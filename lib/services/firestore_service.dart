import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../models/trip_model.dart';
import '../models/itinerary_item_model.dart';
import '../models/expense_model.dart';
import '../models/journal_entry_model.dart';
import '../utils/app_constants.dart';
import '../utils/firestore_extensions.dart';
import 'storage_service.dart';

class FirestoreService {
  static final FirestoreService _instance = FirestoreService._internal();
  factory FirestoreService() => _instance;
  FirestoreService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collection references
  CollectionReference get _usersCollection =>
      _firestore.collection(AppConstants.usersCollection);
  
  CollectionReference<Trip> get _tripsCollection =>
      _firestore.tripsCollection;

  /// Creates a new user document in Firestore
  Future<void> createUserInFirestore(UserModel user) async {
    try {
      await _usersCollection.doc(user.uid).set(user.toJson());
      debugPrint('User document created successfully for uid: ${user.uid}');
    } catch (e) {
      debugPrint('Error creating user document: $e');
      throw Exception('Failed to create user profile. Please try again.');
    }
  }

  /// Retrieves a user document from Firestore
  Future<UserModel?> getUser(String uid) async {
    try {
      final docSnapshot = await _usersCollection.doc(uid).get();
      
      if (docSnapshot.exists && docSnapshot.data() != null) {
        final data = docSnapshot.data() as Map<String, dynamic>;
        return UserModel.fromJson(data);
      }
      
      debugPrint('User document not found for uid: $uid');
      return null;
    } catch (e) {
      debugPrint('Error retrieving user document: $e');
      throw Exception('Failed to retrieve user profile. Please try again.');
    }
  }

  /// Updates user document in Firestore
  Future<void> updateUser(UserModel user) async {
    try {
      await _usersCollection.doc(user.uid).update(user.toJson());
      debugPrint('User document updated successfully for uid: ${user.uid}');
    } catch (e) {
      debugPrint('Error updating user document: $e');
      throw Exception('Failed to update user profile. Please try again.');
    }
  }

  /// Updates user's last login timestamp
  Future<void> updateLastLoginAt(String uid) async {
    try {
      await _usersCollection.doc(uid).update({
        'lastLoginAt': Timestamp.fromDate(DateTime.now()),
      });
      debugPrint('Last login timestamp updated for uid: $uid');
    } catch (e) {
      debugPrint('Error updating last login timestamp: $e');
      // Don't throw error for this non-critical operation
    }
  }

  /// Updates user's display name
  Future<void> updateDisplayName(String uid, String displayName) async {
    try {
      await _usersCollection.doc(uid).update({
        'displayName': displayName,
      });
      debugPrint('Display name updated for uid: $uid');
    } catch (e) {
      debugPrint('Error updating display name: $e');
      throw Exception('Failed to update display name. Please try again.');
    }
  }

  /// Updates user's photo URL
  Future<void> updatePhotoUrl(String uid, String photoUrl) async {
    try {
      await _usersCollection.doc(uid).update({
        'photoUrl': photoUrl,
      });
      debugPrint('Photo URL updated for uid: $uid');
    } catch (e) {
      debugPrint('Error updating photo URL: $e');
      throw Exception('Failed to update photo URL. Please try again.');
    }
  }

  /// Updates user document with custom data
  Future<void> updateUserData(String uid, Map<String, dynamic> data) async {
    try {
      await _usersCollection.doc(uid).update(data);
      debugPrint('User data updated successfully for uid: $uid');
    } catch (e) {
      debugPrint('Error updating user data: $e');
      throw Exception('Failed to update user data. Please try again.');
    }
  }

  /// Deletes user document from Firestore
  Future<void> deleteUser(String uid) async {
    try {
      await _usersCollection.doc(uid).delete();
      debugPrint('User document deleted for uid: $uid');
    } catch (e) {
      debugPrint('Error deleting user document: $e');
      throw Exception('Failed to delete user profile. Please try again.');
    }
  }

  /// Checks if user document exists in Firestore
  Future<bool> userExists(String uid) async {
    try {
      final docSnapshot = await _usersCollection.doc(uid).get();
      return docSnapshot.exists;
    } catch (e) {
      debugPrint('Error checking if user exists: $e');
      return false;
    }
  }

  /// Gets a stream of user document updates
  Stream<UserModel?> getUserStream(String uid) {
    return _usersCollection.doc(uid).snapshots().map((docSnapshot) {
      if (docSnapshot.exists && docSnapshot.data() != null) {
        final data = docSnapshot.data() as Map<String, dynamic>;
        return UserModel.fromJson(data);
      }
      return null;
    });
  }

  /// Batch operations for multiple user updates
  WriteBatch get batch => _firestore.batch();

  /// Commits a batch operation
  Future<void> commitBatch(WriteBatch batch) async {
    try {
      await batch.commit();
      debugPrint('Batch operation completed successfully');
    } catch (e) {
      debugPrint('Error committing batch operation: $e');
      throw Exception('Failed to complete batch operation. Please try again.');
    }
  }
  
  // Trip operations
  
  /// Creates a new trip in Firestore
  Future<Trip> createTrip(Trip trip) async {
    try {
      if (trip.id.isEmpty) {
        trip = trip.copyWith(id: _tripsCollection.doc().id);
      }
      
      await _tripsCollection.doc(trip.id).set(trip);
      return trip;
    } catch (e) {
      throw Exception('Failed to create trip: $e');
    }
  }
  
  /// Gets a specific trip by ID
  Future<Trip?> getTrip(String tripId) async {
    try {
      final doc = await _tripsCollection.doc(tripId).get();
      return doc.exists ? doc.data() : null;
    } catch (e) {
      throw Exception('Failed to get trip: $e');
    }
  }
  
  /// Updates an existing trip
  Future<void> updateTrip(Trip trip) async {
    try {
      await _tripsCollection.doc(trip.id).update(trip.toMap());
    } catch (e) {
      throw Exception('Failed to update trip: $e');
    }
  }
  
  /// Deletes a trip
  Future<void> deleteTrip(String tripId) async {
    try {
      // Delete all itinerary items first
      final itineraryCollection = _tripsCollection
          .doc(tripId)
          .collection(AppConstants.itineraryItemsCollection);
      
      final batch = _firestore.batch();
      final items = await itineraryCollection.get();
      
      for (final item in items.docs) {
        batch.delete(item.reference);
      }
      
      // Delete the trip itself
      batch.delete(_tripsCollection.doc(tripId));
      
      await batch.commit();
    } catch (e) {
      throw Exception('Failed to delete trip: $e');
    }
  }
  
  /// Gets all trips for a specific user
  Future<List<Trip>> getUserTrips(String userId) async {
    try {
      final query = _tripsCollection
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true);
      
      final snapshot = await query.get();
      return snapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      throw Exception('Failed to get user trips: $e');
    }
  }
  
  /// Gets upcoming trips for a user
  Future<List<Trip>> getUpcomingTrips(String userId) async {
    try {
      final now = DateTime.now();
      final query = _tripsCollection
          .where('userId', isEqualTo: userId)
          .where('startDate', isGreaterThanOrEqualTo: now)
          .orderBy('startDate');
      
      final snapshot = await query.get();
      return snapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      throw Exception('Failed to get upcoming trips: $e');
    }
  }
  
  /// Gets shared trips where user is a collaborator
  Future<List<Trip>> getSharedTrips(String userId) async {
    try {
      final query = _tripsCollection
          .where('collaborators', arrayContains: userId)
          .orderBy('startDate', descending: true);
      
      final snapshot = await query.get();
      return snapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      throw Exception('Failed to get shared trips: $e');
    }
  }
  
  /// Gets a stream of user's trips
  Stream<List<Trip>> getUserTripsStream(String userId) {
    return _tripsCollection
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }

  /// Gets user's trips once (not a stream)
  Future<List<TripModel>> getTripsOnce(String userId) async {
    try {
      final snapshot = await _tripsCollection
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();
      
      return snapshot.docs.map((doc) {
        final trip = doc.data();
        return TripModel(
          id: trip.id,
          title: trip.title,
          destination: trip.destination,
          startDate: trip.startDate,
          endDate: trip.endDate,
          description: trip.description,
          imageUrl: trip.imageUrl,
          userId: trip.userId,
          collaborators: trip.collaborators,
          createdAt: trip.createdAt,
          updatedAt: trip.updatedAt,
        );
      }).toList();
    } catch (e) {
      throw Exception('Failed to get trips: $e');
    }
  }
  
  /// Gets a stream of a specific trip
  Stream<Trip?> getTripStream(String tripId) {
    return _tripsCollection
        .doc(tripId)
        .snapshots()
        .map((doc) => doc.exists ? doc.data() : null);
  }
  
  /// Adds a collaborator to a trip
  Future<void> addCollaborator(String tripId, String userId) async {
    try {
      await _tripsCollection.doc(tripId).update({
        'collaborators': FieldValue.arrayUnion([userId])
      });
    } catch (e) {
      throw Exception('Failed to add collaborator: $e');
    }
  }
  
  /// Removes a collaborator from a trip
  Future<void> removeCollaborator(String tripId, String userId) async {
    try {
      await _tripsCollection.doc(tripId).update({
        'collaborators': FieldValue.arrayRemove([userId])
      });
    } catch (e) {
      throw Exception('Failed to remove collaborator: $e');
    }
  }
  
  // Itinerary Item operations
  
  /// Gets the itinerary items collection for a trip
  CollectionReference<ItineraryItem> _getItineraryCollection(String tripId) {
    return _tripsCollection
        .doc(tripId)
        .collection(AppConstants.itineraryItemsCollection)
        .withConverter<ItineraryItem>(
          fromFirestore: (snapshot, _) => ItineraryItem.fromMap(snapshot.data()!),
          toFirestore: (item, _) => item.toMap(),
        );
  }
  
  /// Creates a new itinerary item
  Future<ItineraryItem> createItineraryItem(String tripId, ItineraryItem item) async {
    try {
      final collection = _getItineraryCollection(tripId);
      
      if (item.id.isEmpty) {
        item = item.copyWith(id: collection.doc().id);
      }
      
      await collection.doc(item.id).set(item);
      return item;
    } catch (e) {
      throw Exception('Failed to create itinerary item: $e');
    }
  }
  
  /// Gets a specific itinerary item
  Future<ItineraryItem?> getItineraryItem(String tripId, String itemId) async {
    try {
      final doc = await _getItineraryCollection(tripId).doc(itemId).get();
      return doc.exists ? doc.data() : null;
    } catch (e) {
      throw Exception('Failed to get itinerary item: $e');
    }
  }
  
  /// Updates an itinerary item
  Future<void> updateItineraryItem(String tripId, ItineraryItem item) async {
    try {
      await _getItineraryCollection(tripId).doc(item.id).update(item.toMap());
    } catch (e) {
      throw Exception('Failed to update itinerary item: $e');
    }
  }
  
  /// Deletes an itinerary item
  Future<void> deleteItineraryItem(String tripId, String itemId) async {
    try {
      await _getItineraryCollection(tripId).doc(itemId).delete();
    } catch (e) {
      throw Exception('Failed to delete itinerary item: $e');
    }
  }
  
  /// Gets all itinerary items for a trip
  Future<List<ItineraryItem>> getTripItinerary(String tripId) async {
    try {
      final snapshot = await _getItineraryCollection(tripId)
          .orderBy('startTime')
          .get();
      
      return snapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      throw Exception('Failed to get trip itinerary: $e');
    }
  }
  
  /// Gets itinerary items for a specific day
  Future<List<ItineraryItem>> getDayItinerary(String tripId, DateTime date) async {
    try {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));
      
      final snapshot = await _getItineraryCollection(tripId)
          .where('startTime', isGreaterThanOrEqualTo: startOfDay)
          .where('startTime', isLessThan: endOfDay)
          .orderBy('startTime')
          .get();
      
      return snapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      throw Exception('Failed to get day itinerary: $e');
    }
  }
  
  /// Gets a stream of itinerary items for a trip
  Stream<List<ItineraryItem>> getTripItineraryStream(String tripId) {
    return _getItineraryCollection(tripId)
        .orderBy('startTime')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }
  
  /// Gets a stream of itinerary items for a specific day
  Stream<List<ItineraryItem>> getDayItineraryStream(String tripId, DateTime date) {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    
    return _getItineraryCollection(tripId)
        .where('startTime', isGreaterThanOrEqualTo: startOfDay)
        .where('startTime', isLessThan: endOfDay)
        .orderBy('startTime')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }
  
  /// Reorders itinerary items
  Future<void> reorderItineraryItems(String tripId, List<ItineraryItem> items) async {
    try {
      final batch = _firestore.batch();
      final collection = _getItineraryCollection(tripId);
      
      for (int i = 0; i < items.length; i++) {
        final updatedItem = items[i].copyWith(order: i);
        batch.update(collection.doc(updatedItem.id), updatedItem.toMap());
      }
      
      await batch.commit();
    } catch (e) {
      throw Exception('Failed to reorder itinerary items: $e');
    }
  }
  
  /// Adds multiple itinerary items in a batch operation (for AI-generated items)
  Future<void> addItineraryItemsBatch(String tripId, List<ItineraryItem> items) async {
    try {
      final batch = _firestore.batch();
      final collection = _getItineraryCollection(tripId);
      
      for (final item in items) {
        final docRef = collection.doc();
        final updatedItem = item.copyWith(id: docRef.id);
        batch.set(docRef, updatedItem.toJson());
      }
      
      await batch.commit();
      debugPrint('Successfully added ${items.length} itinerary items in batch');
    } catch (e) {
      debugPrint('Error adding itinerary items batch: $e');
      throw Exception('Failed to add itinerary items: $e');
    }
  }

  /// Gets itinerary items for a trip as a one-time fetch (for map display)
  Future<List<ItineraryItem>> getItineraryItemsOnce(String tripId) async {
    try {
      final querySnapshot = await _firestore
          .collection(AppConstants.tripsCollection)
          .doc(tripId)
          .collection(AppConstants.itineraryItemsCollection)
          .orderBy('startTime')
          .get();

      return querySnapshot.docs
          .map((doc) => ItineraryItem.fromJson(doc.data(), doc.id))
          .toList();
    } catch (e) {
      debugPrint('Error getting itinerary items: $e');
      throw Exception('Failed to get itinerary items: $e');
    }
  }

  // ============================================================================
  // EXPENSE MANAGEMENT METHODS
  // ============================================================================

  /// Helper method to get expenses collection reference
  CollectionReference<Expense> _getExpensesCollection(String tripId) {
    return _firestore
        .collection(AppConstants.tripsCollection)
        .doc(tripId)
        .collection('expenses')
        .withConverter<Expense>(
          fromFirestore: ExpenseConverter.fromFirestore,
          toFirestore: ExpenseConverter.toFirestore,
        );
  }

  /// Gets a stream of expenses for a trip, ordered by date (most recent first)
  Stream<List<Expense>> getExpenses(String tripId) {
    try {
      return _getExpensesCollection(tripId)
          .orderBy('date', descending: true)
          .snapshots()
          .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
    } catch (e) {
      debugPrint('Error getting expenses stream: $e');
      throw Exception('Failed to load expenses: $e');
    }
  }

  /// Adds a new expense to a trip
  Future<void> addExpense(String tripId, Expense expense) async {
    try {
      final collection = _getExpensesCollection(tripId);
      final docRef = collection.doc();
      
      final updatedExpense = expense.copyWith(
        id: docRef.id,
        createdAt: Timestamp.now(),
        updatedAt: Timestamp.now(),
      );
      
      await docRef.set(updatedExpense);
      debugPrint('Expense added successfully: ${expense.title}');
    } catch (e) {
      debugPrint('Error adding expense: $e');
      throw Exception('Failed to add expense: $e');
    }
  }

  /// Updates an existing expense
  Future<void> updateExpense(String tripId, Expense expense) async {
    try {
      if (expense.id == null) {
        throw Exception('Expense ID is required for update');
      }

      final collection = _getExpensesCollection(tripId);
      final updatedExpense = expense.copyWith(updatedAt: Timestamp.now());
      
      await collection.doc(expense.id).update(updatedExpense.toJson());
      debugPrint('Expense updated successfully: ${expense.title}');
    } catch (e) {
      debugPrint('Error updating expense: $e');
      throw Exception('Failed to update expense: $e');
    }
  }

  /// Deletes an expense from a trip
  Future<void> deleteExpense(String tripId, String expenseId) async {
    try {
      await _getExpensesCollection(tripId).doc(expenseId).delete();
      debugPrint('Expense deleted successfully: $expenseId');
    } catch (e) {
      debugPrint('Error deleting expense: $e');
      throw Exception('Failed to delete expense: $e');
    }
  }

  /// Gets expenses for a trip as a one-time fetch (for analytics)
  Future<List<Expense>> getExpensesOnce(String tripId) async {
    try {
      final querySnapshot = await _getExpensesCollection(tripId)
          .orderBy('date', descending: true)
          .get();

      return querySnapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      debugPrint('Error getting expenses: $e');
      throw Exception('Failed to get expenses: $e');
    }
  }

  /// Gets expenses for a specific date range
  Future<List<Expense>> getExpensesByDateRange(
    String tripId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final querySnapshot = await _getExpensesCollection(tripId)
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .orderBy('date', descending: true)
          .get();

      return querySnapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      debugPrint('Error getting expenses by date range: $e');
      throw Exception('Failed to get expenses for date range: $e');
    }
  }

  /// Gets expenses by category
  Future<List<Expense>> getExpensesByCategory(
    String tripId,
    ExpenseCategory category,
  ) async {
    try {
      final querySnapshot = await _getExpensesCollection(tripId)
          .where('category', isEqualTo: category.name)
          .orderBy('date', descending: true)
          .get();

      return querySnapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      debugPrint('Error getting expenses by category: $e');
      throw Exception('Failed to get expenses by category: $e');
    }
  }

  /// Gets expenses paid by a specific user
  Future<List<Expense>> getExpensesByUser(String tripId, String userId) async {
    try {
      final querySnapshot = await _getExpensesCollection(tripId)
          .where('paidByUserId', isEqualTo: userId)
          .orderBy('date', descending: true)
          .get();

      return querySnapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      debugPrint('Error getting expenses by user: $e');
      throw Exception('Failed to get expenses by user: $e');
    }
  }

  // ===== JOURNAL ENTRY OPERATIONS =====

  /// Get reference to journal entries subcollection
  CollectionReference<JournalEntry> _getJournalEntriesCollection(String tripId) {
    return _firestore
        .collection('trips')
        .doc(tripId)
        .collection('journalEntries')
        .withConverter<JournalEntry>(
          fromFirestore: (snapshot, _) => JournalEntry.fromJson(
            snapshot.data()!,
            snapshot.id,
          ),
          toFirestore: (entry, _) => entry.toJson(),
        );
  }

  /// Get stream of journal entries for a trip
  Stream<List<JournalEntry>> getJournalEntries(String tripId) {
    try {
      return _getJournalEntriesCollection(tripId)
          .orderBy('date', descending: true)
          .snapshots()
          .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
    } catch (e) {
      debugPrint('Error getting journal entries stream: $e');
      throw Exception('Failed to get journal entries: $e');
    }
  }

  /// Add a new journal entry
  Future<void> addJournalEntry(String tripId, JournalEntry entry) async {
    try {
      await _getJournalEntriesCollection(tripId).add(entry);
      debugPrint('Journal entry added successfully for trip: $tripId');
    } catch (e) {
      debugPrint('Error adding journal entry: $e');
      throw Exception('Failed to add journal entry: $e');
    }
  }

  /// Update an existing journal entry
  Future<void> updateJournalEntry(String tripId, JournalEntry entry) async {
    try {
      if (entry.id == null || entry.id!.isEmpty) {
        throw Exception('Journal entry ID is required for updates');
      }

      await _getJournalEntriesCollection(tripId)
          .doc(entry.id)
          .update(entry.toJson());
      
      debugPrint('Journal entry updated successfully: ${entry.id}');
    } catch (e) {
      debugPrint('Error updating journal entry: $e');
      throw Exception('Failed to update journal entry: $e');
    }
  }

  /// Delete a journal entry and its associated image
  Future<void> deleteJournalEntry(String tripId, JournalEntry entry) async {
    try {
      if (entry.id == null || entry.id!.isEmpty) {
        throw Exception('Journal entry ID is required for deletion');
      }

      // Delete the document from Firestore
      final docRef = _getJournalEntriesCollection(tripId).doc(entry.id);
      await docRef.delete();

      // Delete the associated image if it exists
      if (entry.imageUrl != null && entry.imageUrl!.isNotEmpty) {
        final storageService = StorageService();
        await storageService.deleteImage(entry.imageUrl!);
      }

      debugPrint('Journal entry deleted successfully: ${entry.id}');
    } catch (e) {
      debugPrint('Error deleting journal entry: $e');
      throw Exception('Failed to delete journal entry: $e');
    }
  }

  /// Get journal entries for a specific date range
  Stream<List<JournalEntry>> getJournalEntriesByDateRange(
    String tripId,
    DateTime startDate,
    DateTime endDate,
  ) {
    try {
      return _getJournalEntriesCollection(tripId)
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .orderBy('date', descending: true)
          .snapshots()
          .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
    } catch (e) {
      debugPrint('Error getting journal entries by date range: $e');
      throw Exception('Failed to get journal entries by date range: $e');
    }
  }

  /// Get journal entries by user
  Future<List<JournalEntry>> getJournalEntriesByUser(
    String tripId,
    String userId,
  ) async {
    try {
      final querySnapshot = await _getJournalEntriesCollection(tripId)
          .where('userId', isEqualTo: userId)
          .orderBy('date', descending: true)
          .get();

      return querySnapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      debugPrint('Error getting journal entries by user: $e');
      throw Exception('Failed to get journal entries by user: $e');
    }
  }

  /// Get a single journal entry by ID
  Future<JournalEntry?> getJournalEntry(String tripId, String entryId) async {
    try {
      final docSnapshot = await _getJournalEntriesCollection(tripId)
          .doc(entryId)
          .get();

      if (docSnapshot.exists) {
        return docSnapshot.data();
      }
      return null;
    } catch (e) {
      debugPrint('Error getting journal entry: $e');
      throw Exception('Failed to get journal entry: $e');
    }
  }
}