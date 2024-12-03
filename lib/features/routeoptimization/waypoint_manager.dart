// lib/features/routeoptimization/waypoint_manager.dart

import 'package:flutter/material.dart';
import 'models/waypoint.dart';

class WaypointManager extends StatefulWidget {
  final List<Waypoint> waypoints;
  final Function(List<Waypoint>) onWaypointsChanged;

  const WaypointManager({
    Key? key,
    required this.waypoints,
    required this.onWaypointsChanged,
  }) : super(key: key);

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

  void _addWaypoint() {
    showDialog(
      context: context,
      builder: (context) {
        final TextEditingController nameController = TextEditingController();
        final TextEditingController coordinateController =
            TextEditingController();

        return AlertDialog(
          title: const Text('Add Waypoint'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              TextField(
                controller: coordinateController,
                decoration:
                    const InputDecoration(labelText: 'Coordinate (lat,lng)'),
              ),
            ],
          ),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.pop(context),
            ),
            TextButton(
              child: const Text('Add'),
              onPressed: () {
                if (nameController.text.isNotEmpty &&
                    coordinateController.text.isNotEmpty) {
                  setState(() {
                    _waypoints.add(
                      Waypoint(
                        name: nameController.text.trim(),
                        coordinate: coordinateController.text.trim(),
                      ),
                    );
                  });
                  widget.onWaypointsChanged(_waypoints);
                  Navigator.pop(context);
                } else {
                  // Show an error message if inputs are empty
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

  void _editWaypoint(int index) {
    final waypoint = _waypoints[index];
    final TextEditingController nameController =
        TextEditingController(text: waypoint.name);
    final TextEditingController coordinateController =
        TextEditingController(text: waypoint.coordinate);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Waypoint'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              TextField(
                controller: coordinateController,
                decoration:
                    const InputDecoration(labelText: 'Coordinate (lat,lng)'),
              ),
            ],
          ),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.pop(context),
            ),
            TextButton(
              child: const Text('Save'),
              onPressed: () {
                if (nameController.text.isNotEmpty &&
                    coordinateController.text.isNotEmpty) {
                  setState(() {
                    _waypoints[index] = Waypoint(
                      name: nameController.text.trim(),
                      coordinate: coordinateController.text.trim(),
                    );
                  });
                  widget.onWaypointsChanged(_waypoints);
                  Navigator.pop(context);
                } else {
                  // Show an error message if inputs are empty
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

  void _removeWaypoint(int index) {
    setState(() {
      _waypoints.removeAt(index);
    });
    widget.onWaypointsChanged(_waypoints);
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Manage Waypoints'),
        ),
        body: ListView.builder(
          itemCount: _waypoints.length,
          itemBuilder: (context, index) {
            final waypoint = _waypoints[index];
            return ListTile(
              title: Text(waypoint.name),
              subtitle: Text(waypoint.coordinate),
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
        floatingActionButton: FloatingActionButton(
          onPressed: _addWaypoint,
          child: const Icon(Icons.add),
          tooltip: 'Add Waypoint',
        ),
      ),
    );
  }
}
