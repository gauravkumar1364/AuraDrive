import 'dart:async';
import 'dart:math' as math;
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import '../models/models.dart';
import 'simulated_location_service.dart';

/// Mock GNSS measurement model for development
class MockGnssMeasurementModel {
  final int svid;
  final int constellationType;
  final int timeNanos;
  final double carrierFrequencyHz;
  final double pseudorangeRateMetersPerSecond;
  
  MockGnssMeasurementModel({
    required this.svid,
    required this.constellationType,
    required this.timeNanos,
    required this.carrierFrequencyHz,
    required this.pseudorangeRateMetersPerSecond,
  });
}

/// Service for managing GNSS positioning and cooperative enhancement
class GnssService extends ChangeNotifier {
  // Current state
  bool _isInitialized = false;
  bool _isStreaming = false;
  GnssQuality? _currentQuality;
  PositionData? _currentPosition;
  List<MockGnssMeasurementModel> _mockMeasurements = [];
  
  // Cooperative positioning data
  final Map<String, PositionData> _peerPositions = {};
  
  // Stream controllers
  final StreamController<PositionData> _positionController = 
      StreamController<PositionData>.broadcast();
  final StreamController<GnssQuality> _qualityController = 
      StreamController<GnssQuality>.broadcast();
  
  // Position stream subscription
  StreamSubscription<Position>? _positionSubscription;
  
  // Simulated location service for testing
  final SimulatedLocationService _simulatedLocation = SimulatedLocationService();
  bool _useSimulation = false;
  
  // Streams
  Stream<PositionData> get positionStream => _positionController.stream;
  Stream<GnssQuality> get qualityStream => _qualityController.stream;
  
  // Getters
  bool get isInitialized => _isInitialized;
  bool get isStreaming => _isStreaming;
  GnssQuality? get currentQuality => _currentQuality;
  PositionData? get currentPosition => _currentPosition;
  Map<String, PositionData> get peerPositions => Map.unmodifiable(_peerPositions);
  
  /// Initialize GNSS service
  Future<bool> initialize() async {
    try {
      // Check if running on desktop (Windows, macOS, Linux)
      _useSimulation = !kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux);
      
      if (_useSimulation) {
        debugPrint('🖥️ Running on desktop - using simulated location');
        await _simulatedLocation.initialize();
        _isInitialized = true;
        notifyListeners();
        return true;
      }
      
      // Check location permissions for real devices
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          debugPrint('GnssService: Location permissions denied');
          return false;
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        debugPrint('GnssService: Location permissions permanently denied');
        return false;
      }
      
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('GnssService: Location services are disabled');
        return false;
      }
      
      _isInitialized = true;
      notifyListeners();
      
      debugPrint('GnssService: Initialized successfully');
      return true;
    } catch (e) {
      debugPrint('GnssService: Initialization error: $e');
      // Fallback to simulation if real location fails
      debugPrint('⚠️ Falling back to simulated location');
      _useSimulation = true;
      await _simulatedLocation.initialize();
      _isInitialized = true;
      notifyListeners();
      return true;
    }
  }
  
  /// Start GNSS positioning with enhanced accuracy
  Future<bool> startPositioning() async {
    if (!_isInitialized) {
      debugPrint('GnssService: Not initialized');
      return false;
    }
    
    if (_isStreaming) {
      debugPrint('GnssService: Already streaming');
      return true;
    }
    
    try {
      if (_useSimulation) {
        // Use simulated location
        _simulatedLocation.startLocationUpdates();
        _positionSubscription = _simulatedLocation.getLocationStream()?.listen(
          _onPositionUpdate,
          onError: (error) {
            debugPrint('GnssService: Simulated position error: $error');
          },
        );
      } else {
        // Start position updates with high accuracy
        const LocationSettings locationSettings = LocationSettings(
          accuracy: LocationAccuracy.bestForNavigation,
          distanceFilter: 1, // Update every meter
          timeLimit: Duration(seconds: 10),
        );
        
        _positionSubscription = Geolocator.getPositionStream(
          locationSettings: locationSettings,
        ).listen(
          _onPositionUpdate,
          onError: (error) {
            debugPrint('GnssService: Position update error: $error');
          },
        );
      }
      
      // Start mock measurements for development
      _startMockMeasurements();
      
      _isStreaming = true;
      notifyListeners();
      
      debugPrint('GnssService: Started positioning');
      return true;
    } catch (e) {
      debugPrint('GnssService: Error starting positioning: $e');
      return false;
    }
  }
  
  /// Stop GNSS positioning
  Future<void> stopPositioning() async {
    if (!_isStreaming) return;
    
    try {
      await _positionSubscription?.cancel();
      _positionSubscription = null;
      _isStreaming = false;
      notifyListeners();
      
      debugPrint('GnssService: Stopped positioning');
    } catch (e) {
      debugPrint('GnssService: Error stopping positioning: $e');
    }
  }
  
  /// Process position update from standard GNSS
  void _onPositionUpdate(Position position) {
    final deviceId = 'current_device'; // TODO: Get actual device ID
    
    _currentPosition = PositionData(
      deviceId: deviceId,
      latitude: position.latitude,
      longitude: position.longitude,
      altitude: position.altitude,
      accuracy: position.accuracy,
      timestamp: position.timestamp,
      speed: position.speed,
      heading: position.heading,
      positioningMode: _determinePositioningMode().name,
    );
    
    // Update quality metrics
    _updateGnssQuality(position);
    
    // Process cooperative positioning if we have peer data
    if (_peerPositions.isNotEmpty) {
      _processCooperativePositioning();
    }
    
    _positionController.add(_currentPosition!);
    notifyListeners();
  }
  
  /// Start mock GNSS measurements for development
  void _startMockMeasurements() {
    Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_isStreaming) {
        timer.cancel();
        return;
      }
      
      // Generate mock measurements
      _mockMeasurements = List.generate(8, (index) {
        return MockGnssMeasurementModel(
          svid: index + 1,
          constellationType: index < 4 ? 1 : (index < 6 ? 6 : 1), // GPS and NavIC mix
          timeNanos: DateTime.now().millisecondsSinceEpoch * 1000000,
          carrierFrequencyHz: index < 4 ? 1575.42e6 : 1176.45e6, // L1 and L5 frequencies
          pseudorangeRateMetersPerSecond: -1000 + (index * 200.0),
        );
      });
    });
  }
  
  /// Update GNSS quality metrics
  void _updateGnssQuality(Position position) {
    // Simulate constellation detection based on accuracy
    final constellations = <ConstellationType>[ConstellationType.gps];
    
    // Add NavIC for Indian region
    if (position.latitude >= 5.0 && position.latitude <= 40.0 &&
        position.longitude >= 55.0 && position.longitude <= 110.0) {
      constellations.add(ConstellationType.navic);
    }
    
    // Add other constellations based on accuracy
    if (position.accuracy < 5.0) {
      constellations.add(ConstellationType.galileo);
      constellations.add(ConstellationType.glonass);
    }
    
    // Calculate mock DOP values
    final double hdop = _calculateMockHDOP(position.accuracy);
    final double vdop = hdop * 1.2;
    final double pdop = math.sqrt(hdop * hdop + vdop * vdop);
    
    _currentQuality = GnssQuality(
      satelliteCount: _mockMeasurements.length,
      hdop: hdop,
      vdop: vdop,
      pdop: pdop,
      positioningMode: _determinePositioningMode(),
      constellationTypes: constellations,
      timestamp: DateTime.now(),
    );
    
    _qualityController.add(_currentQuality!);
  }
  
  /// Calculate mock HDOP from position accuracy
  double _calculateMockHDOP(double accuracy) {
    if (accuracy <= 2.0) return 1.0;
    if (accuracy <= 5.0) return 1.5;
    if (accuracy <= 10.0) return 2.0;
    if (accuracy <= 20.0) return 3.0;
    return 5.0;
  }
  
  /// Determine positioning mode
  GnssPositioningMode _determinePositioningMode() {
    if (_currentQuality?.hasNavICSupport == true) {
      return GnssPositioningMode.sbas; // NavIC provides SBAS-like accuracy
    }
    
    if (_peerPositions.isNotEmpty) {
      return GnssPositioningMode.dgps; // Cooperative positioning similar to DGPS
    }
    
    return GnssPositioningMode.sps;
  }
  
  /// Add peer position data for cooperative positioning
  void addPeerPosition(PositionData peerPosition) {
    _peerPositions[peerPosition.deviceId] = peerPosition;
    
    // Remove old peer positions (older than 30 seconds)
    final cutoffTime = DateTime.now().subtract(const Duration(seconds: 30));
    _peerPositions.removeWhere((key, value) => value.timestamp.isBefore(cutoffTime));
    
    notifyListeners();
  }
  
  /// Process cooperative positioning using SmartCoop algorithm
  void _processCooperativePositioning() {
    if (_currentPosition == null || _peerPositions.isEmpty) return;
    
    // Calculate Inter-Phone Ranging (IPR) corrections
    final correctedPosition = _calculateIPRCorrection(_currentPosition!);
    
    if (correctedPosition != null) {
      // Update position with cooperative enhancement
      _currentPosition = correctedPosition.copyWith(
        positioningMode: 'Cooperative',
        accuracy: correctedPosition.accuracy * 0.7, // Improved accuracy
      );
      
      _positionController.add(_currentPosition!);
      notifyListeners();
    }
  }
  
  /// Calculate Inter-Phone Ranging correction using double differencing
  PositionData? _calculateIPRCorrection(PositionData basePosition) {
    if (_peerPositions.length < 2) return null;
    
    // Select best peers based on distance and signal quality
    final nearbyPeers = _peerPositions.values
        .where((peer) => basePosition.distanceTo(peer) < 1000) // Within 1km
        .toList();
    
    if (nearbyPeers.length < 2) return null;
    
    // Simple weighted average for demonstration
    // In reality, this would use more sophisticated algorithms
    double weightedLat = basePosition.latitude;
    double weightedLng = basePosition.longitude;
    double totalWeight = 1.0;
    
    for (final peer in nearbyPeers) {
      final distance = basePosition.distanceTo(peer);
      final weight = 1.0 / (1.0 + distance / 100.0); // Closer peers have higher weight
      
      weightedLat += peer.latitude * weight;
      weightedLng += peer.longitude * weight;
      totalWeight += weight;
    }
    
    weightedLat /= totalWeight;
    weightedLng /= totalWeight;
    
    return basePosition.copyWith(
      latitude: weightedLat,
      longitude: weightedLng,
      positioningMode: 'Cooperative',
    );
  }
  
  /// Get positioning accuracy estimate
  double getPositioningAccuracy() {
    if (_currentQuality == null) return 10.0; // Default 10m
    return _currentQuality!.estimatedAccuracy;
  }
  
  /// Check if NavIC is available
  bool get hasNavICSupport {
    if (_currentQuality == null) return false;
    return _currentQuality!.hasNavICSupport;
  }
  
  /// Get cooperative positioning benefit (improvement factor)
  double getCooperativePositioningBenefit() {
    if (_peerPositions.isEmpty) return 1.0;
    
    // More peers = better cooperative positioning
    final peerCount = _peerPositions.length;
    return 1.0 + (peerCount * 0.1).clamp(0.0, 0.5); // Up to 50% improvement
  }
  
  /// Get current satellite count
  int get satelliteCount => _mockMeasurements.length;
  
  /// Check if positioning is suitable for safety applications
  bool get isSuitableForSafety {
    return _currentQuality?.isSuitableForSafetyCritical ?? false;
  }
  
  /// Dispose of resources
  @override
  void dispose() {
    stopPositioning();
    _positionController.close();
    _qualityController.close();
    super.dispose();
  }
}