import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/trip_model.dart';
import '../models/itinerary_item_model.dart';
import '../services/firestore_service.dart';
import '../services/location_service.dart';
import '../services/maps_service.dart';
import '../widgets/loading_indicator.dart';
import '../config/app_config.dart';

class MapScreen extends StatefulWidget {
  final Trip trip;

  const MapScreen({
    super.key,
    required this.trip,
  });

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  // Services
  final FirestoreService _firestoreService = FirestoreService();
  final LocationService _locationService = LocationService();
  final MapsService _mapsService = MapsService();

  // State variables
  bool _isLoading = true;
  GoogleMapController? _mapController;
  Position? _userPosition;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  ItineraryItem? _selectedItem;
  List<ItineraryItem> _tripItems = [];
  bool _isOffline = false;
  String _connectionStatus = 'Checking connection...';

  @override
  void initState() {
    super.initState();
    _loadMapData();
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  /// Load map data including user location and trip items
  Future<void> _loadMapData() async {
    setState(() {
      _isLoading = true;
      _connectionStatus = 'Checking connection...';
    });

    try {
      // Check connectivity
      final connectivityResult = await Connectivity().checkConnectivity();
      _isOffline = connectivityResult == ConnectivityResult.none;

      setState(() {
        _connectionStatus = _isOffline ? 'Offline Mode' : 'Online';
      });

      // Get user position
      await _getUserLocation();

      // Load trip data based on connectivity
      if (_isOffline) {
        await _loadOfflineData();
      } else {
        await _loadOnlineData();
      }

      // Generate markers
      await _generateMarkers();

    } catch (e) {
      print('Error loading map data: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading map: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// Get user's current location
  Future<void> _getUserLocation() async {
    try {
      _userPosition = await _locationService.getCurrentLocation();
    } on LocationServiceDisabledException {
      _showLocationDialog(
        'Location Disabled',
        'Location services are disabled. Please enable them in settings.',
        _locationService.openLocationSettings,
      );
    } on LocationPermissionDeniedException {
      _showLocationDialog(
        'Permission Denied',
        'Location permission is required for navigation features.',
        _locationService.requestLocationPermission,
      );
    } on LocationPermissionPermanentlyDeniedException {
      _showLocationDialog(
        'Permission Denied',
        'Location permission was permanently denied. Please enable it in app settings.',
        _locationService.openAppSettings,
      );
    } catch (e) {
      print('Error getting user location: $e');
      // Try to get last known location
      _userPosition = await _locationService.getLastKnownLocation();
    }
  }

  /// Load data from Firestore (online mode)
  Future<void> _loadOnlineData() async {
    try {
      _tripItems = await _firestoreService.getItineraryItemsOnce(widget.trip.id!);
      
      // Cache the data for offline use
      await _cacheData();
      
    } catch (e) {
      print('Error loading online data: $e');
      // Fall back to offline data if available
      await _loadOfflineData();
    }
  }

  /// Load data from local cache (offline mode)
  Future<void> _loadOfflineData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final itemsJson = prefs.getString('offline_trip_${widget.trip.id!}');
      
      if (itemsJson != null) {
        final itemsData = json.decode(itemsJson) as List;
        _tripItems = itemsData
            .map((data) => ItineraryItem.fromJson(data, data['id']))
            .toList();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No offline data found. Connect to Wi-Fi to download trip data.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      print('Error loading offline data: $e');
    }
  }

  /// Cache trip data for offline use
  Future<void> _cacheData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final itemsJson = json.encode(_tripItems.map((item) => item.toJson()).toList());
      await prefs.setString('offline_trip_${widget.trip.id!}', itemsJson);
    } catch (e) {
      print('Error caching data: $e');
    }
  }

  /// Generate markers for the map
  Future<void> _generateMarkers() async {
    try {
      // Get trip markers
      _markers = await _mapsService.getTripMarkers(_tripItems);

      // Add user location marker if available
      if (_userPosition != null) {
        final userMarker = _mapsService.createUserLocationMarker(
          LatLng(_userPosition!.latitude, _userPosition!.longitude),
        );
        _markers.add(userMarker);
      }

      // Add tap handlers to markers
      _markers = _markers.map((marker) {
        if (marker.markerId.value != 'user_location') {
          // Find corresponding item
          final item = _tripItems.firstWhere(
            (item) => item.id == marker.markerId.value,
            orElse: () => _tripItems.first,
          );

          return marker.copyWith(
            onTapParam: () {
              setState(() {
                _selectedItem = item;
              });
            },
          );
        }
        return marker;
      }).toSet();

    } catch (e) {
      print('Error generating markers: $e');
    }
  }

  /// Get directions to selected item
  Future<void> _getDirectionsToSelectedItem() async {
    if (_selectedItem == null || _userPosition == null || !_selectedItem!.hasCoordinates) {
      return;
    }

    if (_isOffline) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Directions require an internet connection'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      setState(() {
        _isLoading = true;
      });

      final origin = LatLng(_userPosition!.latitude, _userPosition!.longitude);
      final destination = LatLng(_selectedItem!.latitude!, _selectedItem!.longitude!);

      _polylines = await _mapsService.getDirections(origin, destination, null);

      // Move camera to show both points
      if (_mapController != null) {
        final bounds = _calculateBounds([origin, destination]);
        await _mapController!.animateCamera(
          CameraUpdate.newLatLngBounds(bounds, 100.0),
        );
      }

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to get directions: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// Calculate bounds for camera positioning
  LatLngBounds _calculateBounds(List<LatLng> positions) {
    if (positions.isEmpty) {
      return LatLngBounds(
        southwest: const LatLng(0, 0),
        northeast: const LatLng(0, 0),
      );
    }

    double minLat = positions.first.latitude;
    double maxLat = positions.first.latitude;
    double minLng = positions.first.longitude;
    double maxLng = positions.first.longitude;

    for (final position in positions) {
      minLat = minLat < position.latitude ? minLat : position.latitude;
      maxLat = maxLat > position.latitude ? maxLat : position.latitude;
      minLng = minLng < position.longitude ? minLng : position.longitude;
      maxLng = maxLng > position.longitude ? maxLng : position.longitude;
    }

    return LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
  }

  /// Show location permission dialog
  void _showLocationDialog(String title, String message, Future<bool> Function() action) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await action();
              // Retry getting location
              await _getUserLocation();
              setState(() {});
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text('${widget.trip.title} - Map'),
        ),
        body: const Center(
          child: LoadingIndicator(message: 'Loading map...'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.trip.title} - Map'),
        actions: [
          // Connection status indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: _isOffline ? Colors.orange : Colors.green,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              _connectionStatus,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
              ),
            ),
          ),
          // Refresh button
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadMapData,
            tooltip: 'Refresh Map',
          ),
        ],
      ),
      body: Stack(
        children: [
          // Google Map
          GoogleMap(
            initialCameraPosition: _userPosition != null
                ? CameraPosition(
                    target: LatLng(_userPosition!.latitude, _userPosition!.longitude),
                    zoom: AppConfig.defaultMapZoom,
                  )
                : const CameraPosition(
                    target: LatLng(0.0, 0.0),
                    zoom: 2.0,
                  ),
            onMapCreated: (GoogleMapController controller) {
              _mapController = controller;
              
              // Fit all markers if available
              if (_markers.isNotEmpty) {
                final positions = _markers
                    .map((marker) => marker.position)
                    .toList();
                final bounds = _calculateBounds(positions);
                
                // Delay to ensure map is ready
                Future.delayed(const Duration(milliseconds: 500), () {
                  controller.animateCamera(
                    CameraUpdate.newLatLngBounds(bounds, 100.0),
                  );
                });
              }
            },
            markers: _markers,
            polylines: _polylines,
            myLocationEnabled: _userPosition != null,
            myLocationButtonEnabled: true,
            zoomControlsEnabled: true,
            mapToolbarEnabled: true,
          ),

          // Selected item directions button
          if (_selectedItem != null && _selectedItem!.hasCoordinates)
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _selectedItem!.title,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _selectedItem!.location,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _getDirectionsToSelectedItem,
                              icon: const Icon(Icons.directions),
                              label: const Text('Get Directions'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            onPressed: () {
                              setState(() {
                                _selectedItem = null;
                                _polylines.clear();
                              });
                            },
                            icon: const Icon(Icons.close),
                            tooltip: 'Close Details',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Trip items count indicator
          Positioned(
            top: 16,
            right: 16,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Text(
                  '${_tripItems.length} locations',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}