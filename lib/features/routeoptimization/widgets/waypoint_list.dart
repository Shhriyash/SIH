// lib/features/routeoptimization/widgets/waypoint_list.dart

import 'package:flutter/material.dart';
import '../models/waypoint.dart';

class WaypointList extends StatelessWidget {
  final List<Waypoint> waypoints;
  final Function(int) onRemove;

  const WaypointList({
    super.key,
    required this.waypoints,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: waypoints.length,
      itemBuilder: (context, index) {
        final waypoint = waypoints[index];
        var coordinates = waypoint.coordinate.split(',');
        String latitude = coordinates[0];
        String longitude = coordinates[1];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          child: ListTile(
            leading: CircleAvatar(
              child: Text('${index + 1}'),
            ),
            title: Text(waypoint.name),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Lat: $latitude, Lng: $longitude'),
                Text('Post ID: ${waypoint.postId}'),
                if (waypoint.isDelivered)
                  const Text(
                    'Delivered',
                    style: TextStyle(
                        color: Colors.green, fontWeight: FontWeight.bold),
                  ),
              ],
            ),
            trailing: IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () => onRemove(index),
            ),
          ),
        );
      },
    );
  }
}
