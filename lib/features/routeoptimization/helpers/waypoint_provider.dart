// lib/providers/waypoint_provider.dart

import 'package:dakmadad/features/routeoptimization/services/firestore_service.dart';
import 'package:flutter/material.dart';
import '../models/waypoint.dart';

class WaypointProvider with ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  final List<Waypoint> _waypoints = [];

  List<Waypoint> get waypoints => List.unmodifiable(_waypoints);

  /// Adds a new waypoint to the local list.
  Future<void> addWaypoint(Waypoint waypoint) async {
    // Check for duplicate postId to prevent duplicates
    if (_waypoints.any((w) => w.postId == waypoint.postId)) {
      throw Exception(
          'Waypoint with postId ${waypoint.postId} already exists.');
    }

    _waypoints.add(waypoint);
    notifyListeners();
  }

  /// Updates an existing waypoint locally.
  Future<void> updateWaypoint(Waypoint waypoint) async {
    int index = _waypoints.indexWhere((w) => w.postId == waypoint.postId);
    if (index != -1) {
      _waypoints[index] = waypoint;
      notifyListeners();
    } else {
      throw Exception('Waypoint with postId ${waypoint.postId} not found.');
    }
  }

  /// Marks a waypoint as delivered locally.
  Future<void> markAsDelivered(String postId) async {
    int index = _waypoints.indexWhere((w) => w.postId == postId);
    if (index != -1) {
      _waypoints[index].isDelivered = true;
      notifyListeners();
      await _firestoreService.updateWaypoint(_waypoints[index]);
    } else {
      throw Exception('Waypoint with postId $postId not found.');
    }
  }

  /// Removes a waypoint from the local list.
  Future<void> removeWaypoint(String postId) async {
    int index = _waypoints.indexWhere((w) => w.postId == postId);
    if (index != -1) {
      _waypoints.removeAt(index);
      notifyListeners();
    } else {
      throw Exception('Waypoint with postId $postId not found.');
    }
  }

  /// Resets the local waypoint list.
  Future<void> resetWaypoints() async {
    _waypoints.clear();
    notifyListeners();
  }

  /// Loads waypoints into the local list (placeholder for local storage integration).
  Future<void> loadWaypoints() async {
    try {
      // Placeholder for loading waypoints from a local database or other storage.
      // Implement your local storage logic here if needed.
      notifyListeners();
    } catch (e) {
      print('Error loading waypoints: $e');
      // Optionally, handle errors by setting an error state or notifying the user
    }
  }
}
