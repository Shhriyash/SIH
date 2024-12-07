// lib/features/routeoptimization/waypoint_manager.dart

import 'package:dakmadad/features/routeoptimization/waypoint_adder.dart';
import 'package:flutter/material.dart';
import 'models/waypoint.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class WaypointManager extends StatefulWidget {
  final List<Waypoint> waypoints;
  final Function(List<Waypoint>) onWaypointsChanged;

  const WaypointManager({
    super.key,
    required this.waypoints,
    required this.onWaypointsChanged,
  });

  @override
  _WaypointManagerState createState() => _WaypointManagerState();
}

class _WaypointManagerState extends State<WaypointManager> {
  late List<Waypoint> _waypoints;

  @override
  void initState() {
    super.initState();
    _waypoints = List.from(widget.waypoints);
  }

  // Validation for coordinates
  bool _validateCoordinate(String coordinate) {
    List<String> parts = coordinate.split(',');
    if (parts.length != 2) return false;

    double? lat = double.tryParse(parts[0].trim());
    double? lng = double.tryParse(parts[1].trim());

    if (lat == null || lng == null) return false;

    if (lat < -90 || lat > 90) return false;
    if (lng < -180 || lng > 180) return false;

    return true;
  }

  // Common dialog for Add/Edit
  Future<Waypoint?> _showWaypointDialog(
      {Waypoint? waypoint, int? index}) async {
    final TextEditingController nameController =
        TextEditingController(text: waypoint?.name ?? '');
    final TextEditingController coordinateController =
        TextEditingController(text: waypoint?.coordinate ?? '');
    final TextEditingController postIdController =
        TextEditingController(text: waypoint?.postId ?? '');

    return showDialog<Waypoint>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(waypoint == null ? 'Add Waypoint' : 'Edit Waypoint'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Name'),
                ),
                TextField(
                  controller: coordinateController,
                  decoration:
                      const InputDecoration(labelText: 'Coordinate (lat,lng)'),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                ),
                TextField(
                  controller: postIdController,
                  decoration: const InputDecoration(labelText: 'Post ID'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.pop(context),
            ),
            TextButton(
              child: Text(waypoint == null ? 'Add' : 'Save'),
              onPressed: () {
                if (nameController.text.isNotEmpty &&
                    coordinateController.text.isNotEmpty &&
                    postIdController.text.isNotEmpty) {
                  String name = nameController.text.trim();
                  String coordinate = coordinateController.text.trim();
                  String postId = postIdController.text.trim();

                  if (!_validateCoordinate(coordinate)) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text(
                              'Invalid coordinates. Please enter valid latitude and longitude.')),
                    );
                    return;
                  }

                  Waypoint newWaypoint = Waypoint(
                    name: name,
                    coordinate: coordinate,
                    postId: postId,
                  );

                  Navigator.pop(context, newWaypoint);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please fill in all fields')),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  // Add Waypoint
  void _addWaypoint() async {
    // Navigate to WaypointAdderPage and wait for the result
    List<Waypoint>? newWaypoints = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WaypointAdderPage(),
      ),
    );

    if (newWaypoints != null && newWaypoints.isNotEmpty) {
      setState(() {
        _waypoints.addAll(newWaypoints);
      });
      widget.onWaypointsChanged(_waypoints);
    }
  }

  // Edit Waypoint
  void _editWaypoint(int index) async {
    Waypoint? updatedWaypoint =
        await _showWaypointDialog(waypoint: _waypoints[index], index: index);

    if (updatedWaypoint != null) {
      setState(() {
        _waypoints[index] = updatedWaypoint;
      });

      widget.onWaypointsChanged(_waypoints);

      // Update Firebase
      await _updateFirebaseDeliveryStatus(updatedWaypoint);
    }
  }

  // Remove Waypoint
  void _removeWaypoint(int index) async {
    Waypoint waypoint = _waypoints[index];

    // Confirm deletion
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Waypoint'),
          content: const Text('Are you sure you want to delete this waypoint?'),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.pop(context, false),
            ),
            TextButton(
              child: const Text('Delete'),
              onPressed: () => Navigator.pop(context, true),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      setState(() {
        _waypoints.removeAt(index);
      });
      widget.onWaypointsChanged(_waypoints);

      // Remove from Firebase
      await _removeWaypointFromFirebase(waypoint);
    }
  }

  // Update Firebase Delivery Status
  Future<void> _updateFirebaseDeliveryStatus(Waypoint waypoint) async {
    try {
      DocumentReference docRef = FirebaseFirestore.instance
          .collection('deliveries')
          .doc(waypoint.postId);

      await docRef.set(
        {
          'name': waypoint.name,
          'location': {
            'latitude': double.parse(waypoint.coordinate.split(',')[0]),
            'longitude': double.parse(waypoint.coordinate.split(',')[1]),
          },
          'status': 'Delivered', // Adjust as necessary
          'updated_at': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true), // Use merge to update existing fields
      );

      print('Delivery status updated for post_id: ${waypoint.postId}');
    } catch (e) {
      print('Error updating delivery status: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update delivery status.')),
      );
    }
  }

  // Remove Waypoint from Firebase
  Future<void> _removeWaypointFromFirebase(Waypoint waypoint) async {
    try {
      DocumentReference docRef = FirebaseFirestore.instance
          .collection('deliveries')
          .doc(waypoint.postId);

      await docRef.delete();

      print('Delivery record deleted for post_id: ${waypoint.postId}');
    } catch (e) {
      print('Error deleting delivery record: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to delete delivery record.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          AppBar(
            title: const Text('Manage Waypoints'),
            automaticallyImplyLeading: false, // Removes the default back button
          ),
          Expanded(
            child: _waypoints.isEmpty
                ? const Center(
                    child: Text(
                      'No waypoints added.',
                      style: TextStyle(fontSize: 18),
                    ),
                  )
                : ListView.builder(
                    itemCount: _waypoints.length,
                    itemBuilder: (context, index) {
                      final waypoint = _waypoints[index];
                      var coordinates = waypoint.coordinate.split(',');
                      String latitude = coordinates[0];
                      String longitude = coordinates[1];
                      return ListTile(
                        title: Text(waypoint.name),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Lat: $latitude, Lng: $longitude'),
                            Text('Post ID: ${waypoint.postId}'),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () => _editWaypoint(index),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () => _removeWaypoint(index),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: FloatingActionButton.extended(
              onPressed: _addWaypoint,
              tooltip: 'Add Waypoint',
              icon: const Icon(Icons.add),
              label: const Text('Add Waypoint'),
            ),
          ),
        ],
      ),
    );
  }
}
