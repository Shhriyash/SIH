// lib/features/routeoptimization/waypoint_manager_page.dart

import 'package:dakmadad/features/routeoptimization/helpers/waypoint_provider.dart';
import 'package:dakmadad/features/routeoptimization/models/waypoint.dart';
import 'package:dakmadad/features/routeoptimization/waypoint_adder.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';


class WaypointManagerPage extends StatelessWidget {
  const WaypointManagerPage({super.key});

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

  // Dialog for Editing Waypoint
  Future<void> _showWaypointDialog({
    required BuildContext context,
    required Waypoint waypoint,
    required int index,
  }) async {
    final TextEditingController nameController =
        TextEditingController(text: waypoint.name);
    final TextEditingController coordinateController =
        TextEditingController(text: waypoint.coordinate);

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Waypoint'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Name',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: coordinateController,
                  decoration: const InputDecoration(
                    labelText: 'Coordinate (lat,lng)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.pop(context),
            ),
            ElevatedButton(
              child: const Text('Save'),
              onPressed: () async {
                if (nameController.text.isNotEmpty &&
                    coordinateController.text.isNotEmpty) {
                  String name = nameController.text.trim();
                  String coordinate = coordinateController.text.trim();

                  if (!_validateCoordinate(coordinate)) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text(
                              'Invalid coordinates. Please enter valid latitude and longitude.')),
                    );
                    return;
                  }

                  Waypoint updatedWaypoint = Waypoint(
                    name: name,
                    coordinate: coordinate,
                    postId: waypoint.postId,
                    isDelivered: waypoint.isDelivered,
                  );

                  // Update via Provider
                  await Provider.of<WaypointProvider>(context, listen: false)
                      .updateWaypoint(updatedWaypoint);

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Waypoint updated successfully.')),
                  );

                  Navigator.pop(context);
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

  // Remove Waypoint
  Future<void> _removeWaypoint(BuildContext context, int index) async {
    Waypoint waypoint =
        Provider.of<WaypointProvider>(context, listen: false).waypoints[index];

    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Remove Waypoint'),
          content: const Text(
              'Are you sure you want to remove this waypoint from the list?'),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.pop(context, false),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              child: const Text('Remove'),
              onPressed: () => Navigator.pop(context, true),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      try {
        await Provider.of<WaypointProvider>(context, listen: false)
            .removeWaypoint(waypoint.postId);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Waypoint removed successfully.')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to remove waypoint: $e')),
        );
      }
    }
  }

  // Mark as Delivered
  Future<void> _markAsDelivered(BuildContext context, int index) async {
    Waypoint waypoint =
        Provider.of<WaypointProvider>(context, listen: false).waypoints[index];
    try {
      await Provider.of<WaypointProvider>(context, listen: false)
          .markAsDelivered(waypoint.postId);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Waypoint marked as delivered.')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to mark as delivered: $e')),
      );
    }
  }

  // Reset Waypoints
  Future<void> _resetWaypoints(BuildContext context) async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Reset Waypoints'),
          content: const Text(
              'Are you sure you want to reset the waypoint list? This will remove all waypoints.'),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.pop(context, false),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              child: const Text('Reset'),
              onPressed: () => Navigator.pop(context, true),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      await Provider.of<WaypointProvider>(context, listen: false)
          .resetWaypoints();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Waypoint list has been reset.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Waypoints'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Reset List',
            onPressed: () => _resetWaypoints(context),
          ),
        ],
      ),
      body: Consumer<WaypointProvider>(
        builder: (context, waypointProvider, child) {
          if (waypointProvider.waypoints.isEmpty) {
            return const Center(
              child: Text(
                'No waypoints added.',
                style: TextStyle(fontSize: 18),
              ),
            );
          }

          return ListView.builder(
            itemCount: waypointProvider.waypoints.length,
            itemBuilder: (context, index) {
              final waypoint = waypointProvider.waypoints[index];
              var coordinates = waypoint.coordinate.split(',');
              String latitude = coordinates[0];
              String longitude = coordinates[1];
              return Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Card(
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Waypoint Header
                        Row(
                          mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                '${index + 1}. ${waypoint.name}',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleLarge,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (waypoint.isDelivered)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.green,
                                  borderRadius:
                                      BorderRadius.circular(12),
                                ),
                                child: const Text(
                                  'Delivered',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        // Coordinates
                        Text(
                          'Latitude: $latitude\nLongitude: $longitude',
                          style: Theme.of(context)
                              .textTheme
                              .bodyLarge,
                        ),
                        const SizedBox(height: 8),
                        // Post ID
                        Text(
                          'Post ID: ${waypoint.postId}',
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium,
                        ),
                        const SizedBox(height: 12),
                        // Action Buttons
                        Row(
                          mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                          children: [
                            // Edit Button
                            ElevatedButton.icon(
                              onPressed: () => _showWaypointDialog(
                                  context: context,
                                  waypoint: waypoint,
                                  index: index),
                              icon: const Icon(Icons.edit),
                              label: const Text('Edit'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    Theme.of(context).primaryColor,
                              ),
                            ),
                            // Delete Button
                            ElevatedButton.icon(
                              onPressed: () => _removeWaypoint(context, index),
                              icon: const Icon(Icons.delete),
                              label: const Text('Delete'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                              ),
                            ),
                            // Mark as Delivered Button
                            ElevatedButton.icon(
                              onPressed: waypoint.isDelivered
                                  ? null
                                  : () => _markAsDelivered(context, index),
                              icon: const Icon(Icons.check),
                              label: const Text('Mark as Delivered'),
                              style: ElevatedButton.styleFrom(
                                foregroundColor: Colors.black,
                                backgroundColor: Colors.yellow,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          // Navigate to WaypointAdderPage
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const WaypointAdderPage(),
            ),
          );
          // No need to handle the result as Provider updates automatically
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Waypoint'),
        tooltip: 'Add Waypoint',
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
