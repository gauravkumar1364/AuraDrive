import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:geocoding/geocoding.dart';

/// Route Search Dialog Widget
class RouteSearchDialog extends StatefulWidget {
  final LatLng currentPosition;
  final Function(LatLng? source, LatLng? destination) onRouteSelected;

  const RouteSearchDialog({
    super.key,
    required this.currentPosition,
    required this.onRouteSelected,
  });

  @override
  State<RouteSearchDialog> createState() => _RouteSearchDialogState();
}

class _RouteSearchDialogState extends State<RouteSearchDialog> {
  final TextEditingController _sourceController = TextEditingController();
  final TextEditingController _destinationController = TextEditingController();
  LatLng? _selectedSource;
  LatLng? _selectedDestination;
  String? _sourceError;
  String? _destinationError;
  bool _isSearchingSource = false;
  bool _isSearchingDestination = false;

  @override
  void dispose() {
    _sourceController.dispose();
    _destinationController.dispose();
    super.dispose();
  }

  /// Search a location by query
  Future<LatLng?> _searchLocation(String query) async {
    if (query.trim().isEmpty) return null;

    // First check if it's a predefined location
    final predefinedLocation = _getPredefinedLocation(query);
    if (predefinedLocation != null) {
      return predefinedLocation;
    }

    try {
      final searchQueries = _buildSearchQueries(query);
      List<Location> locations = [];

      // Try each search query until we find a match
      for (final searchQuery in searchQueries) {
        try {
          locations = await locationFromAddress(searchQuery);
          if (locations.isNotEmpty) break;
        } catch (e) {
          debugPrint('Search failed for "$searchQuery": $e');
          continue;
        }
      }

      if (locations.isNotEmpty) {
        return LatLng(locations[0].latitude, locations[0].longitude);
      }
    } catch (e) {
      debugPrint('Location search failed: $e');
    }

    return null;
  }

  /// Build a list of search queries with increasingly specific locations
  List<String> _buildSearchQueries(String query) {
    const defaultCity = 'Delhi';
    const defaultCountry = 'India';
    query = query.trim();

    return [
      '$query, $defaultCity, $defaultCountry',
      '$query, $defaultCity',
      query,
    ];
  }

  /// Get predefined location coordinates (if any)
  LatLng? _getPredefinedLocation(String query) {
    query = query.trim().toLowerCase();

    // Common Delhi locations
    const predefinedLocations = {
      // Educational Institutions
      'iit': LatLng(28.5450, 77.1920), // IIT Delhi
      'iit delhi': LatLng(28.5450, 77.1920),
      'indian institute of technology delhi': LatLng(28.5450, 77.1920),
      'dtu': LatLng(28.7501, 77.1177), // DTU
      'delhi technological university': LatLng(28.7501, 77.1177),
      'aiims': LatLng(28.5672, 77.2100), // AIIMS Delhi
      'all india institute of medical sciences': LatLng(28.5672, 77.2100),
      'jnu': LatLng(28.5394, 77.1662), // JNU
      'jawaharlal nehru university': LatLng(28.5394, 77.1662),
      'du': LatLng(28.6863, 77.2060), // Delhi University North Campus
      'delhi university': LatLng(28.6863, 77.2060),
      'nsut': LatLng(28.6115, 77.0365), // NSUT
      'netaji subhas university of technology': LatLng(28.6115, 77.0365),
      'nit delhi': LatLng(28.6115, 77.0365),
      'iim delhi': LatLng(28.5494, 77.1736),

      // Landmarks
      'india gate': LatLng(28.6129, 77.2295),
      'red fort': LatLng(28.6562, 77.2410),
      'qutub minar': LatLng(28.5244, 77.1855),
      'lotus temple': LatLng(28.5535, 77.2588),
      'akshardham': LatLng(28.6127, 77.2773),
      'akshardham temple': LatLng(28.6127, 77.2773),
      'jantar mantar': LatLng(28.6271, 77.2166),
      'rashtrapati bhavan': LatLng(28.6143, 77.1996),
      'parliament house': LatLng(28.6172, 77.2082),
      'humayun tomb': LatLng(28.5933, 77.2507),
      'humayuns tomb': LatLng(28.5933, 77.2507),

      // Commercial Areas
      'connaught place': LatLng(28.6315, 77.2167),
      'cp': LatLng(28.6315, 77.2167),
      'karol bagh': LatLng(28.6510, 77.1906),
      'chandni chowk': LatLng(28.6506, 77.2303),
      'sarojini nagar': LatLng(28.5753, 77.1953),
      'lajpat nagar': LatLng(28.5677, 77.2430),
      'nehru place': LatLng(28.5494, 77.2501),
      'dwarka': LatLng(28.5921, 77.0460),
      'rajouri garden': LatLng(28.6415, 77.1214),
      'pitampura': LatLng(28.6974, 77.1311),
      'rohini': LatLng(28.7496, 77.0669),
    };

    return predefinedLocations[query];
  }

  /// Search source location
  Future<void> _searchSource() async {
    setState(() {
      _isSearchingSource = true;
      _sourceError = null;
    });

    final location = await _searchLocation(_sourceController.text);

    setState(() {
      _isSearchingSource = false;
      if (location != null) {
        _selectedSource = location;
        _sourceError = null;
      } else {
        _sourceError =
            'Location not found. Try: "IIT Delhi", "India Gate", etc.';
      }
    });
  }

  /// Search destination location
  Future<void> _searchDestination() async {
    setState(() {
      _isSearchingDestination = true;
      _destinationError = null;
    });

    final location = await _searchLocation(_destinationController.text);

    setState(() {
      _isSearchingDestination = false;
      if (location != null) {
        _selectedDestination = location;
        _destinationError = null;
      } else {
        _destinationError =
            'Location not found. Try: "DTU", "Connaught Place", etc.';
      }
    });
  }

  /// Use current location as source
  void _useCurrentLocation() {
    setState(() {
      _selectedSource = widget.currentPosition;
      _sourceController.text = 'Current Location';
      _sourceError = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(4),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.search, color: Colors.white),
                  const SizedBox(width: 8),
                  const Text(
                    'Search Route',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Source input
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _sourceController,
                            decoration: InputDecoration(
                              labelText: 'From',
                              hintText: 'Search source location...',
                              errorText: _sourceError,
                              prefixIcon: const Icon(Icons.location_on),
                              suffixIcon: _isSearchingSource
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : IconButton(
                                      icon: const Icon(Icons.search),
                                      onPressed: _searchSource,
                                    ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.my_location),
                          onPressed: _useCurrentLocation,
                          tooltip: 'Use current location',
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Destination input
                    TextField(
                      controller: _destinationController,
                      decoration: InputDecoration(
                        labelText: 'To',
                        hintText: 'Search destination...',
                        errorText: _destinationError,
                        prefixIcon: const Icon(Icons.flag),
                        suffixIcon: _isSearchingDestination
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : IconButton(
                                icon: const Icon(Icons.search),
                                onPressed: _searchDestination,
                              ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Start button
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 16,
                        ),
                      ),
                      onPressed:
                          _selectedSource != null &&
                              _selectedDestination != null
                          ? () {
                              widget.onRouteSelected(
                                _selectedSource,
                                _selectedDestination,
                              );
                              Navigator.pop(context);
                            }
                          : null,
                      child: Text(
                        _selectedSource != null && _selectedDestination != null
                            ? 'Start Navigation'
                            : 'Select Locations',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Tips
                    Card(
                      color: Colors.blue.shade50,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Row(
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  size: 20,
                                  color: Colors.blue,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'Search Tips:',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 8),
                            Text(
                              '• Institutions: "IIT Delhi", "DTU", "AIIMS"',
                              style: TextStyle(fontSize: 12),
                            ),
                            Text(
                              '• Landmarks: "India Gate", "Red Fort"',
                              style: TextStyle(fontSize: 12),
                            ),
                            Text(
                              '• Areas: "Connaught Place", "Karol Bagh"',
                              style: TextStyle(fontSize: 12),
                            ),
                            Text(
                              '• Auto-adds "Delhi, India" if needed',
                              style: TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
