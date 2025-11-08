import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:http/http.dart' as http;
import '../models/itinerary_item_model.dart';
import '../config/app_config.dart';

/// Service for handling Google Maps functionality including markers and directions
class MapsService {
  final PolylinePoints _polylinePoints = PolylinePoints();

  /// Generate markers for trip items that have coordinates
  Future<Set<Marker>> getTripMarkers(List<ItineraryItem> items) async {
    final Set<Marker> markers = {};

    for (final item in items) {
      if (item.hasCoordinates) {
        final marker = Marker(
          markerId: MarkerId(item.id ?? 'item_${items.indexOf(item)}'),
          position: LatLng(item.latitude!, item.longitude!),
          infoWindow: InfoWindow(
            title: item.title,
            snippet: item.notes?.isNotEmpty == true 
                ? item.notes! 
                : 'Tap for directions',
          ),
          icon: _getMarkerIcon(item.type),
          onTap: () {
            // This will be handled by the map screen
          },
        );
        markers.add(marker);
      }
    }

    return markers;
  }

  /// Create a user location marker
  Marker createUserLocationMarker(LatLng position) {
    return Marker(
      markerId: const MarkerId('user_location'),
      position: position,
      infoWindow: const InfoWindow(
        title: 'Your Location',
        snippet: 'Current position',
      ),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
    );
  }

  /// Get directions between two points using Google Directions API
  Future<Set<Polyline>> getDirections(
    LatLng origin,
    LatLng destination,
    String? apiKey,
  ) async {
    final Set<Polyline> polylines = {};

    // Check if API key is configured
    final key = apiKey ?? AppConfig.googleMapsApiKey;
    if (!AppConfig.isGoogleMapsApiKeyConfigured && apiKey == null) {
      throw Exception('Google Maps API key is not configured');
    }

    try {
      // Build directions API URL
      final String url = 'https://maps.googleapis.com/maps/api/directions/json?'
          'origin=${origin.latitude},${origin.longitude}&'
          'destination=${destination.latitude},${destination.longitude}&'
          'key=$key';

      // Make API request
      final response = await http.get(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
      ).timeout(AppConfig.networkTimeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['status'] == 'OK' && data['routes'].isNotEmpty) {
          final route = data['routes'][0];
          final polylineEncoded = route['overview_polyline']['points'];
          
          // Decode polyline
          final List<PointLatLng> polylineCoordinates = 
              _polylinePoints.decodePolyline(polylineEncoded);
          
          // Convert to LatLng list
          final List<LatLng> polylinePoints = polylineCoordinates
              .map((point) => LatLng(point.latitude, point.longitude))
              .toList();

          // Create polyline
          final polyline = Polyline(
            polylineId: const PolylineId('directions'),
            points: polylinePoints,
            color: Colors.blue,
            width: 5,
            patterns: [],
            startCap: Cap.roundCap,
            endCap: Cap.roundCap,
          );

          polylines.add(polyline);
        } else {
          throw Exception('No routes found: ${data['status']}');
        }
      } else {
        throw Exception('Directions API error: ${response.statusCode}');
      }
    } catch (e) {
      print('Error getting directions: $e');
      rethrow;
    }

    return polylines;
  }

  /// Get directions information including distance and duration
  Future<DirectionsInfo?> getDirectionsInfo(
    LatLng origin,
    LatLng destination,
    String? apiKey,
  ) async {
    final key = apiKey ?? AppConfig.googleMapsApiKey;
    if (!AppConfig.isGoogleMapsApiKeyConfigured && apiKey == null) {
      return null;
    }

    try {
      final String url = 'https://maps.googleapis.com/maps/api/directions/json?'
          'origin=${origin.latitude},${origin.longitude}&'
          'destination=${destination.latitude},${destination.longitude}&'
          'key=$key';

      final response = await http.get(Uri.parse(url))
          .timeout(AppConfig.networkTimeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['status'] == 'OK' && data['routes'].isNotEmpty) {
          final route = data['routes'][0];
          final leg = route['legs'][0];
          
          return DirectionsInfo(
            distance: leg['distance']['text'],
            duration: leg['duration']['text'],
            distanceValue: leg['distance']['value'],
            durationValue: leg['duration']['value'],
          );
        }
      }
    } catch (e) {
      print('Error getting directions info: $e');
    }

    return null;
  }

  /// Calculate optimal camera position to show all markers
  CameraPosition calculateOptimalCameraPosition(
    List<LatLng> positions, {
    double padding = 100.0,
  }) {
    if (positions.isEmpty) {
      // Default to a world view
      return const CameraPosition(
        target: LatLng(0.0, 0.0),
        zoom: 2.0,
      );
    }

    if (positions.length == 1) {
      return CameraPosition(
        target: positions.first,
        zoom: AppConfig.userLocationZoom,
      );
    }

    // Calculate bounds
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

    // Calculate center
    final centerLat = (minLat + maxLat) / 2;
    final centerLng = (minLng + maxLng) / 2;

    return CameraPosition(
      target: LatLng(centerLat, centerLng),
      zoom: AppConfig.tripOverviewZoom,
    );
  }

  /// Get marker icon based on itinerary item type
  BitmapDescriptor _getMarkerIcon(ItineraryItemType type) {
    switch (type) {
      case ItineraryItemType.flight:
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
      case ItineraryItemType.hotel:
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue);
      case ItineraryItemType.activity:
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);
      case ItineraryItemType.restaurant:
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange);
      case ItineraryItemType.transport:
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueViolet);
      case ItineraryItemType.meeting:
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueYellow);
      case ItineraryItemType.other:
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRose);
    }
  }

  /// Create custom polyline for specific route types
  Polyline createCustomPolyline(
    String polylineId,
    List<LatLng> points, {
    Color color = Colors.blue,
    int width = 5,
    List<PatternItem> patterns = const [],
  }) {
    return Polyline(
      polylineId: PolylineId(polylineId),
      points: points,
      color: color,
      width: width,
      patterns: patterns,
      startCap: Cap.roundCap,
      endCap: Cap.roundCap,
    );
  }

  /// Clear all polylines
  Set<Polyline> clearPolylines() {
    return <Polyline>{};
  }

  /// Clear all markers except user location
  Set<Marker> clearTripMarkers(Set<Marker> currentMarkers) {
    return currentMarkers
        .where((marker) => marker.markerId.value == 'user_location')
        .toSet();
  }
}

/// Class to hold directions information
class DirectionsInfo {
  final String distance;
  final String duration;
  final int distanceValue; // in meters
  final int durationValue; // in seconds

  const DirectionsInfo({
    required this.distance,
    required this.duration,
    required this.distanceValue,
    required this.durationValue,
  });

  @override
  String toString() {
    return '$distance • $duration';
  }
}