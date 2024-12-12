// lib/services/firestore_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/waypoint.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String _collection = 'post_details'; // Ensure this matches your Firestore collection

  /// Fetches all waypoints from Firestore.
  Future<List<Waypoint>> fetchWaypoints() async {
    try {
      QuerySnapshot snapshot = await _db.collection(_collection).get();
      return snapshot.docs
          .map((doc) => Waypoint.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    } catch (e) {
      print('Error fetching waypoints: $e');
      rethrow;
    }
  }

  /// Adds a new waypoint to Firestore.
  Future<void> addWaypoint(Waypoint waypoint) async {
    try {
      await _db.collection(_collection).doc(waypoint.postId).set(waypoint.toMap());
    } catch (e) {
      print('Error adding waypoint: $e');
      rethrow;
    }
  }

  /// Updates an existing waypoint in Firestore.
  Future<void> updateWaypoint(Waypoint waypoint) async {
    try {
      await _db.collection(_collection).doc(waypoint.postId).update(waypoint.toMap());
    } catch (e) {
      print('Error updating waypoint: $e');
      rethrow;
    }
  }

  /// Deletes a waypoint from Firestore.
  Future<void> deleteWaypoint(String postId) async {
    try {
      await _db.collection(_collection).doc(postId).delete();
    } catch (e) {
      print('Error deleting waypoint: $e');
      rethrow;
    }
  }
}
