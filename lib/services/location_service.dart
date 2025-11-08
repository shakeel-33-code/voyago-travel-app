import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

/// Service for handling user location functionality
class LocationService {
  /// Get the current location of the user
  /// Handles permission requests and location access
  Future<Position?> getCurrentLocation() async {
    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw LocationServiceDisabledException();
      }

      // Check and request location permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw LocationPermissionDeniedException();
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw LocationPermissionPermanentlyDeniedException();
      }

      // Get current position with high accuracy
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 15),
      );

      return position;
    } on LocationServiceDisabledException {
      print('Location services are disabled');
      rethrow;
    } on LocationPermissionDeniedException {
      print('Location permission denied');
      rethrow;
    } on LocationPermissionPermanentlyDeniedException {
      print('Location permission permanently denied');
      rethrow;
    } on TimeoutException {
      print('Location request timed out');
      rethrow;
    } catch (e) {
      print('Error getting current location: $e');
      return null;
    }
  }

  /// Get the last known location of the user
  /// This is faster but may be less accurate
  Future<Position?> getLastKnownLocation() async {
    try {
      Position? position = await Geolocator.getLastKnownPosition();
      return position;
    } catch (e) {
      print('Error getting last known location: $e');
      return null;
    }
  }

  /// Check if location permissions are granted
  Future<bool> hasLocationPermission() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      return permission == LocationPermission.always ||
             permission == LocationPermission.whileInUse;
    } catch (e) {
      print('Error checking location permission: $e');
      return false;
    }
  }

  /// Request location permissions
  Future<bool> requestLocationPermission() async {
    try {
      LocationPermission permission = await Geolocator.requestPermission();
      return permission == LocationPermission.always ||
             permission == LocationPermission.whileInUse;
    } catch (e) {
      print('Error requesting location permission: $e');
      return false;
    }
  }

  /// Check if location services are enabled
  Future<bool> isLocationServiceEnabled() async {
    try {
      return await Geolocator.isLocationServiceEnabled();
    } catch (e) {
      print('Error checking location service status: $e');
      return false;
    }
  }

  /// Open device location settings
  Future<bool> openLocationSettings() async {
    try {
      return await Geolocator.openLocationSettings();
    } catch (e) {
      print('Error opening location settings: $e');
      return false;
    }
  }

  /// Open app-specific location settings
  Future<bool> openAppSettings() async {
    try {
      return await Geolocator.openAppSettings();
    } catch (e) {
      print('Error opening app settings: $e');
      return false;
    }
  }

  /// Calculate distance between two positions in meters
  double calculateDistance(Position start, Position end) {
    return Geolocator.distanceBetween(
      start.latitude,
      start.longitude,
      end.latitude,
      end.longitude,
    );
  }

  /// Calculate bearing between two positions in degrees
  double calculateBearing(Position start, Position end) {
    return Geolocator.bearingBetween(
      start.latitude,
      start.longitude,
      end.latitude,
      end.longitude,
    );
  }

  /// Stream of position updates
  /// Use this for real-time location tracking
  Stream<Position> getPositionStream({
    LocationSettings? locationSettings,
  }) {
    final settings = locationSettings ?? const LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10, // minimum distance in meters before update
    );

    return Geolocator.getPositionStream(locationSettings: settings);
  }

  /// Get human-readable location permission status
  Future<String> getLocationPermissionStatus() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      
      switch (permission) {
        case LocationPermission.denied:
          return 'Permission denied';
        case LocationPermission.deniedForever:
          return 'Permission permanently denied';
        case LocationPermission.whileInUse:
          return 'Permission granted while in use';
        case LocationPermission.always:
          return 'Permission always granted';
        default:
          return 'Unknown permission status';
      }
    } catch (e) {
      return 'Error checking permission: $e';
    }
  }
}

/// Custom exceptions for better error handling
class LocationServiceDisabledException implements Exception {
  final String message = 'Location services are disabled on this device';
  
  @override
  String toString() => message;
}

class LocationPermissionDeniedException implements Exception {
  final String message = 'Location permission was denied';
  
  @override
  String toString() => message;
}

class LocationPermissionPermanentlyDeniedException implements Exception {
  final String message = 'Location permission was permanently denied';
  
  @override
  String toString() => message;
}