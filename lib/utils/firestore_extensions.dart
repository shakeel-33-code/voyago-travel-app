import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/trip_model.dart';
import '../utils/app_constants.dart';

/// Extension on FirebaseFirestore to provide typed collection references
extension FirestoreExtensions on FirebaseFirestore {
  /// Gets a typed reference to the trips collection
  CollectionReference<Trip> get tripsCollection {
    return collection(AppConstants.tripsCollection).withConverter<Trip>(
      fromFirestore: (snapshot, _) => Trip.fromMap(snapshot.data()!),
      toFirestore: (trip, _) => trip.toMap(),
    );
  }
}