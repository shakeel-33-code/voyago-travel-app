import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firestore_service.dart';
import '../services/firebase_auth_service.dart';
import '../models/trip_model.dart';
import '../models/itinerary_item_model.dart';

class TripSelectionDialog extends StatefulWidget {
  final Map<String, dynamic> bookingData;
  final String bookingType;

  const TripSelectionDialog({
    super.key,
    required this.bookingData,
    required this.bookingType,
  });

  @override
  State<TripSelectionDialog> createState() => _TripSelectionDialogState();
}

class _TripSelectionDialogState extends State<TripSelectionDialog> {
  final FirestoreService _firestoreService = FirestoreService();
  final FirebaseAuthService _authService = FirebaseAuthService();
  
  List<TripModel> _trips = [];
  bool _isLoading = true;
  bool _isSaving = false;
  TripModel? _selectedTrip;

  @override
  void initState() {
    super.initState();
    _loadTrips();
  }

  Future<void> _loadTrips() async {
    try {
      final user = _authService.currentUser;
      if (user != null) {
        final trips = await _firestoreService.getTripsOnce(user.uid);
        setState(() {
          _trips = trips;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load trips: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add to Trip'),
      content: SizedBox(
        width: double.maxFinite,
        child: _isLoading
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: CircularProgressIndicator(),
                ),
              )
            : _buildTripsList(),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _isSaving || _selectedTrip == null
              ? null
              : _addBookingToTrip,
          child: _isSaving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Add Booking'),
        ),
      ],
    );
  }

  Widget _buildTripsList() {
    if (_trips.isEmpty) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.luggage,
            size: 48,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            'No trips found',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Create a trip first to add bookings',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      );
    }

    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Select a trip to add this ${widget.bookingType} booking:',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          ...._trips.map((trip) => _buildTripTile(trip)),
        ],
      ),
    );
  }

  Widget _buildTripTile(TripModel trip) {
    final isSelected = _selectedTrip?.id == trip.id;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: RadioListTile<TripModel>(
        value: trip,
        groupValue: _selectedTrip,
        onChanged: (value) {
          setState(() {
            _selectedTrip = value;
          });
        },
        title: Text(
          trip.title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(trip.destination),
            const SizedBox(height: 4),
            Text(
              '${_formatDate(trip.startDate)} - ${_formatDate(trip.endDate)}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
        secondary: CircleAvatar(
          backgroundColor: isSelected
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.primaryContainer,
          child: Icon(
            Icons.place,
            color: isSelected
                ? Theme.of(context).colorScheme.onPrimary
                : Theme.of(context).colorScheme.onPrimaryContainer,
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Future<void> _addBookingToTrip() async {
    if (_selectedTrip == null) return;

    setState(() {
      _isSaving = true;
    });

    try {
      // Create itinerary item from booking data
      final itineraryItem = _createItineraryItemFromBooking();
      
      // Add to trip's itinerary
      await _firestoreService.addItineraryItem(_selectedTrip!.id, itineraryItem);

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${_getBookingTypeDisplayName()} added to ${_selectedTrip!.title}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isSaving = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add booking: $e')),
        );
      }
    }
  }

  ItineraryItemModel _createItineraryItemFromBooking() {
    String title;
    String description;
    DateTime startTime;
    DateTime endTime;
    String location;
    ItineraryItemType type;

    switch (widget.bookingType) {
      case 'flight':
        title = widget.bookingData['title'] ?? 'Flight';
        description = '${widget.bookingData['from']} → ${widget.bookingData['to']}\\n'
            'Airline: ${widget.bookingData['airline'] ?? 'N/A'}\\n'
            'Duration: ${widget.bookingData['duration'] ?? 'N/A'}';
        
        // Parse departure time or use current date
        startTime = _parseDateTime(widget.bookingData['departureTime']) ?? DateTime.now();
        endTime = _parseDateTime(widget.bookingData['arrivalTime']) ?? startTime.add(const Duration(hours: 2));
        
        location = widget.bookingData['from'] ?? 'Airport';
        type = ItineraryItemType.transport;
        break;

      case 'hotel':
        title = widget.bookingData['title'] ?? 'Hotel';
        description = 'Location: ${widget.bookingData['location'] ?? 'N/A'}\\n'
            'Room: ${widget.bookingData['roomType'] ?? 'N/A'}';
        
        if (widget.bookingData['rating'] != null) {
          description += '\\nRating: ${widget.bookingData['rating']}/5 ⭐';
        }
        
        // Parse check-in date or use current date
        startTime = _parseDate(widget.bookingData['checkInDate']) ?? DateTime.now();
        endTime = _parseDate(widget.bookingData['checkOutDate']) ?? startTime.add(const Duration(days: 1));
        
        location = widget.bookingData['location'] ?? 'Hotel';
        type = ItineraryItemType.accommodation;
        break;

      case 'bus':
        title = widget.bookingData['title'] ?? 'Bus';
        description = '${widget.bookingData['from']} → ${widget.bookingData['to']}\\n'
            'Operator: ${widget.bookingData['operator'] ?? 'N/A'}\\n'
            'Duration: ${widget.bookingData['duration'] ?? 'N/A'}';
        
        // Parse departure time or use current date
        startTime = _parseDateTime(widget.bookingData['departureTime']) ?? DateTime.now();
        endTime = _parseDateTime(widget.bookingData['arrivalTime']) ?? startTime.add(const Duration(hours: 4));
        
        location = widget.bookingData['from'] ?? 'Bus Station';
        type = ItineraryItemType.transport;
        break;

      default:
        title = 'Booking';
        description = 'Booking details';
        startTime = DateTime.now();
        endTime = startTime.add(const Duration(hours: 1));
        location = 'Location';
        type = ItineraryItemType.activity;
    }

    return ItineraryItemModel(
      id: '', // Will be generated by Firestore
      title: title,
      description: description,
      startTime: startTime,
      endTime: endTime,
      location: location,
      type: type,
      isCompleted: false,
    );
  }

  DateTime? _parseDateTime(String? dateTimeStr) {
    if (dateTimeStr == null || dateTimeStr.isEmpty) return null;
    
    try {
      // Try parsing various formats
      if (dateTimeStr.contains('T')) {
        return DateTime.parse(dateTimeStr);
      } else if (dateTimeStr.contains(':')) {
        // Try time format like "14:30"
        final parts = dateTimeStr.split(':');
        if (parts.length >= 2) {
          final hour = int.tryParse(parts[0]);
          final minute = int.tryParse(parts[1]);
          if (hour != null && minute != null) {
            final now = DateTime.now();
            return DateTime(now.year, now.month, now.day, hour, minute);
          }
        }
      }
    } catch (e) {
      // Ignore parsing errors
    }
    
    return null;
  }

  DateTime? _parseDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return null;
    
    try {
      if (dateStr.contains('T')) {
        return DateTime.parse(dateStr);
      } else if (dateStr.contains('/')) {
        // Try format like "25/12/2024"
        final parts = dateStr.split('/');
        if (parts.length == 3) {
          final day = int.tryParse(parts[0]);
          final month = int.tryParse(parts[1]);
          final year = int.tryParse(parts[2]);
          if (day != null && month != null && year != null) {
            return DateTime(year, month, day);
          }
        }
      } else if (dateStr.contains('-')) {
        // Try format like "2024-12-25"
        return DateTime.parse(dateStr);
      }
    } catch (e) {
      // Ignore parsing errors
    }
    
    return null;
  }

  String _getBookingTypeDisplayName() {
    switch (widget.bookingType) {
      case 'flight':
        return 'Flight booking';
      case 'hotel':
        return 'Hotel booking';
      case 'bus':
        return 'Bus booking';
      default:
        return 'Booking';
    }
  }
}