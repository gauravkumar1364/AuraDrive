import 'dart:convert';

/// Model representing GNSS positioning quality and accuracy metrics
class GnssQuality {
  final int satelliteCount;
  final double hdop; // Horizontal Dilution of Precision
  final double vdop; // Vertical Dilution of Precision
  final double pdop; // Position Dilution of Precision
  final GnssPositioningMode positioningMode;
  final List<ConstellationType> constellationTypes;
  final double? carrierPhaseAccuracy; // meters
  final double? pseudorangeAccuracy; // meters
  final int? fixQuality; // 0=invalid, 1=GPS fix, 2=DGPS fix, etc.
  final DateTime timestamp;
  final Map<String, dynamic>? additionalMetrics;

  const GnssQuality({
    required this.satelliteCount,
    required this.hdop,
    required this.vdop,
    required this.pdop,
    required this.positioningMode,
    required this.constellationTypes,
    this.carrierPhaseAccuracy,
    this.pseudorangeAccuracy,
    this.fixQuality,
    required this.timestamp,
    this.additionalMetrics,
  });

  /// Create GnssQuality from JSON
  factory GnssQuality.fromJson(Map<String, dynamic> json) {
    return GnssQuality(
      satelliteCount: json['satelliteCount'] as int,
      hdop: (json['hdop'] as num).toDouble(),
      vdop: (json['vdop'] as num).toDouble(),
      pdop: (json['pdop'] as num).toDouble(),
      positioningMode: GnssPositioningMode.values.firstWhere(
        (e) => e.name == json['positioningMode'],
        orElse: () => GnssPositioningMode.sps,
      ),
      constellationTypes: (json['constellationTypes'] as List<dynamic>)
          .map((e) => ConstellationType.values.firstWhere(
                (c) => c.name == e,
                orElse: () => ConstellationType.gps,
              ))
          .toList(),
      carrierPhaseAccuracy: json['carrierPhaseAccuracy'] != null
          ? (json['carrierPhaseAccuracy'] as num).toDouble()
          : null,
      pseudorangeAccuracy: json['pseudorangeAccuracy'] != null
          ? (json['pseudorangeAccuracy'] as num).toDouble()
          : null,
      fixQuality: json['fixQuality'] as int?,
      timestamp: DateTime.parse(json['timestamp'] as String),
      additionalMetrics: json['additionalMetrics'] as Map<String, dynamic>?,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'satelliteCount': satelliteCount,
      'hdop': hdop,
      'vdop': vdop,
      'pdop': pdop,
      'positioningMode': positioningMode.name,
      'constellationTypes': constellationTypes.map((e) => e.name).toList(),
      'carrierPhaseAccuracy': carrierPhaseAccuracy,
      'pseudorangeAccuracy': pseudorangeAccuracy,
      'fixQuality': fixQuality,
      'timestamp': timestamp.toIso8601String(),
      'additionalMetrics': additionalMetrics,
    };
  }

  /// Convert to JSON string
  String toJsonString() => json.encode(toJson());

  /// Create from JSON string
  factory GnssQuality.fromJsonString(String jsonString) {
    return GnssQuality.fromJson(json.decode(jsonString) as Map<String, dynamic>);
  }

  /// Get overall quality score (0-100)
  int get qualityScore {
    int score = 0;

    // Satellite count contribution (0-30 points)
    if (satelliteCount >= 12) {
      score += 30;
    } else if (satelliteCount >= 8) {
      score += 25;
    } else if (satelliteCount >= 6) {
      score += 20;
    } else if (satelliteCount >= 4) {
      score += 15;
    } else {
      score += 5;
    }

    // HDOP contribution (0-25 points)
    if (hdop <= 1.0) {
      score += 25;
    } else if (hdop <= 2.0) {
      score += 20;
    } else if (hdop <= 5.0) {
      score += 15;
    } else if (hdop <= 10.0) {
      score += 10;
    } else {
      score += 5;
    }

    // Positioning mode contribution (0-20 points)
    score += switch (positioningMode) {
      GnssPositioningMode.rtk => 20,
      GnssPositioningMode.dgps => 18,
      GnssPositioningMode.sbas => 15,
      GnssPositioningMode.pps => 12,
      GnssPositioningMode.sps => 10,
      GnssPositioningMode.autonomous => 8,
      GnssPositioningMode.estimated => 5,
    };

    // Constellation diversity contribution (0-15 points)
    if (constellationTypes.length >= 3) {
      score += 15;
    } else if (constellationTypes.length == 2) {
      score += 10;
    } else {
      score += 5;
    }

    // NavIC support bonus (0-10 points)
    if (constellationTypes.contains(ConstellationType.navic)) {
      score += 10;
    }

    return score.clamp(0, 100);
  }

  /// Get quality description
  String get qualityDescription {
    final int score = qualityScore;
    if (score >= 90) return 'Excellent';
    if (score >= 75) return 'Very Good';
    if (score >= 60) return 'Good';
    if (score >= 45) return 'Fair';
    if (score >= 30) return 'Poor';
    return 'Very Poor';
  }

  /// Get estimated position accuracy in meters
  double get estimatedAccuracy {
    // Base accuracy from positioning mode
    double baseAccuracy = switch (positioningMode) {
      GnssPositioningMode.rtk => 0.02,        // 2 cm
      GnssPositioningMode.dgps => 1.0,        // 1 meter
      GnssPositioningMode.sbas => 2.0,        // 2 meters
      GnssPositioningMode.pps => 3.0,         // 3 meters
      GnssPositioningMode.sps => 5.0,         // 5 meters
      GnssPositioningMode.autonomous => 8.0,   // 8 meters
      GnssPositioningMode.estimated => 15.0,  // 15 meters
    };

    // Apply DOP degradation
    return baseAccuracy * hdop;
  }

  /// Check if suitable for safety-critical applications
  bool get isSuitableForSafetyCritical {
    return qualityScore >= 70 &&
           satelliteCount >= 6 &&
           hdop <= 3.0 &&
           positioningMode != GnssPositioningMode.estimated;
  }

  /// Check if suitable for cooperative positioning
  bool get isSuitableForCooperativePositioning {
    return qualityScore >= 50 &&
           satelliteCount >= 4 &&
           hdop <= 10.0;
  }

  /// Check if NavIC is available
  bool get hasNavICSupport =>
      constellationTypes.contains(ConstellationType.navic);

  /// Check if multi-constellation
  bool get isMultiConstellation => constellationTypes.length > 1;

  /// Get constellation names as string
  String get constellationNames =>
      constellationTypes.map((e) => e.displayName).join(', ');

  /// Copy with new values
  GnssQuality copyWith({
    int? satelliteCount,
    double? hdop,
    double? vdop,
    double? pdop,
    GnssPositioningMode? positioningMode,
    List<ConstellationType>? constellationTypes,
    double? carrierPhaseAccuracy,
    double? pseudorangeAccuracy,
    int? fixQuality,
    DateTime? timestamp,
    Map<String, dynamic>? additionalMetrics,
  }) {
    return GnssQuality(
      satelliteCount: satelliteCount ?? this.satelliteCount,
      hdop: hdop ?? this.hdop,
      vdop: vdop ?? this.vdop,
      pdop: pdop ?? this.pdop,
      positioningMode: positioningMode ?? this.positioningMode,
      constellationTypes: constellationTypes ?? this.constellationTypes,
      carrierPhaseAccuracy: carrierPhaseAccuracy ?? this.carrierPhaseAccuracy,
      pseudorangeAccuracy: pseudorangeAccuracy ?? this.pseudorangeAccuracy,
      fixQuality: fixQuality ?? this.fixQuality,
      timestamp: timestamp ?? this.timestamp,
      additionalMetrics: additionalMetrics ?? this.additionalMetrics,
    );
  }

  @override
  String toString() {
    return 'GnssQuality(sats: $satelliteCount, hdop: ${hdop.toStringAsFixed(1)}, '
           'mode: $positioningMode, quality: $qualityDescription, '
           'constellations: $constellationNames)';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GnssQuality &&
          runtimeType == other.runtimeType &&
          satelliteCount == other.satelliteCount &&
          hdop == other.hdop &&
          positioningMode == other.positioningMode &&
          timestamp == other.timestamp;

  @override
  int get hashCode =>
      satelliteCount.hashCode ^
      hdop.hashCode ^
      positioningMode.hashCode ^
      timestamp.hashCode;
}

/// Enum for GNSS positioning modes
enum GnssPositioningMode {
  sps,        // Standard Positioning Service
  pps,        // Precise Positioning Service
  dgps,       // Differential GPS
  rtk,        // Real-Time Kinematic
  sbas,       // Satellite-Based Augmentation System
  autonomous, // Autonomous positioning
  estimated,  // Estimated/dead reckoning
}

/// Enum for GNSS constellation types
enum ConstellationType {
  gps,        // GPS (USA)
  glonass,    // GLONASS (Russia)
  galileo,    // Galileo (EU)
  beidou,     // BeiDou (China)
  navic,      // NavIC/IRNSS (India)
  qzss,       // QZSS (Japan)
}

/// Extension for constellation display names
extension ConstellationTypeExtension on ConstellationType {
  String get displayName {
    return switch (this) {
      ConstellationType.gps => 'GPS',
      ConstellationType.glonass => 'GLONASS',
      ConstellationType.galileo => 'Galileo',
      ConstellationType.beidou => 'BeiDou',
      ConstellationType.navic => 'NavIC',
      ConstellationType.qzss => 'QZSS',
    };
  }

  String get description {
    return switch (this) {
      ConstellationType.gps => 'Global Positioning System (USA)',
      ConstellationType.glonass => 'Global Navigation Satellite System (Russia)',
      ConstellationType.galileo => 'European Global Navigation Satellite System',
      ConstellationType.beidou => 'BeiDou Navigation Satellite System (China)',
      ConstellationType.navic => 'Navigation with Indian Constellation',
      ConstellationType.qzss => 'Quasi-Zenith Satellite System (Japan)',
    };
  }
}