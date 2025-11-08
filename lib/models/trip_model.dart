import 'package:cloud_firestore/cloud_firestore.dart';

class Trip {
  final String? id;
  final String title;
  final Timestamp startDate;
  final Timestamp endDate;
  final String ownerId;
  final List<String> collaboratorIds;
  final String? imageUrl;
  final Timestamp? createdAt;
  final Timestamp? updatedAt;

  const Trip({
    this.id,
    required this.title,
    required this.startDate,
    required this.endDate,
    required this.ownerId,
    this.collaboratorIds = const [],
    this.imageUrl,
    this.createdAt,
    this.updatedAt,
  });

  /// Creates a Trip from Firestore document data
  factory Trip.fromJson(Map<String, dynamic> json, String id) {
    return Trip(
      id: id,
      title: json['title'] as String,
      startDate: json['startDate'] as Timestamp,
      endDate: json['endDate'] as Timestamp,
      ownerId: json['ownerId'] as String,
      collaboratorIds: List<String>.from(json['collaboratorIds'] ?? []),
      imageUrl: json['imageUrl'] as String?,
      createdAt: json['createdAt'] as Timestamp?,
      updatedAt: json['updatedAt'] as Timestamp?,
    );
  }

  /// Converts Trip to JSON for Firestore
  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'startDate': startDate,
      'endDate': endDate,
      'ownerId': ownerId,
      'collaboratorIds': collaboratorIds,
      'imageUrl': imageUrl,
      'createdAt': createdAt ?? Timestamp.now(),
      'updatedAt': Timestamp.now(),
    };
  }

  /// Creates a copy of Trip with updated fields
  Trip copyWith({
    String? id,
    String? title,
    Timestamp? startDate,
    Timestamp? endDate,
    String? ownerId,
    List<String>? collaboratorIds,
    String? imageUrl,
    Timestamp? createdAt,
    Timestamp? updatedAt,
  }) {
    return Trip(
      id: id ?? this.id,
      title: title ?? this.title,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      ownerId: ownerId ?? this.ownerId,
      collaboratorIds: collaboratorIds ?? this.collaboratorIds,
      imageUrl: imageUrl ?? this.imageUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Returns formatted date range string
  String get dateRangeString {
    final start = startDate.toDate();
    final end = endDate.toDate();
    
    if (start.year == end.year && start.month == end.month && start.day == end.day) {
      // Same day trip
      return '${start.day}/${start.month}/${start.year}';
    } else if (start.year == end.year && start.month == end.month) {
      // Same month
      return '${start.day}-${end.day}/${start.month}/${start.year}';
    } else if (start.year == end.year) {
      // Same year
      return '${start.day}/${start.month} - ${end.day}/${end.month}/${start.year}';
    } else {
      // Different years
      return '${start.day}/${start.month}/${start.year} - ${end.day}/${end.month}/${end.year}';
    }
  }

  /// Returns the duration of the trip in days
  int get durationInDays {
    final start = startDate.toDate();
    final end = endDate.toDate();
    return end.difference(start).inDays + 1; // +1 to include both start and end days
  }

  /// Check if the trip is currently active (ongoing)
  bool get isActive {
    final now = DateTime.now();
    final start = startDate.toDate();
    final end = endDate.toDate();
    return now.isAfter(start) && now.isBefore(end.add(const Duration(days: 1)));
  }

  /// Check if the trip is upcoming
  bool get isUpcoming {
    final now = DateTime.now();
    final start = startDate.toDate();
    return start.isAfter(now);
  }

  /// Check if the trip is completed
  bool get isCompleted {
    final now = DateTime.now();
    final end = endDate.toDate();
    return now.isAfter(end.add(const Duration(days: 1)));
  }

  /// Get trip status as string
  String get status {
    if (isActive) return 'Active';
    if (isUpcoming) return 'Upcoming';
    if (isCompleted) return 'Completed';
    return 'Unknown';
  }

  /// Check if user is the owner of the trip
  bool isOwner(String userId) {
    return ownerId == userId;
  }

  /// Check if user is a collaborator
  bool isCollaborator(String userId) {
    return collaboratorIds.contains(userId);
  }

  /// Check if user has access to the trip (owner or collaborator)
  bool hasAccess(String userId) {
    return isOwner(userId) || isCollaborator(userId);
  }

  /// Get all members (owner + collaborators)
  List<String> get allMembers {
    return [ownerId, ...collaboratorIds];
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Trip && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Trip(id: $id, title: $title, startDate: $startDate, endDate: $endDate, ownerId: $ownerId)';
  }
}

/// Firestore converter for Trip
class TripConverter {
  static final fromFirestore = (
    DocumentSnapshot<Map<String, dynamic>> snapshot,
    SnapshotOptions? options,
  ) {
    final data = snapshot.data();
    if (data == null) return null;
    return Trip.fromJson(data, snapshot.id);
  };

  static final toFirestore = (
    Trip trip,
    SetOptions? options,
  ) {
    return trip.toJson();
  };
}

/// Extension to get typed collection reference
extension TripCollectionReference on FirebaseFirestore {
  CollectionReference<Trip> get tripsCollection {
    return collection('trips').withConverter<Trip>(
      fromFirestore: TripConverter.fromFirestore,
      toFirestore: TripConverter.toFirestore,
    );
  }
}