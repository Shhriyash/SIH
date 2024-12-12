// lib/features/home/delivery_page.dart

import 'dart:async';
import 'package:dakmadad/features/routeoptimization/waypoint_adder.dart';
import 'package:dakmadad/features/routeoptimization/optimized_route_page.dart';
import 'package:dakmadad/features/voice_enabled/reciever_form.dart';
import 'package:dakmadad/l10n/generated/S.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:dakmadad/core/theme/app_colors.dart';
import 'package:location/location.dart';

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
  final String _postOfficeName = "Loading...";
  bool isFetching = false;

  // Location related variables
  LocationData? _currentLocation;
  bool _isFetchingLocation = false;
  final Location _location = Location();

  @override
  void initState() {
    super.initState();
    _fetchCurrentLocation();
  }

  @override
  void dispose() {
    super.dispose();
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(S.of(context)!.errorFetchingData)),
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(S.of(context)!.errorFetchingData)),
        );
        setState(() {
          _isFetchingLocation = false;
        });
        return;
      }
    }

    LocationData locationData = await _location.getLocation();
    setState(() {
      _currentLocation = locationData;
      _isFetchingLocation = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 20),
          child: Column(
            children: [
              Container(
                decoration: const BoxDecoration(
                  color: AppColors.primaryRed,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(32),
                    bottomRight: Radius.circular(32),
                  ),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      S.of(context)!.deliverySection,
                      style: GoogleFonts.montserrat(
                        fontSize: 44,
                        fontWeight: FontWeight.w900,
                        color: Colors.yellow[100],
                      ),
                    ),
                    InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const WaypointAdderPage(),
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
                              height: 120,
                              width: 150,
                              child: LottieBuilder.asset(
                                'assets/jsons/delivery_animation.json',
                                fit: BoxFit.cover,
                                repeat: true,
                                onLoaded: (composition) {
                                  print(
                                      'Animation loaded with ${composition.duration}');
                                },
                                errorBuilder: (context, error, stackTrace) {
                                  return Center(
                                      child: Text(
                                          S.of(context)!.errorFetchingData));
                                },
                              ),
                            ),
                            const SizedBox(width: 24),
                            Expanded(
                              child: Text(
                                S.of(context)!.qrScanToUpdate,
                                style: GoogleFonts.montserrat(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFFB71C1C),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  children: [
                    _buildCard(
                      icon: Icons.settings,
                      title: S.of(context)!.waypointAdder,
                      description: S.of(context)!.adjustYourDeliveryPreferences,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const WaypointAdderPage()),
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    _buildCard(
                      icon: Icons.route,
                      title: S.of(context)!.optimisedRoute,
                      // Since there's no suitable description in ARB for the second card,
                      // we will omit the description entirely.
                      description: '',
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
                            SnackBar(content: Text(S.of(context)!.unknown)),
                          );
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    _buildCard(
                      icon: CupertinoIcons.check_mark_circled,
                      title: S.of(context)!.checkStatus,
                      description: S.of(context)!.checkStatusOfArticle,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ReceiverDetailsPage(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

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
                color: Colors.white10,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.red.withOpacity(0.3),
                    blurRadius: 1,
                    offset: const Offset(0, 0),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(16),
              child: Icon(
                icon,
                size: 32,
                color: AppColors.primaryRed,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.montserrat(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryRed,
                    ),
                  ),
                  if (description.isNotEmpty) const SizedBox(height: 8),
                  if (description.isNotEmpty)
                    Text(
                      description,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black54,
                        fontWeight: FontWeight.w600,
                        height: 1.5,
                      ),
                    ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              color: AppColors.primaryRed,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
