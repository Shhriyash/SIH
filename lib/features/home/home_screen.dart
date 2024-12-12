import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dakmadad/features/auth/presentation/screens/placeholder_screen.dart';
import 'package:dakmadad/features/auth/presentation/screens/register_screen.dart';
import 'package:dakmadad/features/delivery/delivery_page.dart';
import 'package:dakmadad/features/home/folating_nav_bar.dart';
import 'package:dakmadad/features/home/user_page.dart';
import 'package:dakmadad/features/voice_enabled/reciever_form.dart';
import 'package:dakmadad/features/voice_enabled/sender_form.dart';
import 'package:dakmadad/l10n/generated/S.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:dakmadad/core/theme/app_colors.dart';
import 'package:dakmadad/features/camera/pages/edge_detection.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_nav_bar/google_nav_bar.dart';

class HomeScreen extends StatefulWidget {
  final Function(Locale locale) onLanguageChange;
  final Function(ThemeMode themeMode) onThemeChange;

  const HomeScreen({
    super.key,
    required this.onLanguageChange,
    required this.onThemeChange,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _postOfficeName = ""; // Will be set after localization is available
  bool isFetching = false;
  int _selectedIndex = 0; // For navigation bar

  @override
  void initState() {
    super.initState();
    // Initialize _postOfficeName after the first frame to ensure context is available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        _postOfficeName = S.of(context)!.loading;
      });
      _fetchPostOfficeName();
    });
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
        final postOfficeName =
            docSnapshot.data()?['postOffice'] ?? S.of(context)!.unknown;

        // Update the cache and UI
        await prefs.setString('postOfficeName', postOfficeName);
        setState(() {
          _postOfficeName = postOfficeName;
          isFetching = false;
        });
      } else {
        setState(() {
          _postOfficeName = S.of(context)!.noDataFound;
          isFetching = false;
        });
      }
    } catch (e) {
      // Handle errors
      setState(() {
        _postOfficeName = S.of(context)!.errorFetchingData;
        isFetching = false;
      });
    }
  }

  void _onNavBarTap(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Define the pages for navigation
    List<Widget> pages = [
      _buildHomeContent(),
      DeliveryPage(
        onLanguageChange: widget.onLanguageChange,
        onThemeChange: widget.onThemeChange,
      )
    ];

    return Scaffold(
      extendBody: true, // Allows the body to extend behind the navigation bar
      appBar: AppBar(
        backgroundColor: AppColors.primaryRed,
        elevation: 0,
        leading: Container(
          height: 40,
          width: 40,
          margin: const EdgeInsets.only(left: 16),
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: const Icon(Icons.person_2_outlined, color: Colors.black),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => UsersPage(
                    onLanguageChange: widget.onLanguageChange,
                    onThemeChange: widget.onThemeChange,
                  ),
                ),
              );
            },
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              S.of(context)!.yourLocation,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.yellow,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '$_postOfficeName ${S.of(context)!.postOffice}',
              style: const TextStyle(
                fontSize: 12,
                color: Colors.white,
                fontWeight: FontWeight.w100,
              ),
            ),
          ],
        ),
        centerTitle: false,
        actions: [
          Container(
            height: 40,
            width: 40,
            margin: const EdgeInsets.only(right: 16),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.notifications_none_outlined,
                  color: Colors.black),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        PlaceholderScreen(title: S.of(context)!.support),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Using IndexedStack to preserve the state of each page
          IndexedStack(
            index: _selectedIndex,
            children: pages,
          ),
          // Reusable Positioned navigation bar
          FloatingNavBar(
            selectedIndex: _selectedIndex,
            onTabChange: _onNavBarTap,
            tabs: [
              GButton(
                icon: Icons.local_post_office_outlined,
                text: S.of(context)!.office, // Replaced with localized string
                iconSize: 15,
                textStyle: const TextStyle(
                  fontSize: 14,
                  color: Colors.amberAccent,
                ),
              ),
              GButton(
                icon: Icons.delivery_dining_outlined,
                text: S.of(context)!.delivery, // Replaced with localized string
                iconSize: 15,
                textStyle: const TextStyle(
                  fontSize: 14,
                  color: Colors.amberAccent,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Build the Home Content with four cards
  Widget _buildHomeContent() {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 100), // Padding to avoid overlap
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
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    S.of(context)!.officeSection,
                    style: GoogleFonts.montserrat(
                      fontSize: 48, // Reduced font size
                      fontWeight: FontWeight.w900,
                      color: Colors.yellow[100],
                    ),
                  ),
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
                            height: 100, // Reduced height
                            width: 200, // Reduced width
                            child: Lottie.asset(
                              'assets/jsons/document_scanning.json',
                              height: 100,
                              width: 100,
                              fit: BoxFit.fitWidth,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              S.of(context)!.scanParcel,
                              style: GoogleFonts.montserrat(
                                fontSize: 24, // Reduced font size
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFFB71C1C),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  //TODO: for the new page
                  /* Container(
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
                  ),*/
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Add four cards here
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                children: [
                  _buildCard(
                    icon: Icons.camera_alt,
                    title: S.of(context)!.scanArticle, // Localized title
                    description:
                        S.of(context)!.scanTheArticle, // Localized description
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
                    icon: CupertinoIcons.check_mark_circled,
                    title: S.of(context)!.checkStatus, // Localized title
                    description: S
                        .of(context)!
                        .checkStatusOfArticle, // Localized description
                    onTap: () {
                      // Handle tap
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ReceiverDetailsPage(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12), // Reduced spacing
                  _buildCard(
                    icon: Icons.settings,
                    title: S.of(context)!.settings, // Localized title
                    description: S
                        .of(context)!
                        .adjustYourPreferences, // Localized description
                    onTap: () {
                      // Handle tap
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => UsersPage(
                            onLanguageChange: widget.onLanguageChange,
                            onThemeChange: widget.onThemeChange,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
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
              ), // Enlarged size
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
