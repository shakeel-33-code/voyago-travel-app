import 'package:flutter/material.dart';

// App Constants
class AppConstants {
  // App Info
  static const String appName = 'VoyaGo';
  static const String appVersion = '1.0.0';
  static const String appDescription = 'Your Ultimate Travel Companion';

  // Firebase Collection Names
  static const String usersCollection = 'users';
  static const String tripsCollection = 'trips';
  static const String itineraryItemsCollection = 'itineraryItems';
  static const String expensesCollection = 'expenses';
  static const String journalEntriesCollection = 'journalEntries';
  static const String sosAlertsCollection = 'sosAlerts';

  // Storage Paths
  static const String journalImagesPath = 'journal_images';
  static const String profileImagesPath = 'profile_images';

  // Shared Preferences Keys
  static const String userDataKey = 'user_data';
  static const String offlineTripsKey = 'offline_trips';
  static const String themeKey = 'theme_mode';

  // API Keys (These should be stored securely in production)
  static const String googleMapsApiKey = 'YOUR_GOOGLE_MAPS_API_KEY';
  static const String dialogflowProjectId = 'YOUR_DIALOGFLOW_PROJECT_ID';

  // Default Values
  static const int defaultPageSize = 20;
  static const int maxImageSize = 5 * 1024 * 1024; // 5MB
  static const Duration defaultTimeout = Duration(seconds: 30);

  // Itinerary Item Types
  static const List<String> itineraryItemTypes = [
    'Flight',
    'Hotel',
    'Activity',
    'Restaurant',
    'Transport',
    'Meeting',
    'Other'
  ];

  // Expense Categories
  static const List<String> expenseCategories = [
    'Accommodation',
    'Food & Dining',
    'Transportation',
    'Activities',
    'Shopping',
    'Emergency',
    'Other'
  ];

  // Trip Duration Options (in days)
  static const List<int> tripDurationOptions = [1, 2, 3, 5, 7, 10, 14, 21, 30];
}