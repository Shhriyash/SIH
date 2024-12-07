// lib/providers/waypoint_provider.dart

import 'package:flutter/material.dart';
import '../models/waypoint.dart';
import '../services/firestore_service.dart';

class WaypointProvider with ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  final List<Waypoint> _waypoints = [];

  List<Waypoint> get waypoints => List.unmodifiable(_waypoints);

  /// Adds a new waypoint to the list and Firebase.
  Future<void> addWaypoint(Waypoint waypoint) async {
    _waypoints.add(waypoint);
    notifyListeners();
    await _firestoreService.addWaypoint(waypoint);
  }

  /// Updates an existing waypoint both locally and in Firebase.
  Future<void> updateWaypoint(Waypoint waypoint) async {
    int index = _waypoints.indexWhere((w) => w.postId == waypoint.postId);
    if (index != -1) {
      _waypoints[index] = waypoint;
      notifyListeners();
      await _firestoreService.updateWaypoint(waypoint);
    }
  }

  /// Marks a waypoint as delivered.
  Future<void> markAsDelivered(String postId) async {
    int index = _waypoints.indexWhere((w) => w.postId == postId);
    if (index != -1) {
      _waypoints[index].isDelivered = true;
      notifyListeners();
      await _firestoreService.markWaypointAsDelivered(postId);
    }
  }

  /// Removes a waypoint from the list and Firebase.
  Future<void> removeWaypoint(String postId) async {
    int index = _waypoints.indexWhere((w) => w.postId == postId);
    if (index != -1) {
      _waypoints.removeAt(index);
      notifyListeners();
      await _firestoreService.deleteWaypoint(postId);
    }
  }

  /// Resets the waypoint list.
  Future<void> resetWaypoints() async {
    for (var waypoint in _waypoints) {
      await _firestoreService.deleteWaypoint(waypoint.postId);
    }
    _waypoints.clear();
    notifyListeners();
  }

  /// Loads waypoints from Firebase.
  Future<void> loadWaypoints() async {
    try {
      List<Waypoint> fetchedWaypoints = await _firestoreService.fetchWaypoints();
      _waypoints.clear();
      _waypoints.addAll(fetchedWaypoints);
      notifyListeners();
    } catch (e) {
      print('Error loading waypoints: $e');
      // Optionally, handle errors by setting an error state or notifying the user
    }
  }
}
