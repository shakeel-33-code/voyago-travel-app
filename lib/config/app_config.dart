/// Configuration constants for the VoyaGo app
class AppConfig {
  // Google Maps API Key
  // TODO: Replace with your actual Google Cloud Console API key
  // Make sure to enable the following APIs:
  // - Maps SDK for Android
  // - Maps SDK for iOS  
  // - Directions API
  // - Geocoding API
  static const String googleMapsApiKey = 'YOUR_GOOGLE_MAPS_API_KEY_HERE';
  
  // App Constants
  static const String appName = 'VoyaGo';
  static const String appVersion = '1.0.0';
  
  // Firebase Configuration
  static const String firebaseProjectId = 'voyago-app';
  
  // Map Configuration
  static const double defaultMapZoom = 12.0;
  static const double userLocationZoom = 15.0;
  static const double tripOverviewZoom = 10.0;
  
  // Offline Configuration
  static const int maxOfflineTrips = 10;
  static const Duration cacheValidityDuration = Duration(days: 7);
  
  // Network Configuration  
  static const Duration networkTimeout = Duration(seconds: 30);
  static const int maxRetryAttempts = 3;
  
  // Validation
  static bool get isGoogleMapsApiKeyConfigured {
    return googleMapsApiKey != 'YOUR_GOOGLE_MAPS_API_KEY_HERE' && 
           googleMapsApiKey.isNotEmpty;
  }
}