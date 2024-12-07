// lib/services/firestore_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/waypoint.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Fetches all waypoints from the 'post_details' collection.
  Future<List<Waypoint>> fetchWaypoints() async {
    try {
      QuerySnapshot snapshot = await _db.collection('post_details').get();
      return snapshot.docs.map((doc) {
        return Waypoint.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    } catch (e) {
      print('Error in fetchWaypoints: $e');
      throw Exception('Failed to fetch waypoints: $e');
    }
  }

  /// Adds a new waypoint to Firebase.
  Future<void> addWaypoint(Waypoint waypoint) async {
    try {
      DocumentReference docRef =
          _db.collection('post_details').doc(waypoint.postId);
      await docRef.set(waypoint.toMap());
    } catch (e) {
      print('Error in addWaypoint: $e');
      throw Exception('Failed to add waypoint: $e');
    }
  }

  /// Updates a waypoint's data in Firebase.
  Future<void> updateWaypoint(Waypoint waypoint) async {
    try {
      DocumentReference docRef =
          _db.collection('post_details').doc(waypoint.postId);
      await docRef.update(waypoint.toMap());
    } catch (e) {
      print('Error in updateWaypoint: $e');
      throw Exception('Failed to update waypoint: $e');
    }
  }

  /// Marks a waypoint as delivered.
  Future<void> markWaypointAsDelivered(String postId) async {
    try {
      DocumentReference docRef = _db.collection('post_details').doc(postId);
      await docRef.update({
        'isDelivered': true,
        'deliveryTime': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error in markWaypointAsDelivered: $e');
      throw Exception('Failed to mark waypoint as delivered: $e');
    }
  }

  /// Deletes a waypoint from Firebase.
  Future<void> deleteWaypoint(String postId) async {
    try {
      DocumentReference docRef = _db.collection('post_details').doc(postId);
      await docRef.delete();
    } catch (e) {
      print('Error in deleteWaypoint: $e');
      throw Exception('Failed to delete waypoint: $e');
    }
  }
}
