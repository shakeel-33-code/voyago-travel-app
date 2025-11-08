class AppConstants {
  // Firestore Collections
  static const String usersCollection = 'users';
  static const String tripsCollection = 'trips';
  static const String itineraryItemsCollection = 'itineraryItems';
  
  // App Information
  static const String appName = 'VoyaGo';
  static const String appVersion = '1.0.0';
  
  // Storage Paths
  static const String profileImagesPath = 'profile_images';
  static const String tripImagesPath = 'trip_images';
  
  // Date Formats
  static const String dateFormat = 'MMM dd, yyyy';
  static const String timeFormat = 'hh:mm a';
  static const String dateTimeFormat = 'MMM dd, yyyy hh:mm a';
  
  // Trip Constants
  static const int maxTripDuration = 365; // days
  static const int maxCollaborators = 10;
  static const int maxItineraryItems = 100;
  
  // Validation Constants
  static const int minPasswordLength = 6;
  static const int maxNameLength = 50;
  static const int maxDescriptionLength = 500;
  
  // Error Messages
  static const String networkError = 'Please check your internet connection and try again.';
  static const String generalError = 'Something went wrong. Please try again.';
  static const String authError = 'Authentication failed. Please try again.';
  
  // Success Messages
  static const String accountCreated = 'Account created successfully!';
  static const String loginSuccess = 'Logged in successfully!';
  static const String profileUpdated = 'Profile updated successfully!';
  static const String tripCreated = 'Trip created successfully!';
  static const String tripUpdated = 'Trip updated successfully!';
  static const String tripDeleted = 'Trip deleted successfully!';
}