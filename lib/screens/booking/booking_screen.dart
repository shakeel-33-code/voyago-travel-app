import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/booking_service.dart';
import '../../services/firestore_service.dart';
import '../../services/firebase_auth_service.dart';
import '../../models/trip_model.dart';
import '../../models/itinerary_item_model.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/loading_indicator.dart';
import 'trip_selection_dialog.dart';

class BookingScreen extends StatefulWidget {
  const BookingScreen({super.key});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  final BookingService _bookingService = BookingService();
  final FirestoreService _firestoreService = FirestoreService();
  final TextEditingController _fromController = TextEditingController();
  final TextEditingController _toController = TextEditingController();

  String _currentType = 'flight';
  bool _isLoading = false;
  List<Map<String, dynamic>> _results = [];

  @override
  void dispose() {
    _fromController.dispose();
    _toController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Book Tickets & Hotels'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Header with booking type selection
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'What would you like to book?',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 16),
                // Booking type selector
                _buildTypeSelector(),
                const SizedBox(height: 20),
                // Search fields
                _buildSearchFields(),
                const SizedBox(height: 16),
                // Search button
                CustomButton(
                  onPressed: _isLoading ? null : _performSearch,
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text('Search ${_bookingService.getBookingTypeDisplayName(_currentType)}'),
                ),
              ],
            ),
          ),
          const Divider(),
          // Results section
          Expanded(
            child: _buildResultsSection(),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeSelector() {
    return SegmentedButton<String>(
      segments: const [
        ButtonSegment(
          value: 'flight',
          label: Text('✈️ Flights'),
        ),
        ButtonSegment(
          value: 'hotel',
          label: Text('🏨 Hotels'),
        ),
        ButtonSegment(
          value: 'bus',
          label: Text('🚌 Buses'),
        ),
      ],
      selected: {_currentType},
      onSelectionChanged: (Set<String> selected) {
        setState(() {
          _currentType = selected.first;
          _results.clear(); // Clear previous results
        });
      },
    );
  }

  Widget _buildSearchFields() {
    if (_currentType == 'hotel') {
      return Column(
        children: [
          CustomTextField(
            controller: _fromController,
            labelText: 'Destination',
            hintText: 'Enter city or location',
            prefixIcon: Icons.location_on,
          ),
          const SizedBox(height: 12),
          CustomTextField(
            controller: _toController,
            labelText: 'Additional Preferences (Optional)',
            hintText: 'e.g., Beach view, City center',
            prefixIcon: Icons.tune,
          ),
        ],
      );
    } else {
      return Column(
        children: [
          CustomTextField(
            controller: _fromController,
            labelText: 'From',
            hintText: 'Enter departure city',
            prefixIcon: Icons.flight_takeoff,
          ),
          const SizedBox(height: 12),
          CustomTextField(
            controller: _toController,
            labelText: 'To',
            hintText: 'Enter destination city',
            prefixIcon: Icons.flight_land,
          ),
        ],
      );
    }
  }

  Widget _buildResultsSection() {
    if (_isLoading) {
      return const Center(child: LoadingIndicator());
    }

    if (_results.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _getResultsIcon(),
              size: 64,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              'Search for ${_bookingService.getBookingTypeDisplayName(_currentType).toLowerCase()}',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Enter your travel details and tap search',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _results.length,
      itemBuilder: (context, index) {
        final result = _results[index];
        return _buildResultCard(result);
      },
    );
  }

  Widget _buildResultCard(Map<String, dynamic> result) {
    switch (_currentType) {
      case 'flight':
        return _buildFlightCard(result);
      case 'hotel':
        return _buildHotelCard(result);
      case 'bus':
        return _buildBusCard(result);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildFlightCard(Map<String, dynamic> flight) {
    final price = flight['price']?.toDouble() ?? 0.0;
    final currency = flight['currency'] ?? 'INR';
    final departureTime = flight['departureTime'] as String?;
    final arrivalTime = flight['arrivalTime'] as String?;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        flight['title'] ?? 'Flight',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      Text(
                        '${flight['from']} → ${flight['to']}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                Text(
                  _bookingService.formatPrice(price, currency),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildInfoChip(
                    'Departure',
                    departureTime != null ? _bookingService.formatTime(departureTime) : 'TBD',
                  ),
                ),
                Expanded(
                  child: _buildInfoChip(
                    'Arrival',
                    arrivalTime != null ? _bookingService.formatTime(arrivalTime) : 'TBD',
                  ),
                ),
                Expanded(
                  child: _buildInfoChip(
                    'Duration',
                    flight['duration'] ?? 'N/A',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _showFlightDetails(flight),
                    child: const Text('Details'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () => _showTripSelectionDialog(flight),
                    child: const Text('Book'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHotelCard(Map<String, dynamic> hotel) {
    final pricePerNight = hotel['pricePerNight']?.toDouble() ?? 0.0;
    final currency = hotel['currency'] ?? 'INR';
    final totalPrice = _bookingService.calculateTotalHotelPrice(hotel);
    final nights = _bookingService.calculateNights(
      hotel['checkInDate'] ?? '',
      hotel['checkOutDate'] ?? '',
    );

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        hotel['title'] ?? 'Hotel',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      Text(
                        hotel['location'] ?? 'Location',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      if (hotel['rating'] != null) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.star,
                              color: Colors.amber,
                              size: 16,
                            ),
                            Text(
                              ' ${hotel['rating']}/5',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      _bookingService.formatPrice(totalPrice, currency),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    Text(
                      '$nights nights',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildInfoChip(
                    'Check-in',
                    hotel['checkInDate'] != null 
                        ? _bookingService.formatDate(hotel['checkInDate'])
                        : 'TBD',
                  ),
                ),
                Expanded(
                  child: _buildInfoChip(
                    'Check-out',
                    hotel['checkOutDate'] != null 
                        ? _bookingService.formatDate(hotel['checkOutDate'])
                        : 'TBD',
                  ),
                ),
                Expanded(
                  child: _buildInfoChip(
                    'Per Night',
                    _bookingService.formatPrice(pricePerNight, currency),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _showHotelDetails(hotel),
                    child: const Text('Details'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () => _showTripSelectionDialog(hotel),
                    child: const Text('Book'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBusCard(Map<String, dynamic> bus) {
    final price = bus['price']?.toDouble() ?? 0.0;
    final currency = bus['currency'] ?? 'INR';
    final departureTime = bus['departureTime'] as String?;
    final arrivalTime = bus['arrivalTime'] as String?;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        bus['title'] ?? 'Bus',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      Text(
                        '${bus['from']} → ${bus['to']}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      Text(
                        'Operator: ${bus['operator'] ?? 'N/A'}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                Text(
                  _bookingService.formatPrice(price, currency),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildInfoChip(
                    'Departure',
                    departureTime != null ? _bookingService.formatTime(departureTime) : 'TBD',
                  ),
                ),
                Expanded(
                  child: _buildInfoChip(
                    'Arrival',
                    arrivalTime != null ? _bookingService.formatTime(arrivalTime) : 'TBD',
                  ),
                ),
                Expanded(
                  child: _buildInfoChip(
                    'Duration',
                    bus['duration'] ?? 'N/A',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _showBusDetails(bus),
                    child: const Text('Details'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () => _showTripSelectionDialog(bus),
                    child: const Text('Book'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
      ],
    );
  }

  IconData _getResultsIcon() {
    switch (_currentType) {
      case 'flight':
        return Icons.flight;
      case 'hotel':
        return Icons.hotel;
      case 'bus':
        return Icons.directions_bus;
      default:
        return Icons.search;
    }
  }

  Future<void> _performSearch() async {
    if (_fromController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_currentType == 'hotel' 
              ? 'Please enter a destination' 
              : 'Please enter departure location'),
        ),
      );
      return;
    }

    if (_currentType != 'hotel' && _toController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter destination location'),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _results.clear();
    });

    try {
      final query = _currentType == 'hotel' 
          ? _fromController.text.trim()
          : '${_fromController.text.trim()} to ${_toController.text.trim()}';

      final results = await _bookingService.searchBookings(_currentType, query);
      
      setState(() {
        _results = results;
      });

      if (results.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No ${_bookingService.getBookingTypeDisplayName(_currentType).toLowerCase()} found for your search'),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Search failed: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showFlightDetails(Map<String, dynamic> flight) {
    showDialog(
      context: context,
      builder: (context) => _FlightDetailsDialog(flight: flight, bookingService: _bookingService),
    );
  }

  void _showHotelDetails(Map<String, dynamic> hotel) {
    showDialog(
      context: context,
      builder: (context) => _HotelDetailsDialog(hotel: hotel, bookingService: _bookingService),
    );
  }

  void _showBusDetails(Map<String, dynamic> bus) {
    showDialog(
      context: context,
      builder: (context) => _BusDetailsDialog(bus: bus, bookingService: _bookingService),
    );
  }

  Future<void> _showTripSelectionDialog(Map<String, dynamic> bookingData) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => TripSelectionDialog(
        bookingData: bookingData,
        bookingType: _currentType,
      ),
    );

    // If booking was successfully added, you might want to show a confirmation
    if (result == true && mounted) {
      // Additional success handling if needed
      debugPrint('Booking successfully added to trip');
    }
  }
}

// Flight Details Dialog
class _FlightDetailsDialog extends StatelessWidget {
  final Map<String, dynamic> flight;
  final BookingService bookingService;

  const _FlightDetailsDialog({
    required this.flight,
    required this.bookingService,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(flight['title'] ?? 'Flight Details'),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDetailRow('Airline', flight['airline'] ?? 'N/A'),
            _buildDetailRow('Aircraft', flight['aircraft'] ?? 'N/A'),
            _buildDetailRow('Class', flight['bookingClass'] ?? 'N/A'),
            _buildDetailRow('From', flight['from'] ?? 'N/A'),
            _buildDetailRow('To', flight['to'] ?? 'N/A'),
            _buildDetailRow('Duration', flight['duration'] ?? 'N/A'),
            if (flight['departureTime'] != null)
              _buildDetailRow('Departure', bookingService.formatDateTime(flight['departureTime'])),
            if (flight['arrivalTime'] != null)
              _buildDetailRow('Arrival', bookingService.formatDateTime(flight['arrivalTime'])),
            _buildDetailRow(
              'Price',
              bookingService.formatPrice(
                flight['price']?.toDouble() ?? 0.0,
                flight['currency'] ?? 'INR',
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

// Hotel Details Dialog
class _HotelDetailsDialog extends StatelessWidget {
  final Map<String, dynamic> hotel;
  final BookingService bookingService;

  const _HotelDetailsDialog({
    required this.hotel,
    required this.bookingService,
  });

  @override
  Widget build(BuildContext context) {
    final amenities = hotel['amenities'] as List<dynamic>? ?? [];
    
    return AlertDialog(
      title: Text(hotel['title'] ?? 'Hotel Details'),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDetailRow('Location', hotel['location'] ?? 'N/A'),
            _buildDetailRow('Room Type', hotel['roomType'] ?? 'N/A'),
            if (hotel['rating'] != null)
              _buildDetailRow('Rating', '${hotel['rating']}/5 ⭐'),
            if (hotel['checkInDate'] != null)
              _buildDetailRow('Check-in', bookingService.formatDate(hotel['checkInDate'])),
            if (hotel['checkOutDate'] != null)
              _buildDetailRow('Check-out', bookingService.formatDate(hotel['checkOutDate'])),
            _buildDetailRow(
              'Nights',
              bookingService.calculateNights(
                hotel['checkInDate'] ?? '',
                hotel['checkOutDate'] ?? '',
              ).toString(),
            ),
            _buildDetailRow(
              'Per Night',
              bookingService.formatPrice(
                hotel['pricePerNight']?.toDouble() ?? 0.0,
                hotel['currency'] ?? 'INR',
              ),
            ),
            _buildDetailRow(
              'Total Price',
              bookingService.formatPrice(
                bookingService.calculateTotalHotelPrice(hotel),
                hotel['currency'] ?? 'INR',
              ),
            ),
            if (hotel['description'] != null) ...[
              const SizedBox(height: 8),
              Text(
                'Description:',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(hotel['description']),
            ],
            if (amenities.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Amenities:',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Wrap(
                spacing: 4,
                children: amenities.map((amenity) => Chip(
                  label: Text(amenity.toString()),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                )).toList(),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

// Bus Details Dialog
class _BusDetailsDialog extends StatelessWidget {
  final Map<String, dynamic> bus;
  final BookingService bookingService;

  const _BusDetailsDialog({
    required this.bus,
    required this.bookingService,
  });

  @override
  Widget build(BuildContext context) {
    final amenities = bus['amenities'] as List<dynamic>? ?? [];
    
    return AlertDialog(
      title: Text(bus['title'] ?? 'Bus Details'),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDetailRow('Operator', bus['operator'] ?? 'N/A'),
            _buildDetailRow('Bus Type', bus['busType'] ?? 'N/A'),
            _buildDetailRow('From', bus['from'] ?? 'N/A'),
            _buildDetailRow('To', bus['to'] ?? 'N/A'),
            _buildDetailRow('Duration', bus['duration'] ?? 'N/A'),
            if (bus['departureTime'] != null)
              _buildDetailRow('Departure', bookingService.formatDateTime(bus['departureTime'])),
            if (bus['arrivalTime'] != null)
              _buildDetailRow('Arrival', bookingService.formatDateTime(bus['arrivalTime'])),
            _buildDetailRow(
              'Price',
              bookingService.formatPrice(
                bus['price']?.toDouble() ?? 0.0,
                bus['currency'] ?? 'INR',
              ),
            ),
            if (amenities.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Amenities:',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Wrap(
                spacing: 4,
                children: amenities.map((amenity) => Chip(
                  label: Text(amenity.toString()),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                )).toList(),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}