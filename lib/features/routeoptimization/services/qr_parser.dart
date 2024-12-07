// lib/services/qr_parser.dart

import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart'; // Needed for compute
import '../models/waypoint.dart';

class QRParser {
  // Top-level function for parsing QR code data into Waypoint
  static Waypoint parseQRCode(String qrData) {
    final Map<String, dynamic> data = json.decode(qrData);

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

    return Waypoint(
      name: name,
      coordinate: coordinate,
      postId: postId,
    );
  }

  // Method to parse QR code using isolates
  static Future<Waypoint> parseQRCodeIsolate(String qrData) async {
    return await compute(parseQRCode, qrData);
  }
}
