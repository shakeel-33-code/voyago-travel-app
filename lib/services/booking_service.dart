import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';

class BookingService {
  static final BookingService _instance = BookingService._internal();
  factory BookingService() => _instance;
  BookingService._internal();

  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  /// Search for bookings using the Cloud Function
  Future<List<Map<String, dynamic>>> searchBookings(String type, String query) async {
    try {
      debugPrint('Searching bookings: $type - $query');
      
      final callable = _functions.httpsCallable('searchBookings');
      
      final result = await callable.call({
        'type': type,
        'query': query,
      });

      final data = result.data;
      if (data == null || data['results'] == null) {
        debugPrint('No booking results returned');
        return [];
      }

      final List<dynamic> resultsList = data['results'];
      final bookings = resultsList.map((item) => Map<String, dynamic>.from(item)).toList();
      
      debugPrint('Found ${bookings.length} booking results');
      return bookings;
    } on FirebaseFunctionsException catch (e) {
      debugPrint('Firebase Functions error: ${e.code} - ${e.message}');
      throw Exception('Booking search failed: ${e.message}');
    } catch (e) {
      debugPrint('Error searching bookings: $e');
      throw Exception('Failed to search bookings. Please try again.');
    }
  }

  /// Get formatted price string
  String formatPrice(double price, String currency) {
    switch (currency.toUpperCase()) {
      case 'INR':
        return '₹${price.toStringAsFixed(0)}';
      case 'USD':
        return '\$${price.toStringAsFixed(2)}';
      case 'EUR':
        return '€${price.toStringAsFixed(2)}';
      default:
        return '$currency ${price.toStringAsFixed(2)}';
    }
  }

  /// Format date and time for display
  String formatDateTime(String isoString) {
    try {
      final dateTime = DateTime.parse(isoString);
      final day = dateTime.day.toString().padLeft(2, '0');
      final month = dateTime.month.toString().padLeft(2, '0');
      final year = dateTime.year;
      final hour = dateTime.hour.toString().padLeft(2, '0');
      final minute = dateTime.minute.toString().padLeft(2, '0');
      
      return '$day/$month/$year at $hour:$minute';
    } catch (e) {
      debugPrint('Error formatting date: $e');
      return 'Invalid date';
    }
  }

  /// Format time only for display
  String formatTime(String isoString) {
    try {
      final dateTime = DateTime.parse(isoString);
      final hour = dateTime.hour.toString().padLeft(2, '0');
      final minute = dateTime.minute.toString().padLeft(2, '0');
      
      return '$hour:$minute';
    } catch (e) {
      debugPrint('Error formatting time: $e');
      return 'Invalid time';
    }
  }

  /// Format date only for display
  String formatDate(String isoString) {
    try {
      final dateTime = DateTime.parse(isoString);
      final day = dateTime.day.toString().padLeft(2, '0');
      final month = dateTime.month.toString().padLeft(2, '0');
      final year = dateTime.year;
      
      return '$day/$month/$year';
    } catch (e) {
      debugPrint('Error formatting date: $e');
      return 'Invalid date';
    }
  }

  /// Get booking type display name
  String getBookingTypeDisplayName(String type) {
    switch (type.toLowerCase()) {
      case 'flight':
        return 'Flights';
      case 'hotel':
        return 'Hotels';
      case 'bus':
        return 'Buses';
      default:
        return 'Bookings';
    }
  }

  /// Get icon for booking type
  String getBookingTypeIcon(String type) {
    switch (type.toLowerCase()) {
      case 'flight':
        return '✈️';
      case 'hotel':
        return '🏨';
      case 'bus':
        return '🚌';
      default:
        return '📅';
    }
  }

  /// Calculate number of nights for hotel bookings
  int calculateNights(String checkInDate, String checkOutDate) {
    try {
      final checkIn = DateTime.parse(checkInDate);
      final checkOut = DateTime.parse(checkOutDate);
      return checkOut.difference(checkIn).inDays;
    } catch (e) {
      debugPrint('Error calculating nights: $e');
      return 1;
    }
  }

  /// Get total hotel price for the stay
  double calculateTotalHotelPrice(Map<String, dynamic> hotelData) {
    try {
      final pricePerNight = hotelData['pricePerNight']?.toDouble() ?? 0.0;
      final checkInDate = hotelData['checkInDate'] as String?;
      final checkOutDate = hotelData['checkOutDate'] as String?;
      
      if (checkInDate == null || checkOutDate == null) return pricePerNight;
      
      final nights = calculateNights(checkInDate, checkOutDate);
      return pricePerNight * nights;
    } catch (e) {
      debugPrint('Error calculating total hotel price: $e');
      return hotelData['pricePerNight']?.toDouble() ?? 0.0;
    }
  }

  /// Check if booking is available (mock logic)
  bool isBookingAvailable(Map<String, dynamic> bookingData) {
    // In a real app, this would check actual availability
    // For now, we'll just return true for all mock data
    return true;
  }

  /// Get booking details summary for itinerary
  String getBookingDetailsSummary(String type, Map<String, dynamic> bookingData) {
    switch (type.toLowerCase()) {
      case 'flight':
        final from = bookingData['from'] ?? '';
        final to = bookingData['to'] ?? '';
        final departureTime = bookingData['departureTime'] as String?;
        final price = bookingData['price']?.toDouble() ?? 0.0;
        final currency = bookingData['currency'] ?? 'INR';
        
        return 'From: $from\nTo: $to\n'
               'Departure: ${departureTime != null ? formatDateTime(departureTime) : 'TBD'}\n'
               'Price: ${formatPrice(price, currency)}';
               
      case 'hotel':
        final location = bookingData['location'] ?? '';
        final checkInDate = bookingData['checkInDate'] as String?;
        final checkOutDate = bookingData['checkOutDate'] as String?;
        final pricePerNight = bookingData['pricePerNight']?.toDouble() ?? 0.0;
        final currency = bookingData['currency'] ?? 'INR';
        final nights = calculateNights(checkInDate ?? '', checkOutDate ?? '');
        final totalPrice = calculateTotalHotelPrice(bookingData);
        
        return 'Location: $location\n'
               'Check-in: ${checkInDate != null ? formatDate(checkInDate) : 'TBD'}\n'
               'Check-out: ${checkOutDate != null ? formatDate(checkOutDate) : 'TBD'}\n'
               'Nights: $nights\n'
               'Price: ${formatPrice(pricePerNight, currency)}/night\n'
               'Total: ${formatPrice(totalPrice, currency)}';
               
      case 'bus':
        final from = bookingData['from'] ?? '';
        final to = bookingData['to'] ?? '';
        final departureTime = bookingData['departureTime'] as String?;
        final duration = bookingData['duration'] ?? '';
        final price = bookingData['price']?.toDouble() ?? 0.0;
        final currency = bookingData['currency'] ?? 'INR';
        
        return 'From: $from\nTo: $to\n'
               'Departure: ${departureTime != null ? formatDateTime(departureTime) : 'TBD'}\n'
               'Duration: $duration\n'
               'Price: ${formatPrice(price, currency)}';
               
      default:
        return 'Booking details available';
    }
  }
}