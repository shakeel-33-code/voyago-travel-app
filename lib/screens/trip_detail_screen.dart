import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/trip_model.dart';
import '../models/itinerary_item_model.dart';
import '../services/firebase_auth_service.dart';
import '../services/firestore_service.dart';
import '../services/ai_planner_service.dart';
import '../services/geocoding_service.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/loading_indicator.dart';
import '../utils/app_constants.dart';
import 'add_itinerary_item_screen.dart';
import 'navigation/map_screen.dart';
import 'expenses/expense_tracker_screen.dart';
import 'journal/travel_journal_screen.dart';

class TripDetailScreen extends StatefulWidget {
  final String tripId;
  
  const TripDetailScreen({
    super.key,
    required this.tripId,
  });

  @override
  State<TripDetailScreen> createState() => _TripDetailScreenState();
}

class _TripDetailScreenState extends State<TripDetailScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final FirebaseAuthService _authService = FirebaseAuthService();
  final AIPlannerService _aiPlannerService = AIPlannerService();
  final GeocodingService _geocodingService = GeocodingService();
  
  Trip? _trip;
  List<ItineraryItem> _itineraryItems = [];
  bool _isLoading = true;
  bool _isGeneratingAI = false;
  DateTime _selectedDate = DateTime.now();
  
  @override
  void initState() {
    super.initState();
    _loadTripData();
  }
  
  Future<void> _loadTripData() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final trip = await _firestoreService.getTrip(widget.tripId);
      if (trip != null) {
        setState(() {
          _trip = trip;
          _selectedDate = trip.startDate;
        });
        await _loadDayItinerary(_selectedDate);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load trip: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  Future<void> _loadDayItinerary(DateTime date) async {
    try {
      final items = await _firestoreService.getDayItinerary(widget.tripId, date);
      setState(() {
        _itineraryItems = items;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load itinerary: $e')),
        );
      }
    }
  }
  
  Future<void> _deleteTrip() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Trip'),
        content: const Text('Are you sure you want to delete this trip? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
      setState(() {
        _isLoading = true;
      });
      
      try {
        await _firestoreService.deleteTrip(widget.tripId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text(AppConstants.tripDeleted)),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete trip: $e')),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }
  
  Future<void> _deleteItineraryItem(ItineraryItem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Item'),
        content: Text('Are you sure you want to delete "${item.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
      try {
        await _firestoreService.deleteItineraryItem(widget.tripId, item.id);
        await _loadDayItinerary(_selectedDate);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Item deleted successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete item: $e')),
          );
        }
      }
    }
  }
  
  /// Shows the AI prompt dialog for generating itinerary
  Future<void> _showAIPromptDialog() async {
    final TextEditingController promptController = TextEditingController();
    final List<String> examplePrompts = _aiPlannerService.getExamplePrompts();
    
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Row(
                children: [
                  Icon(Icons.auto_awesome, color: Colors.purple),
                  SizedBox(width: 8),
                  Text('Generate with AI'),
                ],
              ),
              content: SizedBox(
                width: MediaQuery.of(context).size.width * 0.8,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Describe your ideal itinerary for ${_trip!.destination}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 16),
                    
                    CustomTextField(
                      controller: promptController,
                      labelText: 'Describe your trip',
                      hintText: 'e.g., 3 days in Goa, beach activities and local food',
                      maxLines: 3,
                      prefixIcon: Icons.edit_note,
                    ),
                    
                    const SizedBox(height: 16),
                    
                    Text(
                      'Example prompts:',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    
                    SizedBox(
                      height: 120,
                      child: ListView.builder(
                        itemCount: examplePrompts.length,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: InkWell(
                              onTap: () {
                                promptController.text = examplePrompts[index];
                                setDialogState(() {});
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.surfaceVariant,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  examplePrompts[index],
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                CustomButton(
                  text: 'Generate',
                  onPressed: promptController.text.trim().isNotEmpty
                      ? () {
                          Navigator.of(context).pop();
                          _generateAIItinerary(promptController.text.trim());
                        }
                      : null,
                  icon: Icons.auto_awesome,
                ),
              ],
            );
          },
        );
      },
    );
  }
  
  /// Generates AI itinerary based on user prompt
  Future<void> _generateAIItinerary(String prompt) async {
    if (!_aiPlannerService.isValidPrompt(prompt)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid prompt (5-500 characters)'),
        ),
      );
      return;
    }
    
    setState(() {
      _isGeneratingAI = true;
    });
    
    try {
      // Get AI suggestions
      final List<ItineraryItem> aiItems = await _aiPlannerService.getAiSuggestions(prompt);
      
      if (aiItems.isEmpty) {
        throw Exception('No suggestions generated. Please try a different prompt.');
      }
      
      // Geocode all AI-generated items before saving
      for (var item in aiItems) {
        item = item.copyWith(tripId: widget.tripId);
        if (item.location.isNotEmpty) {
          final coords = await _geocodingService.geocodeAddress(item.location);
          if (coords != null) {
            item = item.copyWith(
              latitude: coords.latitude,
              longitude: coords.longitude,
            );
          }
        }
      }
      
      // Add the items to Firestore in batch
      await _firestoreService.addItineraryItemsBatch(widget.tripId, aiItems);
      
      // Reload the current day's itinerary
      await _loadDayItinerary(_selectedDate);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Generated ${aiItems.length} activities with AI! 🎉'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to generate AI itinerary: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isGeneratingAI = false;
        });
      }
    }
  }
  
  /// Cache trip data for offline use
  Future<void> _cacheOfflineData() async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Caching trip data...'),
          backgroundColor: Colors.blue,
        ),
      );

      // Get all itinerary items for this trip
      final items = await _firestoreService.getItineraryItemsOnce(widget.tripId);
      
      // Save to SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final itemsJson = json.encode(items.map((item) => item.toJson()).toList());
      await prefs.setString('offline_trip_${widget.tripId}', itemsJson);
      
      // Also cache trip metadata
      final tripJson = json.encode(_trip!.toJson());
      await prefs.setString('offline_trip_meta_${widget.tripId}', tripJson);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Trip saved for offline use! 📱'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to cache trip data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  /// Navigate to map screen
  void _navigateToMap() {
    if (_trip == null) return;
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MapScreen(trip: _trip!),
      ),
    );
  }
  
  /// Navigate to expense tracker screen
  void _navigateToExpenses() {
    if (_trip == null) return;
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ExpenseTrackerScreen(trip: _trip!),
      ),
    );
  }
  
  /// Navigate to travel journal screen
  void _navigateToJournal() {
    if (_trip == null) return;
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TravelJournalScreen(trip: _trip!),
      ),
    );
  }
  
  void _addItineraryItem() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddItineraryItemScreen(
          tripId: widget.tripId,
          selectedDate: _selectedDate,
          trip: _trip!,
        ),
      ),
    ).then((_) => _loadDayItinerary(_selectedDate));
  }
  
  List<DateTime> _getTripDays() {
    if (_trip == null) return [];
    
    final days = <DateTime>[];
    var current = _trip!.startDate;
    
    while (current.isBefore(_trip!.endDate) || current.isAtSameMomentAs(_trip!.endDate)) {
      days.add(current);
      current = current.add(const Duration(days: 1));
    }
    
    return days;
  }
  
  @override
  Widget build(BuildContext context) {
    if (_trip == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    
    return LoadingOverlay(
      isLoading: _isLoading || _isGeneratingAI,
      message: _isGeneratingAI ? 'Generating AI itinerary...' : null,
      child: Scaffold(
        appBar: AppBar(
          title: Text(_trip!.title),
          centerTitle: true,
          actions: [
            IconButton(
              onPressed: _navigateToMap,
              icon: const Icon(Icons.map),
              tooltip: 'View Map',
            ),
            IconButton(
              onPressed: _navigateToJournal,
              icon: const Icon(Icons.book),
              tooltip: 'Travel Journal',
            ),
            IconButton(
              onPressed: _navigateToExpenses,
              icon: const Icon(Icons.receipt_long),
              tooltip: 'Expenses',
            ),
            IconButton(
              onPressed: _cacheOfflineData,
              icon: const Icon(Icons.download_for_offline),
              tooltip: 'Save Offline',
            ),
            IconButton(
              onPressed: _showAIPromptDialog,
              icon: const Icon(Icons.auto_awesome),
              tooltip: 'Generate with AI',
            ),
            PopupMenuButton(
              itemBuilder: (context) => [
                PopupMenuItem(
                  onTap: _deleteTrip,
                  child: const Row(
                    children: [
                      Icon(Icons.delete, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Delete Trip'),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _addItineraryItem,
          child: const Icon(Icons.add),
        ),
        body: Column(
          children: [
            // Trip Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).colorScheme.primaryContainer,
                    Theme.of(context).colorScheme.primaryContainer.withOpacity(0.8),
                  ],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _trip!.destination,
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            color: Theme.of(context).colorScheme.onPrimaryContainer,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (_trip!.description.isNotEmpty) ...[
                    Text(
                      _trip!.description,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 16,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _trip!.formattedDateRange,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onPrimaryContainer,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _trip!.status.color,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _trip!.status.displayName,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Date Selector
            Container(
              height: 80,
              color: Theme.of(context).colorScheme.surface,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                itemCount: _getTripDays().length,
                itemBuilder: (context, index) {
                  final day = _getTripDays()[index];
                  final isSelected = day.day == _selectedDate.day &&
                      day.month == _selectedDate.month &&
                      day.year == _selectedDate.year;
                  
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedDate = day;
                      });
                      _loadDayItinerary(day);
                    },
                    child: Container(
                      width: 60,
                      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.surfaceVariant,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            day.day.toString(),
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: isSelected
                                  ? Theme.of(context).colorScheme.onPrimary
                                  : Theme.of(context).colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][day.weekday - 1],
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: isSelected
                                  ? Theme.of(context).colorScheme.onPrimary
                                  : Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            
            // Itinerary Items
            Expanded(
              child: _itineraryItems.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.event_note,
                            size: 64,
                            color: Theme.of(context).colorScheme.outline,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No activities planned for this day',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: Theme.of(context).colorScheme.outline,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Tap the + button to add activities',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.outline,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _itineraryItems.length,
                      itemBuilder: (context, index) {
                        final item = _itineraryItems[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: item.type.color,
                              child: Icon(
                                item.type.icon,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                            title: Text(
                              item.title,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (item.description.isNotEmpty) ...[
                                  Text(item.description),
                                  const SizedBox(height: 4),
                                ],
                                Row(
                                  children: [
                                    Icon(
                                      Icons.access_time,
                                      size: 14,
                                      color: Theme.of(context).colorScheme.outline,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      item.formattedTimeRange,
                                      style: Theme.of(context).textTheme.bodySmall,
                                    ),
                                    if (item.location.isNotEmpty) ...[
                                      const SizedBox(width: 12),
                                      Icon(
                                        Icons.place,
                                        size: 14,
                                        color: Theme.of(context).colorScheme.outline,
                                      ),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          item.location,
                                          style: Theme.of(context).textTheme.bodySmall,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                            trailing: PopupMenuButton(
                              itemBuilder: (context) => [
                                PopupMenuItem(
                                  onTap: () => _deleteItineraryItem(item),
                                  child: const Row(
                                    children: [
                                      Icon(Icons.delete, color: Colors.red),
                                      SizedBox(width: 8),
                                      Text('Delete'),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}