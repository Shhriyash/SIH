// lib/services/qr_parser.dart
import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart'; 
import '../models/waypoint.dart';

class QRParser {
  // Private helper function to parse a Map into a Waypoint
  static Waypoint _parseDataToWaypoint(Map<String, dynamic> data) {
    final String postId = data['post_id'] ?? '';
    final String name = data['geocoded_info']?['formattedAddress'] ?? 'Unknown Address';

    double latitude = 0.0;
    double longitude = 0.0;

    if (data['geocoded_info']?['latitude'] is num) {
      latitude = (data['geocoded_info']['latitude'] as num).toDouble();
    }

    if (data['geocoded_info']?['longitude'] is num) {
      longitude = (data['geocoded_info']['longitude'] as num).toDouble();
    }

    final String coordinate = '$latitude,$longitude';

    if (postId.isEmpty) {
      throw Exception("Post ID is missing in the data.");
    }

    return Waypoint(
      name: name,
      coordinate: coordinate,
      postId: postId,
    );
  }

  // Async method that now only handles a URL
  static Future<Waypoint> parseQRCode(String qrData) async {
    final response = await http.get(Uri.parse(qrData));

    if (response.statusCode != 200) {
      throw Exception('Failed to fetch data from URL: ${response.statusCode}');
    }

    final data = json.decode(response.body) as Map<String, dynamic>;
    return _parseDataToWaypoint(data);
  }

  // Optional: If you still want to use isolates for CPU-bound parsing
  static Future<Waypoint> parseQRCodeIsolate(String qrData) async {
    final response = await http.get(Uri.parse(qrData));

    if (response.statusCode != 200) {
      throw Exception('Failed to fetch data from URL: ${response.statusCode}');
    }

    final data = json.decode(response.body) as Map<String, dynamic>;

    return await compute(_parseDataToWaypoint, data);
  }
}
