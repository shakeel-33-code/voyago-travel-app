import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Service for converting addresses to geographic coordinates
class GeocodingService {
  /// Convert an address string to LatLng coordinates
  /// Returns null if the address cannot be found or an error occurs
  Future<LatLng?> geocodeAddress(String address) async {
    if (address.trim().isEmpty) {
      return null;
    }

    try {
      // Use the geocoding package to get location from address
      List<Location> locations = await locationFromAddress(address);
      
      if (locations.isNotEmpty) {
        final location = locations.first;
        return LatLng(location.latitude, location.longitude);
      }
      
      return null;
    } catch (e) {
      // Handle any errors (network issues, invalid address, etc.)
      print('Geocoding error for address "$address": $e');
      return null;
    }
  }

  /// Convert multiple addresses to coordinates in batch
  /// Returns a map of address to LatLng, with null values for failed geocoding
  Future<Map<String, LatLng?>> geocodeAddresses(List<String> addresses) async {
    final Map<String, LatLng?> results = {};
    
    for (final address in addresses) {
      results[address] = await geocodeAddress(address);
      // Add small delay to avoid rate limiting
      await Future.delayed(const Duration(milliseconds: 100));
    }
    
    return results;
  }

  /// Convert LatLng coordinates back to an address
  /// Returns null if reverse geocoding fails
  Future<String?> reverseGeocode(LatLng coordinates) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        coordinates.latitude,
        coordinates.longitude,
      );
      
      if (placemarks.isNotEmpty) {
        final placemark = placemarks.first;
        
        // Construct address from placemark components
        List<String> addressParts = [];
        
        if (placemark.name != null && placemark.name!.isNotEmpty) {
          addressParts.add(placemark.name!);
        }
        
        if (placemark.street != null && placemark.street!.isNotEmpty) {
          addressParts.add(placemark.street!);
        }
        
        if (placemark.locality != null && placemark.locality!.isNotEmpty) {
          addressParts.add(placemark.locality!);
        }
        
        if (placemark.administrativeArea != null && placemark.administrativeArea!.isNotEmpty) {
          addressParts.add(placemark.administrativeArea!);
        }
        
        if (placemark.country != null && placemark.country!.isNotEmpty) {
          addressParts.add(placemark.country!);
        }
        
        return addressParts.join(', ');
      }
      
      return null;
    } catch (e) {
      print('Reverse geocoding error for coordinates (${coordinates.latitude}, ${coordinates.longitude}): $e');
      return null;
    }
  }

  /// Validate if an address string looks valid for geocoding
  bool isValidAddress(String address) {
    if (address.trim().isEmpty) return false;
    
    // Basic validation - should contain some meaningful content
    final trimmed = address.trim();
    if (trimmed.length < 3) return false;
    
    // Should contain at least one letter or number
    final hasAlphanumeric = RegExp(r'[a-zA-Z0-9]').hasMatch(trimmed);
    if (!hasAlphanumeric) return false;
    
    return true;
  }

  /// Get example addresses for testing/demo purposes
  List<String> getExampleAddresses() {
    return [
      'Times Square, New York, NY, USA',
      'Eiffel Tower, Paris, France',
      'Tokyo Station, Tokyo, Japan',
      'Big Ben, London, UK',
      'Sydney Opera House, Sydney, Australia',
      'Colosseum, Rome, Italy',
      'Machu Picchu, Peru',
      'Taj Mahal, Agra, India',
    ];
  }
}