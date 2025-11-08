import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../models/trip_model.dart';
import '../models/itinerary_item_model.dart';
import '../services/firestore_service.dart';
import '../services/geocoding_service.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/loading_indicator.dart';
import '../utils/app_constants.dart';

class AddItineraryItemScreen extends StatefulWidget {
  final String tripId;
  final DateTime selectedDate;
  final Trip trip;
  
  const AddItineraryItemScreen({
    super.key,
    required this.tripId,
    required this.selectedDate,
    required this.trip,
  });

  @override
  State<AddItineraryItemScreen> createState() => _AddItineraryItemScreenState();
}

class _AddItineraryItemScreenState extends State<AddItineraryItemScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _notesController = TextEditingController();
  
  ItineraryItemType _selectedType = ItineraryItemType.activity;
  TimeOfDay _startTime = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 10, minute: 0);
  bool _isLoading = false;
  
  final FirestoreService _firestoreService = FirestoreService();
  final GeocodingService _geocodingService = GeocodingService();
  
  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _notesController.dispose();
    super.dispose();
  }
  
  Future<void> _selectStartTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _startTime,
      helpText: 'Select start time',
    );
    
    if (picked != null) {
      setState(() {
        _startTime = picked;
        
        // Auto-adjust end time if it's before start time
        if (_endTime.hour < _startTime.hour || 
            (_endTime.hour == _startTime.hour && _endTime.minute <= _startTime.minute)) {
          _endTime = TimeOfDay(
            hour: (_startTime.hour + 1) % 24,
            minute: _startTime.minute,
          );
        }
      });
    }
  }
  
  Future<void> _selectEndTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _endTime,
      helpText: 'Select end time',
    );
    
    if (picked != null) {
      // Validate end time is after start time
      if (picked.hour > _startTime.hour || 
          (picked.hour == _startTime.hour && picked.minute > _startTime.minute)) {
        setState(() {
          _endTime = picked;
        });
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('End time must be after start time')),
          );
        }
      }
    }
  }
  
  Future<void> _saveItineraryItem() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final startDateTime = DateTime(
        widget.selectedDate.year,
        widget.selectedDate.month,
        widget.selectedDate.day,
        _startTime.hour,
        _startTime.minute,
      );
      
      final endDateTime = DateTime(
        widget.selectedDate.year,
        widget.selectedDate.month,
        widget.selectedDate.day,
        _endTime.hour,
        _endTime.minute,
      );
      
      // Geocode the location to get coordinates
      final location = _locationController.text.trim();
      LatLng? coordinates;
      if (location.isNotEmpty) {
        coordinates = await _geocodingService.geocodeAddress(location);
      }
      
      final item = ItineraryItem(
        tripId: widget.tripId,
        title: _titleController.text.trim(),
        type: _selectedType,
        startTime: Timestamp.fromDate(startDateTime),
        endTime: Timestamp.fromDate(endDateTime),
        location: location,
        notes: _notesController.text.trim(),
        latitude: coordinates?.latitude,
        longitude: coordinates?.longitude,
        createdAt: Timestamp.now(),
        updatedAt: Timestamp.now(),
      );
      
      await _firestoreService.addItineraryItem(widget.tripId, item);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(coordinates != null 
              ? 'Activity added successfully with location' 
              : 'Activity added (location could not be found)'),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add activity: $e')),
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
  
  @override
  Widget build(BuildContext context) {
    return LoadingOverlay(
      isLoading: _isLoading,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Add Activity'),
          centerTitle: true,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Date Display
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Adding to',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onPrimaryContainer,
                            ),
                          ),
                          Text(
                            widget.selectedDate.toString().split(' ')[0],
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onPrimaryContainer,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Activity Type Selection
                Text(
                  'Activity Type',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: ItineraryItemType.values.map((type) {
                    final isSelected = _selectedType == type;
                    return FilterChip(
                      label: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            type.icon,
                            size: 16,
                            color: isSelected ? Colors.white : type.color,
                          ),
                          const SizedBox(width: 4),
                          Text(type.displayName),
                        ],
                      ),
                      selected: isSelected,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() {
                            _selectedType = type;
                          });
                        }
                      },
                      backgroundColor: type.color.withOpacity(0.1),
                      selectedColor: type.color,
                      checkmarkColor: Colors.white,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : type.color,
                        fontWeight: FontWeight.bold,
                      ),
                    );
                  }).toList(),
                ),
                
                const SizedBox(height: 24),
                
                // Activity Title
                CustomTextField(
                  controller: _titleController,
                  labelText: 'Activity Title',
                  hintText: 'e.g., Visit Eiffel Tower',
                  prefixIcon: Icons.title,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter an activity title';
                    }
                    if (value.trim().length > AppConstants.maxNameLength) {
                      return 'Title must be less than ${AppConstants.maxNameLength} characters';
                    }
                    return null;
                  },
                ),
                
                const SizedBox(height: 16),
                
                // Location
                CustomTextField(
                  controller: _locationController,
                  labelText: 'Location (Optional)',
                  hintText: 'e.g., Champ de Mars, Paris',
                  prefixIcon: Icons.location_on,
                ),
                
                const SizedBox(height: 16),
                
                // Description
                CustomTextField(
                  controller: _descriptionController,
                  labelText: 'Description (Optional)',
                  hintText: 'Add details about this activity...',
                  prefixIcon: Icons.description,
                  maxLines: 3,
                  validator: (value) {
                    if (value != null && value.trim().length > AppConstants.maxDescriptionLength) {
                      return 'Description must be less than ${AppConstants.maxDescriptionLength} characters';
                    }
                    return null;
                  },
                ),
                
                const SizedBox(height: 24),
                
                // Time Selection
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Theme.of(context).colorScheme.outline,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Time',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      Row(
                        children: [
                          // Start Time
                          Expanded(
                            child: InkWell(
                              onTap: _selectStartTime,
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.surfaceVariant,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Start Time',
                                      style: Theme.of(context).textTheme.bodySmall,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _startTime.format(context),
                                      style: Theme.of(context).textTheme.titleMedium,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          
                          const SizedBox(width: 12),
                          
                          // End Time
                          Expanded(
                            child: InkWell(
                              onTap: _selectEndTime,
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.surfaceVariant,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'End Time',
                                      style: Theme.of(context).textTheme.bodySmall,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _endTime.format(context),
                                      style: Theme.of(context).textTheme.titleMedium,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 12),
                      
                      // Duration Display
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.secondaryContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.schedule,
                              size: 16,
                              color: Theme.of(context).colorScheme.onSecondaryContainer,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Duration: ${_calculateDuration()}',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.onSecondaryContainer,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Notes
                CustomTextField(
                  controller: _notesController,
                  labelText: 'Notes (Optional)',
                  hintText: 'Add any additional notes...',
                  prefixIcon: Icons.note,
                  maxLines: 3,
                ),
                
                const SizedBox(height: 32),
                
                // Save Button
                CustomButton(
                  text: 'Add Activity',
                  onPressed: _saveItineraryItem,
                  icon: Icons.check,
                ),
                
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  String _calculateDuration() {
    final startMinutes = _startTime.hour * 60 + _startTime.minute;
    final endMinutes = _endTime.hour * 60 + _endTime.minute;
    final durationMinutes = endMinutes - startMinutes;
    
    if (durationMinutes <= 0) return '0 min';
    
    final hours = durationMinutes ~/ 60;
    final minutes = durationMinutes % 60;
    
    if (hours == 0) {
      return '$minutes min';
    } else if (minutes == 0) {
      return '$hours hr';
    } else {
      return '$hours hr $minutes min';
    }
  }
}