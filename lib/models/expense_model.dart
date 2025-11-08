import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// Enum for different types of expense categories
enum ExpenseCategory {
  food('Food', Icons.restaurant),
  transport('Transport', Icons.directions_bus),
  accommodation('Accommodation', Icons.hotel),
  activity('Activity', Icons.local_activity),
  other('Other', Icons.more_horiz);

  const ExpenseCategory(this.displayName, this.icon);

  final String displayName;
  final IconData icon;

  /// Convert string to enum
  static ExpenseCategory fromString(String value) {
    return ExpenseCategory.values.firstWhere(
      (category) => category.name.toLowerCase() == value.toLowerCase(),
      orElse: () => ExpenseCategory.other,
    );
  }

  /// Get all display names for dropdown
  static List<String> get allDisplayNames {
    return ExpenseCategory.values.map((category) => category.displayName).toList();
  }

  /// Get category color for UI consistency
  Color get color {
    switch (this) {
      case ExpenseCategory.food:
        return Colors.orange;
      case ExpenseCategory.transport:
        return Colors.blue;
      case ExpenseCategory.accommodation:
        return Colors.green;
      case ExpenseCategory.activity:
        return Colors.purple;
      case ExpenseCategory.other:
        return Colors.grey;
    }
  }
}

class Expense {
  final String? id;
  final String tripId;
  final String title;
  final double amount;
  final ExpenseCategory category;
  final Timestamp date;
  final String paidByUserId;
  final String? notes;
  final Timestamp? createdAt;
  final Timestamp? updatedAt;

  const Expense({
    this.id,
    required this.tripId,
    required this.title,
    required this.amount,
    required this.category,
    required this.date,
    required this.paidByUserId,
    this.notes,
    this.createdAt,
    this.updatedAt,
  });

  /// Creates an Expense from Firestore document data
  factory Expense.fromJson(Map<String, dynamic> json, String id) {
    return Expense(
      id: id,
      tripId: json['tripId'] as String,
      title: json['title'] as String,
      amount: (json['amount'] as num).toDouble(),
      category: ExpenseCategory.fromString(json['category'] as String),
      date: json['date'] as Timestamp,
      paidByUserId: json['paidByUserId'] as String,
      notes: json['notes'] as String?,
      createdAt: json['createdAt'] as Timestamp?,
      updatedAt: json['updatedAt'] as Timestamp?,
    );
  }

  /// Converts Expense to JSON for Firestore
  Map<String, dynamic> toJson() {
    return {
      'tripId': tripId,
      'title': title,
      'amount': amount,
      'category': category.name,
      'date': date,
      'paidByUserId': paidByUserId,
      'notes': notes,
      'createdAt': createdAt ?? Timestamp.now(),
      'updatedAt': Timestamp.now(),
    };
  }

  /// Creates a copy of Expense with updated fields
  Expense copyWith({
    String? id,
    String? tripId,
    String? title,
    double? amount,
    ExpenseCategory? category,
    Timestamp? date,
    String? paidByUserId,
    String? notes,
    Timestamp? createdAt,
    Timestamp? updatedAt,
  }) {
    return Expense(
      id: id ?? this.id,
      tripId: tripId ?? this.tripId,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      date: date ?? this.date,
      paidByUserId: paidByUserId ?? this.paidByUserId,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Returns formatted amount string with currency
  String get formattedAmount {
    return '₹${amount.toStringAsFixed(2)}';
  }

  /// Returns formatted date string
  String get formattedDate {
    final dateTime = date.toDate();
    return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }

  /// Returns formatted date and time string
  String get formattedDateTime {
    final dateTime = date.toDate();
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '${formattedDate} at $hour:$minute';
  }

  /// Check if expense has notes
  bool get hasNotes {
    return notes != null && notes!.isNotEmpty;
  }

  /// Check if expense is from today
  bool get isToday {
    final now = DateTime.now();
    final expenseDate = date.toDate();
    return now.year == expenseDate.year &&
           now.month == expenseDate.month &&
           now.day == expenseDate.day;
  }

  /// Check if expense is from this week
  bool get isThisWeek {
    final now = DateTime.now();
    final expenseDate = date.toDate();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    return expenseDate.isAfter(weekStart.subtract(const Duration(days: 1)));
  }

  /// Get relative date description
  String get relativeDateDescription {
    final now = DateTime.now();
    final expenseDate = date.toDate();
    final difference = now.difference(expenseDate);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return weeks == 1 ? '1 week ago' : '$weeks weeks ago';
    } else {
      return formattedDate;
    }
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Expense && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Expense(id: $id, title: $title, amount: $amount, category: ${category.displayName})';
  }
}

/// Firestore converter for Expense
class ExpenseConverter {
  static final fromFirestore = (
    DocumentSnapshot<Map<String, dynamic>> snapshot,
    SnapshotOptions? options,
  ) {
    final data = snapshot.data();
    if (data == null) return null;
    return Expense.fromJson(data, snapshot.id);
  };

  static final toFirestore = (
    Expense expense,
    SetOptions? options,
  ) {
    return expense.toJson();
  };
}

/// Extension to get typed collection reference for expenses
extension ExpenseCollectionReference on DocumentReference {
  CollectionReference<Expense> get expensesCollection {
    return collection('expenses').withConverter<Expense>(
      fromFirestore: ExpenseConverter.fromFirestore,
      toFirestore: ExpenseConverter.toFirestore,
    );
  }
}

/// Utility class for expense calculations and analytics
class ExpenseAnalytics {
  /// Calculate total amount from list of expenses
  static double calculateTotal(List<Expense> expenses) {
    return expenses.fold(0.0, (sum, expense) => sum + expense.amount);
  }

  /// Calculate expenses by category
  static Map<ExpenseCategory, double> calculateByCategory(List<Expense> expenses) {
    final Map<ExpenseCategory, double> categoryTotals = {};
    
    for (final category in ExpenseCategory.values) {
      categoryTotals[category] = 0.0;
    }
    
    for (final expense in expenses) {
      categoryTotals[expense.category] = 
          (categoryTotals[expense.category] ?? 0.0) + expense.amount;
    }
    
    return categoryTotals;
  }

  /// Calculate expenses by user
  static Map<String, double> calculateByUser(List<Expense> expenses) {
    final Map<String, double> userTotals = {};
    
    for (final expense in expenses) {
      userTotals[expense.paidByUserId] = 
          (userTotals[expense.paidByUserId] ?? 0.0) + expense.amount;
    }
    
    return userTotals;
  }

  /// Calculate cost per person
  static double calculateCostPerPerson(List<Expense> expenses, int participantCount) {
    if (participantCount <= 0) return 0.0;
    return calculateTotal(expenses) / participantCount;
  }

  /// Get expenses from a specific date range
  static List<Expense> getExpensesInDateRange(
    List<Expense> expenses,
    DateTime startDate,
    DateTime endDate,
  ) {
    return expenses.where((expense) {
      final expenseDate = expense.date.toDate();
      return expenseDate.isAfter(startDate.subtract(const Duration(days: 1))) &&
             expenseDate.isBefore(endDate.add(const Duration(days: 1)));
    }).toList();
  }

  /// Get most expensive category
  static ExpenseCategory? getMostExpensiveCategory(List<Expense> expenses) {
    if (expenses.isEmpty) return null;
    
    final categoryTotals = calculateByCategory(expenses);
    
    ExpenseCategory? mostExpensive;
    double maxAmount = 0.0;
    
    categoryTotals.forEach((category, amount) {
      if (amount > maxAmount) {
        maxAmount = amount;
        mostExpensive = category;
      }
    });
    
    return mostExpensive;
  }
}