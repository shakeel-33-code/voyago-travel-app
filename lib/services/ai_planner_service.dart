import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';

import '../models/itinerary_item_model.dart';

/// Service for communicating with Firebase Cloud Functions to get AI-generated itinerary suggestions
class AIPlannerService {
  static final AIPlannerService _instance = AIPlannerService._internal();
  factory AIPlannerService() => _instance;
  AIPlannerService._internal();

  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  /// Gets AI-generated itinerary suggestions based on a prompt
  /// 
  /// [prompt] - The user's input describing their trip (e.g., "3 days in Goa, budget-friendly")
  /// Returns a list of ItineraryItem objects with dates and details
  Future<List<ItineraryItem>> getAiSuggestions(String prompt) async {
    try {
      debugPrint('Requesting AI suggestions for prompt: $prompt');
      
      // Get the callable reference to our Cloud Function
      final HttpsCallable callable = _functions.httpsCallable('generateItinerary');
      
      // Call the function with the user's prompt
      final HttpsCallableResult result = await callable.call({
        'prompt': prompt,
      });
      
      // Parse the response
      final Map<String, dynamic> data = result.data as Map<String, dynamic>;
      final List<dynamic> itemsList = data['itinerary'] as List<dynamic>;
      
      debugPrint('Received ${itemsList.length} AI-generated items');
      
      // Convert each item to an ItineraryItem object
      final List<ItineraryItem> itineraryItems = [];
      
      for (final itemData in itemsList) {
        final Map<String, dynamic> itemMap = itemData as Map<String, dynamic>;
        
        try {
          // Parse the ISO 8601 date string back to DateTime
          final DateTime startTime = DateTime.parse(itemMap['startTime'] as String);
          final DateTime? endTime = itemMap['endTime'] != null 
              ? DateTime.parse(itemMap['endTime'] as String)
              : null;
          
          // Parse the item type string to enum
          final ItineraryItemType type = _parseItemType(itemMap['type'] as String);
          
          final ItineraryItem item = ItineraryItem(
            id: '', // Will be set by FirestoreService
            title: itemMap['title'] as String,
            description: itemMap['description'] as String? ?? '',
            location: itemMap['location'] as String? ?? '',
            startTime: startTime,
            endTime: endTime ?? startTime.add(const Duration(hours: 1)), // Default 1 hour duration
            type: type,
            notes: itemMap['notes'] as String? ?? '',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );
          
          itineraryItems.add(item);
        } catch (e) {
          debugPrint('Error parsing itinerary item: $e');
          // Skip this item if parsing fails
          continue;
        }
      }
      
      debugPrint('Successfully parsed ${itineraryItems.length} itinerary items');
      return itineraryItems;
      
    } on FirebaseFunctionsException catch (e) {
      debugPrint('FirebaseFunctionsException: ${e.code} - ${e.message}');
      throw Exception('AI service error: ${e.message}');
    } catch (e) {
      debugPrint('Error getting AI suggestions: $e');
      throw Exception('Failed to get AI suggestions. Please try again.');
    }
  }
  
  /// Parses a string to ItineraryItemType enum
  ItineraryItemType _parseItemType(String typeString) {
    switch (typeString.toLowerCase()) {
      case 'accommodation':
        return ItineraryItemType.accommodation;
      case 'activity':
        return ItineraryItemType.activity;
      case 'dining':
        return ItineraryItemType.dining;
      case 'transport':
      case 'travel':
        return ItineraryItemType.transport;
      case 'shopping':
        return ItineraryItemType.shopping;
      case 'entertainment':
        return ItineraryItemType.entertainment;
      case 'sightseeing':
        return ItineraryItemType.sightseeing;
      case 'relaxation':
        return ItineraryItemType.relaxation;
      case 'business':
        return ItineraryItemType.business;
      case 'emergency':
        return ItineraryItemType.emergency;
      case 'other':
      default:
        return ItineraryItemType.other;
    }
  }
  
  /// Validates if a prompt is suitable for AI generation
  bool isValidPrompt(String prompt) {
    if (prompt.trim().isEmpty) return false;
    if (prompt.trim().length < 5) return false;
    if (prompt.trim().length > 500) return false;
    return true;
  }
  
  /// Gets example prompts for user guidance
  List<String> getExamplePrompts() {
    return [
      '3 days in Goa, beach activities',
      '5 days in Kerala, backwaters and culture',
      '2 days in Mumbai, business trip',
      '7 days in Rajasthan, heritage tour',
      '4 days in Himachal, adventure sports',
      'Weekend in Bangalore, food and nightlife',
    ];
  }
}