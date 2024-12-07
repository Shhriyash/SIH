// lib/services/isolate_services.dart

import 'dart:convert';
import 'dart:isolate';
import '../models/waypoint.dart';

// Define a message structure
class IsolateMessage {
  final String qrData;
  final SendPort sendPort;

  IsolateMessage(this.qrData, this.sendPort);
}

// Isolate entry point
void qrParserIsolate(IsolateMessage message) {
  try {
    final Map<String, dynamic> data = json.decode(message.qrData);

    String postId = data['post_id'] ?? '';
    String name =
        data['geocoded_info']?['formattedAddress'] ?? 'Unknown Address';
    double latitude = 0.0;
    double longitude = 0.0;

    if (data['geocoded_info']?['latitude'] is num) {
      latitude = (data['geocoded_info']['latitude'] as num).toDouble();
    }

    if (data['geocoded_info']?['longitude'] is num) {
      longitude = (data['geocoded_info']['longitude'] as num).toDouble();
    }

    String coordinate = '$latitude,$longitude';

    if (postId.isEmpty) {
      throw Exception("Post ID is missing in the QR data.");
    }

    Waypoint waypoint = Waypoint(
      name: name,
      coordinate: coordinate,
      postId: postId,
    );

    // Send the result back
    message.sendPort.send(waypoint);
  } catch (e) {
    // Send the error back
    message.sendPort.send(e);
  }
}
