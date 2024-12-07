// lib/main.dart

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:edge_detection/edge_detection.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart'; // For MediaType
import 'package:path/path.dart' as Path;
import 'package:path_provider/path_provider.dart' as PathProvider;
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import 'settings_page.dart'; // Import the Settings Page

class EdgeDetectionPage extends StatefulWidget {
  const EdgeDetectionPage({super.key});

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

  final Uuid uuid = const Uuid();
  final TextEditingController _apiController = TextEditingController();
  final String _apiPrefKey = 'api_endpoint';

  @override
  void initState() {
    super.initState();
    _loadApiEndpoint();
  }

  @override
  void dispose() {
    _apiController.dispose();
    super.dispose();
  }

  // Load the API endpoint from SharedPreferences
  Future<void> _loadApiEndpoint() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _apiController.text = prefs.getString(_apiPrefKey) ??
          'https://d7fe-137-97-168-146.ngrok-free.app/upload'; // Update this to your static endpoint
    });
  }

  // Save the API endpoint to SharedPreferences
  Future<void> _saveApiEndpoint(String api) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_apiPrefKey, api);
  }

  // Navigate to the Settings Page
  Future<void> _navigateToSettings() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) =>
            SettingsPage(currentEndpoint: _apiController.text),
      ),
    );

    // Reload the API endpoint after returning from settings
    _loadApiEndpoint();
  }

  // Upload photos to the server
  Future<void> _uploadPhotos() async {
    setState(() {
      _isProcessing = true;
      _mapError = null;
    });

    // Ensure at least one image is selected
    if (_frontImagePath == null && _rearImagePath == null) {
      setState(() {
        _mapError = "No images selected for upload.";
        _isProcessing = false;
      });
      return;
    }

    String apiEndpoint = _apiController.text.trim();
    if (apiEndpoint.isEmpty) {
      setState(() {
        _mapError = "API endpoint is empty.";
        _isProcessing = false;
      });
      return;
    }

    var uri = Uri.parse(apiEndpoint);
    var request = http.MultipartRequest('POST', uri);

    try {
      // Add front image
      if (_frontImagePath != null) {
        File frontFile = File(_frontImagePath!);
        if (!await frontFile.exists()) {
          throw Exception("Front image file does not exist.");
        }

        var image1 = await http.MultipartFile.fromPath(
          'photo1', // Must match server's expected field name
          _frontImagePath!,
          contentType: MediaType('image', 'jpeg'),
        );
        request.files.add(image1);
        request.fields['id1'] = '1';
      }

      // Add rear image if capturing is enabled and rear image exists
      if (_captureRearImage && _rearImagePath != null) {
        File rearFile = File(_rearImagePath!);
        if (!await rearFile.exists()) {
          throw Exception("Rear image file does not exist.");
        }

        var image2 = await http.MultipartFile.fromPath(
          'photo2', // Must match server's expected field name
          _rearImagePath!,
          contentType: MediaType('image', 'jpeg'),
        );
        request.files.add(image2);
        request.fields['id2'] = '2';
      }

      // Debugging: Log request details
      print("Request files: ${request.files.map((f) => f.field)}");
      print("Request fields: ${request.fields}");

      var response = await request.send();

      if (response.statusCode == 200) {
        final responseData = await http.Response.fromStream(response);
        final responseJson = jsonDecode(responseData.body);
        print('Success: ${responseJson['message']}');

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Photos uploaded successfully!')),
        );
      } else {
        // Handle server error response
        final responseData = await http.Response.fromStream(response);
        print('Failed to upload photos. Response: ${responseData.body}');
        setState(() {
          _mapError = 'Failed to upload photos. Please try again.';
        });
      }
    } catch (e) {
      // Handle exceptions during the upload process
      print('Error uploading photos: $e');
      setState(() {
        _mapError = 'Error uploading photos: $e';
      });
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  // Process the captured image (Generate UUID and update UI)
  Future<void> processImage(String imagePath, String label) async {
    try {
      // Generate UUID for file name
      String imageUuid = uuid.v4();

      // Update UI with UUID and image path
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

  // Capture image from camera using Edge Detection
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
    String imagePath = Path.join(
      (await PathProvider.getTemporaryDirectory()).path,
      "${DateTime.now().millisecondsSinceEpoch}_$label.jpg",
    );

    try {
      bool success = await EdgeDetection.detectEdge(
        imagePath,
        canUseGallery: true,
        androidScanTitle: 'Scanning $label',
        androidCropTitle: 'Crop $label',
        androidCropBlackWhiteTitle: 'Black White $label',
        androidCropReset: 'Reset $label',
      );

      if (success) {
        await processImage(imagePath, label);
      } else {
        setState(() {
          _isProcessing = false;
          _mapError = "$label edge detection failed.";
        });
      }
    } catch (e) {
      setState(() {
        _isProcessing = false;
        _mapError = "Error during edge detection: $e";
      });
    }
  }

  // Build UI card to display captured images and UUIDs
  Widget buildImageCard(String label, String? imagePath, String? imageUuid) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 10),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "$label Image",
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            if (imageUuid != null)
              Text(
                "UUID: $imageUuid",
                style: const TextStyle(fontSize: 14, color: Colors.green),
              ),
            const SizedBox(height: 10),
            if (imagePath != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(
                  File(imagePath),
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
          ],
        ),
      ),
    );
  }

  // Build UI card to display errors
  Widget buildErrorCard(String errorMessage) {
    return Card(
      color: Colors.red[100],
      margin: const EdgeInsets.symmetric(vertical: 10),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.red),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                errorMessage,
                style: const TextStyle(fontSize: 16, color: Colors.red),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Build a generic action button
  Widget buildActionButton(
      String label, VoidCallback onPressed, IconData icon) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 24),
      label: Text(label, style: const TextStyle(fontSize: 16)),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // Build the API Endpoint Text Field (optional, since we're moving it to settings)
  // This can be removed if you prefer all endpoint configurations in settings
  /*
  Widget buildApiEndpointField() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'API Endpoint',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _apiController,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                hintText: 'Enter API endpoint URL',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.save),
                  onPressed: () {
                    String api = _apiController.text.trim();
                    if (api.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('API endpoint cannot be empty.')),
                      );
                      return;
                    }
                    _saveApiEndpoint(api);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('API endpoint saved.')),
                    );
                  },
                ),
              ),
              keyboardType: TextInputType.url,
              onSubmitted: (value) {
                String api = value.trim();
                if (api.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('API endpoint cannot be empty.')),
                  );
                  return;
                }
                _saveApiEndpoint(api);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('API endpoint saved.')),
                );
              },
            ),
            const SizedBox(height: 10),
            TextButton.icon(
              onPressed: _showApiInputDialog,
              icon: const Icon(Icons.link, size: 20),
              label: const Text(
                'Change API Endpoint',
                style: TextStyle(fontSize: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }
  */

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Determine if the upload button should be enabled
    bool isUploadEnabled = _frontImagePath != null &&
        (_rearImagePath != null || !_captureRearImage);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edge Detection'),
        centerTitle: true,
        backgroundColor: theme.primaryColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _navigateToSettings,
            tooltip: 'Change API Endpoint',
          ),
        ],
      ),
      body: Stack(
        children: [
          Container(
            color: theme.primaryColor.withOpacity(0.1),
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    // Optionally, remove this if you don't want the API field on the main page
                    // buildApiEndpointField(),
                    const SizedBox(height: 20),
                    // Toggle for capturing rear image
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      child: SwitchListTile(
                        title: const Text(
                          'Capture Rear Image',
                          style: TextStyle(fontSize: 16),
                        ),
                        value: _captureRearImage,
                        onChanged: (bool value) {
                          setState(() {
                            _captureRearImage = value;
                            _rearImagePath = null;
                            _rearUuid = null;
                          });
                        },
                        secondary: Icon(
                          _captureRearImage
                              ? Icons.camera_alt
                              : Icons.camera_alt_outlined,
                          color: theme.primaryColor,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Scan Front Object Button
                    buildActionButton(
                      'Scan Front Object',
                      _isProcessing ? () {} : () => getImageFromCamera('front'),
                      Icons.camera,
                    ),
                    const SizedBox(height: 20),
                    // Scan Rear Object Button (conditionally visible)
                    if (_captureRearImage)
                      buildActionButton(
                        'Scan Rear Object',
                        _isProcessing || _frontImagePath == null
                            ? () {}
                            : () => getImageFromCamera('rear'),
                        Icons.camera_rear,
                      ),
                    const SizedBox(height: 20),

                    // Display captured front image and UUID
                    if (_frontImagePath != null)
                      buildImageCard('Front', _frontImagePath, _frontUuid),
                    // Display captured rear image and UUID (if applicable)
                    if (_captureRearImage && _rearImagePath != null)
                      buildImageCard('Rear', _rearImagePath, _rearUuid),

                    // Upload Images Button
                    if (isUploadEnabled)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        child: buildActionButton(
                          'Upload Images',
                          _isProcessing ? () {} : _uploadPhotos,
                          Icons.cloud_upload,
                        ),
                      ),

                    // Display error messages
                    if (_mapError != null) buildErrorCard(_mapError!),
                  ],
                ),
              ),
            ),
          ),
          // Loading indicator overlay
          if (_isProcessing)
            Container(
              color: Colors.black54,
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }
}
