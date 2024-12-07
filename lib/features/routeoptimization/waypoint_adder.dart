// lib/pages/waypoint_adder_page.dart

import 'package:dakmadad/features/routeoptimization/models/waypoint.dart';
import 'package:dakmadad/features/routeoptimization/services/firestore_service.dart';
import 'package:dakmadad/features/routeoptimization/services/qr_parser.dart';
import 'package:dakmadad/features/routeoptimization/widgets/waypoint_list.dart';
import 'package:flutter/material.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';

class WaypointAdderPage extends StatefulWidget {
  const WaypointAdderPage({Key? key}) : super(key: key);

  @override
  _WaypointAdderPageState createState() => _WaypointAdderPageState();
}

class _WaypointAdderPageState extends State<WaypointAdderPage> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  QRViewController? controller;
  List<Waypoint> scannedWaypoints = [];
  bool isScanning = false;

  final FirestoreService _firestoreService = FirestoreService();

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  void _startQRScan() async {
    setState(() {
      isScanning = true;
    });
    await showDialog(
      context: context,
      builder: (context) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Scan QR Code'),
          ),
          body: QRView(
            key: qrKey,
            onQRViewCreated: _onQRViewCreated,
          ),
        );
      },
    );
    setState(() {
      isScanning = false;
    });
  }

  void _onQRViewCreated(QRViewController qrController) {
    controller = qrController;
    controller?.scannedDataStream.listen((scanData) async {
      controller?.pauseCamera();
      String qrCodeData = scanData.code ?? '';

      print('Scanned QR Code Data: $qrCodeData');

      // Inside _onQRViewCreated

      try {
        // Parse QR code data using isolate
        Waypoint waypoint = await QRParser.parseQRCodeIsolate(qrCodeData);

        setState(() {
          scannedWaypoints.add(waypoint);
        });

        // Update Firebase
        await _firestoreService.updateDeliveryStatus(
          waypoint.postId,
          waypoint.name, // Assuming 'name' is the post office name
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Waypoint added successfully.')),
        );
      } catch (e) {
        print('Error parsing QR code data: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to parse QR code: ${e.toString()}'),
          ),
        );
      }

      await Future.delayed(const Duration(seconds: 1));
      controller?.resumeCamera();
    });
  }

  Future<void> _updateFirebaseDeliveryStatus(
      String postId, String postOfficeName) async {
    try {
      await _firestoreService.updateDeliveryStatus(postId, postOfficeName);
    } catch (e) {
      // Error is already handled in FirestoreService
    }
  }

  void _addWaypointManually() {
    final TextEditingController addressController = TextEditingController();
    final TextEditingController latController = TextEditingController();
    final TextEditingController lngController = TextEditingController();
    final TextEditingController postIdController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Waypoint Manually'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: addressController,
                  decoration: const InputDecoration(labelText: 'Address'),
                ),
                TextField(
                  controller: latController,
                  decoration: const InputDecoration(labelText: 'Latitude'),
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                ),
                TextField(
                  controller: lngController,
                  decoration: const InputDecoration(labelText: 'Longitude'),
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
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
              child: const Text('Add'),
              onPressed: () async {
                if (addressController.text.isNotEmpty &&
                    latController.text.isNotEmpty &&
                    lngController.text.isNotEmpty &&
                    postIdController.text.isNotEmpty) {
                  String name = addressController.text.trim();
                  String coordinate =
                      '${latController.text.trim()},${lngController.text.trim()}';
                  String postId = postIdController.text.trim();

                  Waypoint waypoint = Waypoint(
                    name: name,
                    coordinate: coordinate,
                    postId: postId,
                  );

                  setState(() {
                    scannedWaypoints.add(waypoint);
                  });

                  try {
                    await _firestoreService.updateDeliveryStatus(postId, name);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Waypoint added successfully.')),
                    );
                  } catch (e) {
                    // Handle Firestore update error
                  }

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

  void _finishAddingWaypoints() {
    Navigator.pop(context, scannedWaypoints); // Return the list of waypoints
  }

  void _removeWaypoint(int index) {
    setState(() {
      scannedWaypoints.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Waypoints'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _finishAddingWaypoints,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: scannedWaypoints.isEmpty
                ? const Center(
                    child: Text(
                      'No Waypoints Added',
                      style:
                          TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                  )
                : WaypointList(
                    waypoints: scannedWaypoints,
                    onRemove: _removeWaypoint,
                  ),
          ),
          const SizedBox(height: 80), // Space for FABs
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FloatingActionButton.extended(
            heroTag: 'qrScan',
            onPressed: _startQRScan,
            icon: const Icon(Icons.qr_code_scanner),
            label: const Text('Scan QR'),
          ),
          const SizedBox(width: 16),
          FloatingActionButton.extended(
            heroTag: 'manualEntry',
            onPressed: _addWaypointManually,
            icon: const Icon(Icons.edit),
            label: const Text('Manual Entry'),
          ),
        ],
      ),
    );
  }
}
