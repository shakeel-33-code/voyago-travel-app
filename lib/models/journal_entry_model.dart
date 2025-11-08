import 'package:cloud_firestore/cloud_firestore.dart';

class JournalEntry {
  final String? id;
  final String tripId;
  final String userId;
  final String title;
  final String? text;
  final String? imageUrl;
  final Timestamp date;

  JournalEntry({
    this.id,
    required this.tripId,
    required this.userId,
    required this.title,
    this.text,
    this.imageUrl,
    required this.date,
  });

  // Convert to JSON for Firestore
  Map<String, dynamic> toJson() {
    return {
      'tripId': tripId,
      'userId': userId,
      'title': title,
      'text': text,
      'imageUrl': imageUrl,
      'date': date,
    };
  }

  // Create from Firestore document
  factory JournalEntry.fromJson(Map<String, dynamic> json, String id) {
    return JournalEntry(
      id: id,
      tripId: json['tripId'] ?? '',
      userId: json['userId'] ?? '',
      title: json['title'] ?? '',
      text: json['text'],
      imageUrl: json['imageUrl'],
      date: json['date'] ?? Timestamp.now(),
    );
  }

  // Create a copy with some fields updated
  JournalEntry copyWith({
    String? id,
    String? tripId,
    String? userId,
    String? title,
    String? text,
    String? imageUrl,
    Timestamp? date,
  }) {
    return JournalEntry(
      id: id ?? this.id,
      tripId: tripId ?? this.tripId,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      text: text ?? this.text,
      imageUrl: imageUrl ?? this.imageUrl,
      date: date ?? this.date,
    );
  }

  // Helper to check if entry has an image
  bool get hasImage => imageUrl != null && imageUrl!.isNotEmpty;

  // Helper to get formatted date string
  String get formattedDate {
    final dateTime = date.toDate();
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }

  @override
  String toString() {
    return 'JournalEntry(id: $id, tripId: $tripId, userId: $userId, title: $title, text: $text, imageUrl: $imageUrl, date: $date)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is JournalEntry &&
        other.id == id &&
        other.tripId == tripId &&
        other.userId == userId &&
        other.title == title &&
        other.text == text &&
        other.imageUrl == imageUrl &&
        other.date == date;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        tripId.hashCode ^
        userId.hashCode ^
        title.hashCode ^
        text.hashCode ^
        imageUrl.hashCode ^
        date.hashCode;
  }
}