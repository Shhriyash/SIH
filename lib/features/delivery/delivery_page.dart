// lib/features/home/delivery_page.dart

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dakmadad/features/home/check_status.dart';
import 'package:dakmadad/features/home/merged_pin_code.dart';
import 'package:dakmadad/features/routeoptimization/waypoint_adder.dart';
import 'package:dakmadad/l10n/generated/S.dart';
import 'package:dakmadad/features/routeoptimization/optimized_route_page.dart'; // Import the optimized route page
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:dakmadad/core/theme/app_colors.dart';
import 'package:dakmadad/features/camera/pages/edge_detection.dart';
import 'package:location/location.dart'; // Import location
import 'package:shared_preferences/shared_preferences.dart';

class DeliveryPage extends StatefulWidget {
  final Function(Locale locale) onLanguageChange;
  final Function(ThemeMode themeMode) onThemeChange;

  const DeliveryPage({
    super.key,
    required this.onLanguageChange,
    required this.onThemeChange,
  });

  @override
  State<DeliveryPage> createState() => _DeliveryPageState();
}

class _DeliveryPageState extends State<DeliveryPage> {
  String _postOfficeName = "Loading..."; // Default text while fetching
  bool isFetching = false;

  // Location related variables
  LocationData? _currentLocation;
  bool _isFetchingLocation = false;
  final Location _location = Location();
  // Removed location subscription since it's not needed without navigation
  // StreamSubscription<LocationData>? _locationSubscription;

  @override
  void initState() {
    super.initState();
    _fetchPostOfficeName();
    _fetchCurrentLocation();
  }

  @override
  void dispose() {
    // Removed location subscription disposal since it's not used
    // _locationSubscription?.cancel();
    super.dispose();
  }

  Future<void> _fetchPostOfficeName() async {
    setState(() {
      isFetching = true;
    });

    final prefs = await SharedPreferences.getInstance();
    final cachedPostOfficeName = prefs.getString('postOfficeName');

    // Use cached data if available
    if (cachedPostOfficeName != null) {
      setState(() {
        _postOfficeName = cachedPostOfficeName;
        isFetching = false;
      });
    }

    try {
      // Fetch post office name from Firestore
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) throw "User not logged in";

      final docSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (docSnapshot.exists) {
        final postOfficeName = docSnapshot.data()?['postOffice'] ?? "Unknown";

        // Update the cache and UI
        await prefs.setString('postOfficeName', postOfficeName);
        setState(() {
          _postOfficeName = postOfficeName;
          isFetching = false;
        });
      } else {
        setState(() {
          _postOfficeName = "No data found";
          isFetching = false;
        });
      }
    } catch (e) {
      // Handle errors
      setState(() {
        _postOfficeName = "Error fetching data";
        isFetching = false;
      });
    }
  }

  Future<void> _fetchCurrentLocation() async {
    setState(() {
      _isFetchingLocation = true;
    });

    bool serviceEnabled;
    PermissionStatus permissionGranted;

    // Check if location service is enabled
    serviceEnabled = await _location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await _location.requestService();
      if (!serviceEnabled) {
        // Handle the case where service is not enabled
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location services are disabled.')),
        );
        setState(() {
          _isFetchingLocation = false;
        });
        return;
      }
    }

    // Check for permissions
    permissionGranted = await _location.hasPermission();
    if (permissionGranted == PermissionStatus.denied ||
        permissionGranted == PermissionStatus.deniedForever) {
      permissionGranted = await _location.requestPermission();
      if (permissionGranted != PermissionStatus.granted) {
        // Handle the case where permission is not granted
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location permissions are denied.')),
        );
        setState(() {
          _isFetchingLocation = false;
        });
        return;
      }
    }

    // Get location data
    LocationData locationData = await _location.getLocation();
    setState(() {
      _currentLocation = locationData;
      _isFetchingLocation = false;
    });

    // Optionally, listen to location changes
    // _locationSubscription = _location.onLocationChanged.listen((newLocationData) {
    //   setState(() {
    //     _currentLocation = newLocationData;
    //   });
    // });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Removed AppBar
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 20), // Adjusted padding
          child: Column(
            children: [
              Container(
                decoration: const BoxDecoration(
                  color: AppColors.primaryRed,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(50),
                    bottomRight: Radius.circular(50),
                  ),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Delivery Section',
                      style: GoogleFonts.montserrat(
                        fontSize: 32, // Adjusted font size for better fit
                        fontWeight: FontWeight.w900,
                        color: Colors.yellow[100],
                      ),
                    ),
                    const SizedBox(height: 16),
                    InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const EdgeDetectionPage(),
                          ),
                        );
                      },
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              blurStyle: BlurStyle.inner,
                              color: Colors.black.withOpacity(0.5),
                              blurRadius: 5,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            SizedBox(
                              height: 80, // Adjusted height
                              width: 80, // Adjusted width
                              child: Lottie.asset(
                                'assets/jsons/document_scanning.json',
                                height: 80,
                                width: 80,
                                fit: BoxFit.fitWidth,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                S.of(context)!.scanParcel,
                                style: GoogleFonts.montserrat(
                                  fontSize: 20, // Adjusted font size
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFFB71C1C),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Search Field for Consignment
                    Container(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: S.of(context)!.enterConsignment,
                          filled: true,
                          fillColor: Colors.white,
                          prefixIcon:
                              const Icon(Icons.search, color: Colors.grey),
                          suffixIcon:
                              const Icon(Icons.qr_code, color: Colors.grey),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // Add delivery feature cards here
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  children: [
                    _buildCard(
                      icon: Icons.camera_alt,
                      title: 'Scan Article',
                      description: 'Scan the Article to generate QR',
                      onTap: () {
                        // Handle tap
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const EdgeDetectionPage(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 12), // Reduced spacing
                    _buildCard(
                      icon: Icons.location_on,
                      title: 'Merged Pincodes',
                      description: 'View and merge pincodes',
                      onTap: () {
                        // Handle tap
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const MergedPinCodesPage(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 12), // Reduced spacing
                    _buildCard(
                      icon: CupertinoIcons.check_mark_circled,
                      title: 'Check Status',
                      description: 'Check Status of a Article',
                      onTap: () {
                        // Handle tap
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const CheckStatusPage(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 12), // Reduced spacing
                    _buildCard(
                      icon: Icons.settings,
                      title: 'waypoint adder',
                      description: 'Adjust your preferences',
                      onTap: () {
                        // Handle tap
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const WaypointAdderPage()),
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    // New Card for Optimized Route
                    _buildCard(
                      icon: Icons.route,
                      title: 'Optimized Route',
                      description: 'View and manage optimized delivery routes',
                      onTap: () {
                        if (_currentLocation != null) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const OptimizedRoutePage(),
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content:
                                    Text('Current location is not available.')),
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
      // Removed FloatingNavBar and other navigation elements
    );
  }

  // Helper method to build a card
  Widget _buildCard({
    required IconData icon,
    required String title,
    required String description,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
          gradient: LinearGradient(
            colors: [Colors.yellow[100]!, Colors.yellow[100]!],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.all(20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.red[50],
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.4),
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(16),
              child: Icon(icon,
                  size: 32, color: AppColors.primaryRed), // Enlarged size
            ),
            const SizedBox(width: 16), // Improved spacing
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.montserrat(
                      fontSize: 18, // Enlarged font size
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryRed,
                    ),
                  ),
                  const SizedBox(height: 8), // Increased spacing
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 14, // Improved font size for better readability
                      color: Colors.black54,
                      fontWeight: FontWeight.w600,
                      height: 1.5, // Improved line height for clarity
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              color: AppColors.primaryRed,
              size: 20, // Slightly larger size for emphasis
            ),
          ],
        ),
      ),
    );
  }
}
