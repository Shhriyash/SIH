// lib/models/waypoint.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class Waypoint {
  final String name;
  final String coordinate; // Format: "latitude,longitude"
  final String postId;
  bool isDelivered;

  Waypoint({
    required this.name,
    required this.coordinate,
    required this.postId,
    this.isDelivered = false,
  });

  factory Waypoint.fromMap(Map<String, dynamic> map, String postId) {
    double latitude = map['geocoded_info']['latitude'];
    double longitude = map['geocoded_info']['longitude'];
    return Waypoint(
      name: map['geocoded_info']['formattedAddress'] ?? 'Unknown Address',
      coordinate: '$latitude,$longitude',
      postId: postId,
      isDelivered: map['isDelivered'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    List<String> coords = coordinate.split(',');
    return {
      'post_id': postId,
      'geocoded_info': {
        'formattedAddress': name,
        'latitude': double.parse(coords[0]),
        'longitude': double.parse(coords[1]),
      },
      'isDelivered': isDelivered,
      'deliveryTime': isDelivered ? FieldValue.serverTimestamp() : null,
    };
  }
}
