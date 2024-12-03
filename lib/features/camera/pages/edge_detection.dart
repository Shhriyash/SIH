import 'dart:async';
import 'dart:io';
import 'package:edge_detection/edge_detection.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:uuid/uuid.dart';
import 'supabase_helper.dart'; // Import the Supabase helper class

class EdgeDetectionPage extends StatefulWidget {
  const EdgeDetectionPage({Key? key}) : super(key: key);

  @override
  _EdgeDetectionPageState createState() => _EdgeDetectionPageState();
}

class _EdgeDetectionPageState extends State<EdgeDetectionPage> {
  String? _frontImagePath;
  String? _rearImagePath;
  String? _frontUuid;
  String? _rearUuid;
  String? _mapError;
  bool _isProcessing = false;
  bool _captureRearImage = false;

  final Uuid uuid = Uuid();
  final SupabaseHelper supabaseHelper =
      SupabaseHelper(); // Initialize Supabase helper

  Future<void> processImage(String imagePath, String label) async {
    setState(() {
      _isProcessing = true;
      _mapError = null;
    });

    try {
      // Generate UUID for file name
      String imageUuid = uuid.v4();
      String fileName = "$imageUuid.jpeg";

      // Upload to Supabase
      await supabaseHelper.uploadImage(imagePath, fileName);

      // Update UI with UUID
      setState(() {
        if (label == 'front') {
          _frontImagePath = imagePath;
          _frontUuid = imageUuid;
        } else {
          _rearImagePath = imagePath;
          _rearUuid = imageUuid;
        }
        _isProcessing = false;
      });
    } catch (e) {
      setState(() {
        _isProcessing = false;
        _mapError = "Error processing $label image: $e";
      });
    }
  }

  Future<void> getImageFromCamera(String label) async {
    setState(() {
      _isProcessing = true;
      _mapError = null;
    });

    // Request camera permission
    PermissionStatus cameraStatus = await Permission.camera.status;
    if (!cameraStatus.isGranted) {
      cameraStatus = await Permission.camera.request();
      if (!cameraStatus.isGranted) {
        setState(() {
          _isProcessing = false;
          _mapError = "Camera permission is required to scan objects.";
        });
        return;
      }
    }

    // Generate file path
    String imagePath = join(
      (await getApplicationSupportDirectory()).path,
      "${(DateTime.now().millisecondsSinceEpoch / 1000).round()}_${label}.jpeg",
    );

    bool success = false;
    try {
      success = await EdgeDetection.detectEdge(
        imagePath,
        canUseGallery: true,
        androidScanTitle: 'Scanning $label',
        androidCropTitle: 'Crop $label',
        androidCropBlackWhiteTitle: 'Black White $label',
        androidCropReset: 'Reset $label',
      );
    } catch (e) {
      setState(() {
        _mapError = "Error detecting $label edge: $e";
        _isProcessing = false;
      });
      return;
    }

    if (success) {
      await processImage(imagePath, label);
    } else {
      setState(() {
        _isProcessing = false;
        _mapError = "$label edge detection failed.";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edge Detection with Supabase'),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // Toggle for capturing rear image
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Capture Rear Image',
                          style: TextStyle(fontSize: 16)),
                      Switch(
                        value: _captureRearImage,
                        onChanged: (bool value) {
                          setState(() {
                            _captureRearImage = value;
                            _rearImagePath = null;
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _isProcessing
                        ? null
                        : () => getImageFromCamera('front'),
                    child: const Text('Scan Front Object'),
                  ),
                  const SizedBox(height: 20),
                  if (_captureRearImage)
                    ElevatedButton(
                      onPressed: _isProcessing || _frontImagePath == null
                          ? null
                          : () => getImageFromCamera('rear'),
                      child: const Text('Scan Rear Object'),
                    ),
                  const SizedBox(height: 20),

                  // Display UUID and image for front
                  if (_frontImagePath != null) ...[
                    const Text(
                      "Front Image UUID:",
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      _frontUuid ?? 'No UUID generated',
                      style: const TextStyle(fontSize: 14, color: Colors.green),
                    ),
                    const SizedBox(height: 10),
                    Image.file(
                      File(_frontImagePath!),
                      height: 200,
                    ),
                  ],

                  // Display UUID and image for rear if applicable
                  if (_captureRearImage && _rearImagePath != null) ...[
                    const SizedBox(height: 20),
                    const Text(
                      "Rear Image UUID:",
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      _rearUuid ?? 'No UUID generated',
                      style: const TextStyle(fontSize: 14, color: Colors.green),
                    ),
                    const SizedBox(height: 10),
                    Image.file(
                      File(_rearImagePath!),
                      height: 200,
                    ),
                  ],

                  // Display errors
                  if (_mapError != null) ...[
                    const SizedBox(height: 20),
                    Text(
                      _mapError!,
                      style: const TextStyle(fontSize: 16, color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (_isProcessing)
            Container(
              color: Colors.black54,
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }
}
