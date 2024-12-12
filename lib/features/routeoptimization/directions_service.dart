// lib/services/directions_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;

class DirectionsService {
  final String apiKey;

  DirectionsService({required this.apiKey});

  /// Fetches directions between two points using Google Directions API.
  Future<String> getDirections(
      double originLat, double originLng, double destLat, double destLng,
      {List<String>? waypoints}) async {
    String origin = '$originLat,$originLng';
    String destination = '$destLat,$destLng';
    String waypointsParam = '';

    if (waypoints != null && waypoints.isNotEmpty) {
      waypointsParam = waypoints.join('|');
    }

    String url =
        'https://maps.googleapis.com/maps/api/directions/json?origin=$origin&destination=$destination&mode=driving&key=$apiKey';

    if (waypointsParam.isNotEmpty) {
      url += '&waypoints=optimize:true|$waypointsParam';
    }

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      if (data['status'] == 'OK') {
        // Extract the encoded polyline from the first route
        return data['routes'][0]['overview_polyline']['points'];
      } else {
        throw Exception('Directions API error: ${data['status']}');
      }
    } else {
      throw Exception('Failed to fetch directions');
    }
  }
}
