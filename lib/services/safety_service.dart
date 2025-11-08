import 'package:firebase_database/firebase_database.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/user_model.dart';

class SafetyService {
  static final SafetyService _instance = SafetyService._internal();
  factory SafetyService() => _instance;
  SafetyService._internal();

  final FirebaseDatabase _rtdb = FirebaseDatabase.instance;

  /// Trigger an SOS alert with the user's current location
  Future<void> triggerSOSAlert(UserModel user) async {
    try {
      // Get current location
      final position = await _getCurrentLocation();
      
      if (position == null) {
        throw Exception('Unable to get location for SOS alert');
      }

      // Create the alert payload
      final alertData = {
        'uid': user.uid,
        'name': user.displayName ?? 'VoyaGo User',
        'email': user.email ?? 'No Email',
        'lat': position.latitude,
        'lng': position.longitude,
        'timestamp': ServerValue.timestamp,
        'accuracy': position.accuracy,
        'altitude': position.altitude,
        'speed': position.speed,
        'heading': position.heading,
      };

      // Write to RTDB - this will overwrite any previous alert from this user
      final ref = _rtdb.ref('sos_alerts/${user.uid}');
      await ref.set(alertData);

      print('SOS alert triggered successfully for user: ${user.uid}');
    } catch (e) {
      print('Error triggering SOS alert: $e');
      throw Exception('Failed to trigger SOS alert: $e');
    }
  }

  /// Clear an SOS alert for a specific user
  Future<void> clearSOSAlert(String uid) async {
    try {
      await _rtdb.ref('sos_alerts/$uid').remove();
      print('SOS alert cleared for user: $uid');
    } catch (e) {
      print('Error clearing SOS alert: $e');
      throw Exception('Failed to clear SOS alert: $e');
    }
  }

  /// Get all active SOS alerts (for emergency responders or team members)
  Stream<Map<String, dynamic>> getSOSAlerts() {
    return _rtdb.ref('sos_alerts').onValue.map((event) {
      final data = event.snapshot.value;
      if (data == null) return <String, dynamic>{};
      
      if (data is Map) {
        return Map<String, dynamic>.from(data);
      }
      
      return <String, dynamic>{};
    });
  }

  /// Get a specific SOS alert by user ID
  Stream<Map<String, dynamic>?> getSOSAlert(String uid) {
    return _rtdb.ref('sos_alerts/$uid').onValue.map((event) {
      final data = event.snapshot.value;
      if (data == null) return null;
      
      if (data is Map) {
        return Map<String, dynamic>.from(data);
      }
      
      return null;
    });
  }

  /// Check if location permissions are granted
  Future<bool> hasLocationPermission() async {
    final permission = await Permission.location.status;
    return permission == PermissionStatus.granted;
  }

  /// Request location permissions
  Future<bool> requestLocationPermission() async {
    final permission = await Permission.location.request();
    return permission == PermissionStatus.granted;
  }

  /// Get current location with proper error handling
  Future<Position?> _getCurrentLocation() async {
    try {
      // Check if location service is enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Location services are disabled. Please enable location services.');
      }

      // Check location permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permissions are denied');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('Location permissions are permanently denied');
      }

      // Get current position with high accuracy for emergency situations
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
        timeLimit: const Duration(seconds: 15), // 15 second timeout for emergency
      );

      return position;
    } catch (e) {
      print('Error getting current location: $e');
      return null;
    }
  }

  /// Get formatted location string for display
  String formatLocation(double lat, double lng) {
    return '${lat.toStringAsFixed(6)}, ${lng.toStringAsFixed(6)}';
  }

  /// Calculate distance between two points (for emergency responders)
  double calculateDistance(double lat1, double lng1, double lat2, double lng2) {
    return Geolocator.distanceBetween(lat1, lng1, lat2, lng2);
  }

  /// Check if an SOS alert is recent (within last hour)
  bool isRecentAlert(int? timestamp) {
    if (timestamp == null) return false;
    
    final alertTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final now = DateTime.now();
    final difference = now.difference(alertTime);
    
    return difference.inHours < 1; // Alert is considered recent if within 1 hour
  }

  /// Format timestamp for display
  String formatAlertTime(int? timestamp) {
    if (timestamp == null) return 'Unknown time';
    
    final alertTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final now = DateTime.now();
    final difference = now.difference(alertTime);
    
    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} minutes ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hours ago';
    } else {
      return '${alertTime.day}/${alertTime.month}/${alertTime.year} at ${alertTime.hour}:${alertTime.minute.toString().padLeft(2, '0')}';
    }
  }

  /// Create a test SOS alert (for development/testing purposes)
  Future<void> createTestSOSAlert(UserModel user) async {
    try {
      final testAlertData = {
        'uid': user.uid,
        'name': '${user.displayName ?? 'Test User'} (TEST)',
        'email': user.email ?? 'test@example.com',
        'lat': 28.6139, // Delhi coordinates for testing
        'lng': 77.2090,
        'timestamp': ServerValue.timestamp,
        'accuracy': 5.0,
        'altitude': 0.0,
        'speed': 0.0,
        'heading': 0.0,
        'isTest': true, // Flag to identify test alerts
      };

      final ref = _rtdb.ref('sos_alerts/${user.uid}');
      await ref.set(testAlertData);

      print('Test SOS alert created for user: ${user.uid}');
    } catch (e) {
      print('Error creating test SOS alert: $e');
      throw Exception('Failed to create test SOS alert: $e');
    }
  }
}