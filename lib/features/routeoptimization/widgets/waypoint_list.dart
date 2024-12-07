// lib/widgets/waypoint_list.dart

import 'package:flutter/material.dart';
import '../models/waypoint.dart';

class WaypointList extends StatelessWidget {
  final List<Waypoint> waypoints;
  final Function(int) onRemove;

  const WaypointList({
    Key? key,
    required this.waypoints,
    required this.onRemove,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: waypoints.length,
      itemBuilder: (context, index) {
        final waypoint = waypoints[index];
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
          trailing: IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () => onRemove(index),
          ),
        );
      },
    );
  }
}
