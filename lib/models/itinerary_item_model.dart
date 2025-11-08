import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// Enum for different types of itinerary items
enum ItineraryItemType {
  flight('Flight', Icons.flight),
  hotel('Hotel', Icons.hotel),
  activity('Activity', Icons.local_activity),
  restaurant('Restaurant', Icons.restaurant),
  transport('Transport', Icons.directions_bus),
  meeting('Meeting', Icons.people),
  other('Other', Icons.place);

  const ItineraryItemType(this.displayName, this.icon);

  final String displayName;
  final IconData icon;

  /// Convert string to enum
  static ItineraryItemType fromString(String value) {
    return ItineraryItemType.values.firstWhere(
      (type) => type.name.toLowerCase() == value.toLowerCase(),
      orElse: () => ItineraryItemType.other,
    );
  }

  /// Get all display names for dropdown
  static List<String> get allDisplayNames {
    return ItineraryItemType.values.map((type) => type.displayName).toList();
  }
}

class ItineraryItem {
  final String? id;
  final String tripId;
  final String title;
  final ItineraryItemType type;
  final Timestamp startTime;
  final Timestamp? endTime;
  final String location;
  final String? notes;
  final int? sortOrder;
  final Timestamp? createdAt;
  final Timestamp? updatedAt;
  final double? latitude;
  final double? longitude;

  const ItineraryItem({
    this.id,
    required this.tripId,
    required this.title,
    required this.type,
    required this.startTime,
    this.endTime,
    required this.location,
    this.notes,
    this.sortOrder,
    this.createdAt,
    this.updatedAt,
    this.latitude,
    this.longitude,
  });

  /// Creates an ItineraryItem from Firestore document data
  factory ItineraryItem.fromJson(Map<String, dynamic> json, String id) {
    return ItineraryItem(
      id: id,
      tripId: json['tripId'] as String,
      title: json['title'] as String,
      type: ItineraryItemType.fromString(json['type'] as String),
      startTime: json['startTime'] as Timestamp,
      endTime: json['endTime'] as Timestamp?,
      location: json['location'] as String,
      notes: json['notes'] as String?,
      sortOrder: json['sortOrder'] as int?,
      createdAt: json['createdAt'] as Timestamp?,
      updatedAt: json['updatedAt'] as Timestamp?,
      latitude: json['latitude'] as double?,
      longitude: json['longitude'] as double?,
    );
  }

  /// Converts ItineraryItem to JSON for Firestore
  Map<String, dynamic> toJson() {
    return {
      'tripId': tripId,
      'title': title,
      'type': type.name,
      'startTime': startTime,
      'endTime': endTime,
      'location': location,
      'notes': notes,
      'sortOrder': sortOrder,
      'createdAt': createdAt ?? Timestamp.now(),
      'updatedAt': Timestamp.now(),
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  /// Creates a copy of ItineraryItem with updated fields
  ItineraryItem copyWith({
    String? id,
    String? tripId,
    String? title,
    ItineraryItemType? type,
    Timestamp? startTime,
    Timestamp? endTime,
    String? location,
    String? notes,
    int? sortOrder,
    Timestamp? createdAt,
    Timestamp? updatedAt,
    double? latitude,
    double? longitude,
  }) {
    return ItineraryItem(
      id: id ?? this.id,
      tripId: tripId ?? this.tripId,
      title: title ?? this.title,
      type: type ?? this.type,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      location: location ?? this.location,
      notes: notes ?? this.notes,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
    );
  }

  /// Returns formatted start time string
  String get formattedStartTime {
    final dateTime = startTime.toDate();
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  /// Returns formatted end time string (if available)
  String? get formattedEndTime {
    if (endTime == null) return null;
    final dateTime = endTime!.toDate();
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  /// Returns formatted date string
  String get formattedDate {
    final dateTime = startTime.toDate();
    return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }

  /// Returns formatted time range string
  String get timeRangeString {
    if (endTime == null) {
      return formattedStartTime;
    }
    return '$formattedStartTime - $formattedEndTime';
  }

  /// Returns duration in minutes (if end time is available)
  int? get durationInMinutes {
    if (endTime == null) return null;
    return endTime!.toDate().difference(startTime.toDate()).inMinutes;
  }

  /// Returns formatted duration string
  String? get formattedDuration {
    final duration = durationInMinutes;
    if (duration == null) return null;
    
    if (duration < 60) {
      return '${duration}m';
    } else {
      final hours = duration ~/ 60;
      final minutes = duration % 60;
      if (minutes == 0) {
        return '${hours}h';
      } else {
        return '${hours}h ${minutes}m';
      }
    }
  }

  /// Check if this is an all-day event
  bool get isAllDay {
    return endTime == null;
  }

  /// Check if the item is currently happening
  bool get isHappening {
    final now = DateTime.now();
    final start = startTime.toDate();
    
    if (endTime == null) {
      // For all-day events, check if it's the same day
      return now.year == start.year && 
             now.month == start.month && 
             now.day == start.day;
    }
    
    final end = endTime!.toDate();
    return now.isAfter(start) && now.isBefore(end);
  }

  /// Check if the item is upcoming
  bool get isUpcoming {
    final now = DateTime.now();
    final start = startTime.toDate();
    return start.isAfter(now);
  }

  /// Check if the item is completed
  bool get isCompleted {
    final now = DateTime.now();
    
    if (endTime == null) {
      // For all-day events, check if the day has passed
      final start = startTime.toDate();
      final endOfDay = DateTime(start.year, start.month, start.day, 23, 59, 59);
      return now.isAfter(endOfDay);
    }
    
    final end = endTime!.toDate();
    return now.isAfter(end);
  }

  /// Get item status as string
  String get status {
    if (isHappening) return 'Now';
    if (isUpcoming) return 'Upcoming';
    if (isCompleted) return 'Completed';
    return 'Unknown';
  }

  /// Get status color
  Color get statusColor {
    if (isHappening) return Colors.green;
    if (isUpcoming) return Colors.blue;
    if (isCompleted) return Colors.grey;
    return Colors.grey;
  }

  /// Check if item has detailed location
  bool get hasLocation {
    return location.isNotEmpty;
  }

  /// Check if item has notes
  bool get hasNotes {
    return notes != null && notes!.isNotEmpty;
  }

  /// Check if item has coordinates
  bool get hasCoordinates {
    return latitude != null && longitude != null;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ItineraryItem && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'ItineraryItem(id: $id, title: $title, type: ${type.displayName}, startTime: $startTime)';
  }
}

/// Firestore converter for ItineraryItem
class ItineraryItemConverter {
  static final fromFirestore = (
    DocumentSnapshot<Map<String, dynamic>> snapshot,
    SnapshotOptions? options,
  ) {
    final data = snapshot.data();
    if (data == null) return null;
    return ItineraryItem.fromJson(data, snapshot.id);
  };

  static final toFirestore = (
    ItineraryItem item,
    SetOptions? options,
  ) {
    return item.toJson();
  };
}

/// Extension to get typed collection reference for itinerary items
extension ItineraryItemCollectionReference on DocumentReference {
  CollectionReference<ItineraryItem> get itineraryItemsCollection {
    return collection('itineraryItems').withConverter<ItineraryItem>(
      fromFirestore: ItineraryItemConverter.fromFirestore,
      toFirestore: ItineraryItemConverter.toFirestore,
    );
  }
}