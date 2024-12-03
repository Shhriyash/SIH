// lib/features/routeoptimization/waypoint_adder_page.dart

import 'package:flutter/material.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'models/waypoint.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class WaypointAdderPage extends StatefulWidget {
  final Function(List<Waypoint>) onWaypointsAdded;

  const WaypointAdderPage({Key? key, required this.onWaypointsAdded})
      : super(key: key);

  @override
  _WaypointAdderPageState createState() => _WaypointAdderPageState();
}

class _WaypointAdderPageState extends State<WaypointAdderPage> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  QRViewController? controller;
  List<Waypoint> scannedWaypoints = [];
  bool isScanning = false; // Initially not scanning

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
    this.controller = qrController;
    controller?.scannedDataStream.listen((scanData) async {
      controller?.pauseCamera();
      String qrCodeData = scanData.code ?? '';
      // Assume qrCodeData contains a document ID for Firebase
      Waypoint? waypoint = await _getWaypointFromFirebase(qrCodeData);
      if (waypoint != null) {
        setState(() {
          scannedWaypoints.add(waypoint);
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Invalid QR code or waypoint not found.')),
        );
      }
      await Future.delayed(Duration(seconds: 1));
      controller?.resumeCamera();
    });
  }

  Future<Waypoint?> _getWaypointFromFirebase(String documentId) async {
    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('waypoints')
          .doc(documentId)
          .get();

      if (doc.exists) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        String name = data['name'];
        String coordinate = '${data['latitude']},${data['longitude']}';
        return Waypoint(name: name, coordinate: coordinate);
      } else {
        return null;
      }
    } catch (e) {
      print('Error fetching waypoint from Firebase: $e');
      return null;
    }
  }

  void _addWaypointManually() {
    final TextEditingController addressController = TextEditingController();
    final TextEditingController latController = TextEditingController();
    final TextEditingController lngController = TextEditingController();

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
              onPressed: () {
                if (addressController.text.isNotEmpty &&
                    latController.text.isNotEmpty &&
                    lngController.text.isNotEmpty) {
                  String name = addressController.text.trim();
                  String coordinate =
                      '${latController.text.trim()},${lngController.text.trim()}';
                  setState(() {
                    scannedWaypoints
                        .add(Waypoint(name: name, coordinate: coordinate));
                  });
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
    widget.onWaypointsAdded(scannedWaypoints);
    Navigator.pop(context);
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
        title: const Text('Add Mails'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _finishAddingWaypoints,
          ),
        ],
      ),
      body: Column(
        children: [
          if (scannedWaypoints.isEmpty)
            Expanded(
              child: Center(
                child: Text(
                  'Add Mails',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                itemCount: scannedWaypoints.length,
                itemBuilder: (context, index) {
                  final waypoint = scannedWaypoints[index];
                  var coordinates = waypoint.coordinate.split(',');
                  String latitude = coordinates[0];
                  String longitude = coordinates[1];
                  return ListTile(
                    title: Text(waypoint.name),
                    subtitle: Text('Lat: $latitude, Lng: $longitude'),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () => _removeWaypoint(index),
                    ),
                  );
                },
              ),
            ),
          SizedBox(height: 80), // To make space for the FABs
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
          SizedBox(width: 16),
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
