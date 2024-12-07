// lib/features/routeoptimization/waypoint_adder_page.dart

import 'package:dakmadad/features/routeoptimization/helpers/waypoint_provider.dart';
import 'package:dakmadad/features/routeoptimization/models/waypoint.dart';
import 'package:dakmadad/features/routeoptimization/services/qr_parser.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class WaypointAdderPage extends StatefulWidget {
  const WaypointAdderPage({super.key});

  @override
  _WaypointAdderPageState createState() => _WaypointAdderPageState();
}

class _WaypointAdderPageState extends State<WaypointAdderPage> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  QRViewController? controller;
  bool isScanning = false;

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  void _startQRScan() async {
    setState(() {
      isScanning = true;
    });
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: const Text('Scan QR Code'),
          ),
          body: QRView(
            key: qrKey,
            onQRViewCreated: _onQRViewCreated,
          ),
        ),
      ),
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

      try {
        // Parse QR code data using the custom QRParser
        Waypoint waypoint = await QRParser.parseQRCodeIsolate(qrCodeData);

        // Generate a unique postId using Firestore auto ID
        DocumentReference docRef =
            FirebaseFirestore.instance.collection('post_details').doc();
        Waypoint newWaypoint = Waypoint(
          name: waypoint.name,
          coordinate: waypoint.coordinate,
          postId: docRef.id,
        );

        // Add to Provider
        await Provider.of<WaypointProvider>(context, listen: false)
            .addWaypoint(newWaypoint);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Waypoint added successfully.')),
        );

        Navigator.pop(context);
      } catch (e) {
        print('Error parsing QR code data: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to parse QR code: ${e.toString()}'),
          ),
        );
        controller?.resumeCamera();
      }
    });
  }

  void _addWaypointManually() {
    final TextEditingController nameController = TextEditingController();
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
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Name',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: latController,
                  decoration: const InputDecoration(
                    labelText: 'Latitude',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: lngController,
                  decoration: const InputDecoration(
                    labelText: 'Longitude',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.pop(context),
            ),
            ElevatedButton(
              child: const Text('Add'),
              onPressed: () async {
                if (nameController.text.isNotEmpty &&
                    latController.text.isNotEmpty &&
                    lngController.text.isNotEmpty) {
                  String name = nameController.text.trim();
                  String coordinate =
                      '${latController.text.trim()},${lngController.text.trim()}';

                  // Validate coordinates
                  List<String> parts = coordinate.split(',');
                  if (parts.length != 2 ||
                      double.tryParse(parts[0]) == null ||
                      double.tryParse(parts[1]) == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text(
                              'Invalid coordinates. Please enter valid latitude and longitude.')),
                    );
                    return;
                  }

                  // Generate a unique postId using Firestore auto ID
                  DocumentReference docRef = FirebaseFirestore.instance
                      .collection('post_details')
                      .doc();
                  Waypoint waypoint = Waypoint(
                    name: name,
                    coordinate: coordinate,
                    postId: docRef.id,
                  );

                  // Add to Provider
                  await Provider.of<WaypointProvider>(context, listen: false)
                      .addWaypoint(waypoint);

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Waypoint added successfully.')),
                  );

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Waypoints'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            tooltip: 'Finish',
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Existing Waypoints List
          Expanded(
            flex: 2,
            child: Consumer<WaypointProvider>(
              builder: (context, waypointProvider, child) {
                if (waypointProvider.waypoints.isEmpty) {
                  return const Center(
                    child: Text(
                      'No waypoints added.',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: waypointProvider.waypoints.length,
                  itemBuilder: (context, index) {
                    final waypoint = waypointProvider.waypoints[index];
                    var coordinates = waypoint.coordinate.split(',');
                    String latitude = coordinates[0];
                    String longitude = coordinates[1];
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      child: Card(
                        elevation: 3,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Theme.of(context).primaryColor,
                            child: Text(
                              '${index + 1}',
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                          title: Text(waypoint.name),
                          subtitle: Text('Lat: $latitude, Lng: $longitude'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Edit Button
                              IconButton(
                                icon: const Icon(Icons.edit),
                                color: Theme.of(context).primaryColor,
                                onPressed: () {
                                  // Navigate to Edit Functionality
                                  // Alternatively, trigger a callback or function
                                  // depending on your implementation
                                },
                              ),
                              // Delete Button
                              IconButton(
                                icon: const Icon(Icons.delete),
                                color: Colors.red,
                                onPressed: () {
                                  // Navigate to Delete Functionality
                                  // Alternatively, trigger a callback or function
                                  // depending on your implementation
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          const Divider(),
          // Add Waypoints Section
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.extended(
            heroTag: 'qrScan',
            onPressed: isScanning ? null : _startQRScan,
            icon: const Icon(Icons.qr_code_scanner),
            label: const Text('Scan QR'),
            tooltip: 'Scan QR Code',
          ),
          const SizedBox(height: 16),
          FloatingActionButton.extended(
            heroTag: 'manualEntry',
            onPressed: _addWaypointManually,
            icon: const Icon(Icons.edit),
            label: const Text('Manual Entry'),
            tooltip: 'Add Waypoint Manually',
          ),
        ],
      ),
    );
  }
}
