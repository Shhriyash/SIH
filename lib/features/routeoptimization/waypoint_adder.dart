// lib/pages/waypoint_adder.dart

import 'dart:async';
import 'package:dakmadad/features/routeoptimization/helpers/waypoint_provider.dart';
import 'package:dakmadad/features/routeoptimization/models/waypoint.dart';
import 'package:dakmadad/features/routeoptimization/services/qr_parser.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
  QRViewController? qrController;
  bool isScanning = false;

  @override
  void dispose() {
    qrController?.dispose();
    super.dispose();
  }

  /// Starts the QR scanning process.
  Future<void> startQRScan() async {
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
            onQRViewCreated: onQRViewCreated,
          ),
        ),
      ),
    );
    setState(() {
      isScanning = false;
    });
  }

  /// Handles the QR scanning result.
  void onQRViewCreated(QRViewController controller) {
    qrController = controller;
    qrController?.scannedDataStream.listen((scanData) async {
      qrController?.pauseCamera();
      String qrCodeData = scanData.code ?? '';

      try {
        // Parse QR code data to get a Waypoint
        Waypoint scannedWaypoint =
            await QRParser.parseQRCodeIsolate(qrCodeData);

        // Add waypoint via Provider
        await Provider.of<WaypointProvider>(context, listen: false)
            .addWaypoint(scannedWaypoint);

        // Fetch current user's UID
        // Assuming you are using FirebaseAuth:
        final currentUser = FirebaseAuth.instance.currentUser;

        if (currentUser == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('User not logged in.')),
          );
          Navigator.pop(context);
          return;
        }

        // Fetch user's post office name from user doc
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .get();

        if (!userDoc.exists) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('User document not found.')),
          );
          Navigator.pop(context);
          return;
        }

        final userData = userDoc.data()!;
        String postOfficeName = userData['postOffice'] ?? 'Unknown Post Office';

        // Now update Firestore's post_details with the new event
        final now = DateTime.now();
        final dateStr =
            '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
        final timeOfDay = TimeOfDay.fromDateTime(now);
        final timeStr = timeOfDay.format(context);

        await FirebaseFirestore.instance
            .collection('post_details')
            .doc(scannedWaypoint.postId)
            .update({
          'events': FieldValue.arrayUnion([
            {
              'date': dateStr,
              'location': postOfficeName,
              'status': 'In Transit',
              'time': timeStr,
            }
          ]),
          'updated_at': DateTime.now().toIso8601String()
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Waypoint added and event updated successfully.')),
        );

        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to process QR code: ${e.toString()}')),
        );
        qrController?.resumeCamera();
      }
    });
  }

  /// Opens a dialog to add a waypoint manually.
  Future<void> addWaypointManually() async {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController latController = TextEditingController();
    final TextEditingController lngController = TextEditingController();

    await showDialog(
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
                  if (!validateCoordinate(coordinate)) {
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
                  try {
                    await Provider.of<WaypointProvider>(context, listen: false)
                        .addWaypoint(waypoint);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Waypoint added successfully.')),
                    );
                    Navigator.pop(context);
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content:
                              Text('Failed to add waypoint: ${e.toString()}')),
                    );
                  }
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

  /// Validates the coordinate string.
  bool validateCoordinate(String coordinate) {
    List<String> parts = coordinate.split(',');
    if (parts.length != 2) return false;

    double? lat = double.tryParse(parts[0].trim());
    double? lng = double.tryParse(parts[1].trim());

    if (lat == null || lng == null) return false;
    if (lat < -90 || lat > 90) return false;
    if (lng < -180 || lng > 180) return false;

    return true;
  }

  /// Removes a waypoint after confirmation.
  Future<void> removeWaypoint(int index) async {
    Waypoint waypoint =
        Provider.of<WaypointProvider>(context, listen: false).waypoints[index];

    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Remove Waypoint'),
          content: const Text(
              'Are you sure you want to remove this waypoint from the list?'),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.pop(context, false),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              child: const Text('Remove'),
              onPressed: () => Navigator.pop(context, true),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      try {
        await Provider.of<WaypointProvider>(context, listen: false)
            .removeWaypoint(waypoint.postId);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Waypoint removed successfully.')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to remove waypoint: $e')),
        );
      }
    }
  }

  /// Marks a waypoint as delivered.
  Future<void> markAsDelivered(int index) async {
    Waypoint waypoint =
        Provider.of<WaypointProvider>(context, listen: false).waypoints[index];
    try {
      await Provider.of<WaypointProvider>(context, listen: false)
          .markAsDelivered(waypoint.postId);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Waypoint marked as delivered.')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to mark as delivered: $e')),
      );
    }
  }

  /// Opens a dialog to edit a waypoint.
  Future<void> showWaypointDialog({
    required Waypoint waypoint,
    required int index,
  }) async {
    final TextEditingController nameController =
        TextEditingController(text: waypoint.name);
    final TextEditingController coordinateController =
        TextEditingController(text: waypoint.coordinate);

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Waypoint'),
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
                  controller: coordinateController,
                  decoration: const InputDecoration(
                    labelText: 'Coordinate (lat,lng)',
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
              child: const Text('Save'),
              onPressed: () async {
                if (nameController.text.isNotEmpty &&
                    coordinateController.text.isNotEmpty) {
                  String name = nameController.text.trim();
                  String coordinate = coordinateController.text.trim();

                  if (!validateCoordinate(coordinate)) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text(
                              'Invalid coordinates. Please enter valid latitude and longitude.')),
                    );
                    return;
                  }

                  Waypoint updatedWaypoint = Waypoint(
                    name: name,
                    coordinate: coordinate,
                    postId: waypoint.postId,
                    isDelivered: waypoint.isDelivered,
                  );

                  // Update via Provider
                  try {
                    await Provider.of<WaypointProvider>(context, listen: false)
                        .updateWaypoint(updatedWaypoint);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Waypoint updated successfully.')),
                    );
                    Navigator.pop(context);
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text(
                              'Failed to update waypoint: ${e.toString()}')),
                    );
                  }
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
              // Navigate back or perform any necessary action
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

                // Split waypoints into delivered, current, and remaining
                List<Waypoint> deliveredWaypoints = waypointProvider.waypoints
                    .where((w) => w.isDelivered)
                    .toList();

                List<Waypoint> remainingWaypoints = waypointProvider.waypoints
                    .where((w) => !w.isDelivered)
                    .toList();

                Waypoint? currentDelivery = remainingWaypoints.isNotEmpty
                    ? remainingWaypoints.first
                    : null;

                List<Waypoint> otherRemaining = remainingWaypoints.length > 1
                    ? remainingWaypoints.sublist(1)
                    : [];

                return SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Current Delivery Section
                        if (currentDelivery != null) ...[
                          const Text(
                            'Current Delivery',
                            style: TextStyle(
                                fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 4, vertical: 2),
                            child: Card(
                              color: Colors.orange.shade50,
                              elevation: 4,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: ListTile(
                                leading: const Icon(
                                  Icons.local_shipping,
                                  color: Colors.orange,
                                  size: 40,
                                ),
                                title: Text(
                                  currentDelivery.name,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18),
                                ),
                                subtitle: Text(
                                    'Lat: ${currentDelivery.coordinate.split(',')[0]}, Lng: ${currentDelivery.coordinate.split(',')[1]}\nPost ID: ${currentDelivery.postId}'),
                                isThreeLine: true,
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit,
                                          color: Colors.blue),
                                      onPressed: () => showWaypointDialog(
                                        waypoint: currentDelivery,
                                        index: waypointProvider.waypoints
                                            .indexOf(currentDelivery),
                                      ),
                                      tooltip: 'Edit',
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete,
                                          color: Colors.red),
                                      onPressed: () => removeWaypoint(
                                        waypointProvider.waypoints
                                            .indexOf(currentDelivery),
                                      ),
                                      tooltip: 'Delete',
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Remaining Deliveries Section
                        if (otherRemaining.isNotEmpty) ...[
                          const Text(
                            'Remaining Deliveries',
                            style: TextStyle(
                                fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          ListView.builder(
                            physics: const NeverScrollableScrollPhysics(),
                            shrinkWrap: true,
                            itemCount: otherRemaining.length,
                            itemBuilder: (context, index) {
                              final waypoint = otherRemaining[index];
                              var coordinates = waypoint.coordinate.split(',');
                              String latitude = coordinates[0];
                              String longitude = coordinates[1];
                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 4, vertical: 2),
                                child: Card(
                                  color: Colors.blue.shade50,
                                  elevation: 2,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: ListTile(
                                    leading: const Icon(
                                      Icons.delivery_dining,
                                      color: Colors.blue,
                                    ),
                                    title: Text(
                                      waypoint.name,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold),
                                    ),
                                    subtitle: Text(
                                        'Lat: $latitude, Lng: $longitude\nPost ID: ${waypoint.postId}'),
                                    isThreeLine: true,
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.edit,
                                              color: Colors.blue),
                                          onPressed: () => showWaypointDialog(
                                            waypoint: waypoint,
                                            index: waypointProvider.waypoints
                                                .indexOf(waypoint),
                                          ),
                                          tooltip: 'Edit',
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.delete,
                                              color: Colors.red),
                                          onPressed: () => removeWaypoint(
                                            waypointProvider.waypoints
                                                .indexOf(waypoint),
                                          ),
                                          tooltip: 'Delete',
                                        ),
                                        IconButton(
                                          icon: Icon(
                                            waypoint.isDelivered
                                                ? Icons.check_circle
                                                : Icons.check_circle_outline,
                                            color: waypoint.isDelivered
                                                ? Colors.green
                                                : Colors.grey,
                                          ),
                                          onPressed: waypoint.isDelivered
                                              ? null
                                              : () => markAsDelivered(
                                                  waypointProvider.waypoints
                                                      .indexOf(waypoint)),
                                          tooltip: waypoint.isDelivered
                                              ? 'Delivered'
                                              : 'Mark as Delivered',
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Delivered Section
                        if (deliveredWaypoints.isNotEmpty) ...[
                          const Text(
                            'Delivered',
                            style: TextStyle(
                                fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          ListView.builder(
                            physics: const NeverScrollableScrollPhysics(),
                            shrinkWrap: true,
                            itemCount: deliveredWaypoints.length,
                            itemBuilder: (context, index) {
                              final waypoint = deliveredWaypoints[index];
                              var coordinates = waypoint.coordinate.split(',');
                              String latitude = coordinates[0];
                              String longitude = coordinates[1];
                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 4, vertical: 2),
                                child: Card(
                                  color: Colors.green.shade50,
                                  elevation: 2,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: ListTile(
                                    leading: const Icon(
                                      Icons.check_circle,
                                      color: Colors.green,
                                    ),
                                    title: Text(
                                      waypoint.name,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold),
                                    ),
                                    subtitle: Text(
                                        'Lat: $latitude, Lng: $longitude\nPost ID: ${waypoint.postId}'),
                                    isThreeLine: true,
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.edit,
                                              color: Colors.blue),
                                          onPressed: () => showWaypointDialog(
                                            waypoint: waypoint,
                                            index: waypointProvider.waypoints
                                                .indexOf(waypoint),
                                          ),
                                          tooltip: 'Edit',
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.delete,
                                              color: Colors.red),
                                          onPressed: () => removeWaypoint(
                                            waypointProvider.waypoints
                                                .indexOf(waypoint),
                                          ),
                                          tooltip: 'Delete',
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 16),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const Divider(),
          // Add Waypoints Section (if any)
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.extended(
            heroTag: 'qrScan',
            onPressed: isScanning ? null : startQRScan,
            icon: const Icon(Icons.qr_code_scanner),
            label: const Text('Scan QR'),
            tooltip: 'Scan QR Code',
          ),
          const SizedBox(height: 16),
          FloatingActionButton.extended(
            heroTag: 'manualEntry',
            onPressed: addWaypointManually,
            icon: const Icon(Icons.edit),
            label: const Text('Manual Entry'),
            tooltip: 'Add Waypoint Manually',
          ),
        ],
      ),
    );
  }
}
