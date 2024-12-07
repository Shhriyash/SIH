import 'package:dakmadad/features/camera/pages/edge_detection.dart';
import 'package:dakmadad/features/routeoptimization/optimized_route_page.dart';
import 'package:dakmadad/features/routeoptimization/waypoint_adder.dart';
import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Use a Stack to layer the rounded background and the main content
      body: Stack(
        children: [
          // Background with rounded top edges
          Positioned(
            top: -10,
            left: 0,
            right: 0,
            child: Container(
              height: 300, // Adjust the height as needed
              decoration: const BoxDecoration(
                color: Color(0xFFB71C1C),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(50),
                  bottomRight: Radius.circular(50),
                ),
              ),
            ),
          ),
          // Scrollable content
          SafeArea(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // AppBar replacement with transparent background to blend with the Stack
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      children: [
                        // Profile Icon Button
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(1),
                            // Background color
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.person_2_outlined),
                            color: Colors.black,
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const PlaceholderScreen(title: 'Profile'),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Location Information
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Your Location',
                                style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.yellow,
                                    fontWeight: FontWeight.bold),
                              ),
                              Text(
                                'Sudama Nagar Post Office, Indore',
                                style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w100),
                              ),
                            ],
                          ),
                        ),
                        // Notifications Icon Button
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(1),
                            // Background color
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.notifications_none_outlined),
                            color: Colors.black,
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const PlaceholderScreen(
                                      title: 'Notification'),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Spacer to position the next section below the rounded background

                  const SizedBox(height: 30),
                  // Scan Container

                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 5,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.document_scanner, size: 24),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Scan your Post / Parcel & get QR generated.',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Search Field
                  Container(
                    margin: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 16),
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Enter a consignment no...',
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
                  // GridView for navigation options inside a Column
                  SizedBox(
                    height: 30,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      children: [
                        _buildGridItem(
                          context,
                          'Post Office',
                          'assets/post_office.png',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const PlaceholderScreen(
                                    title: 'Post Office'),
                              ),
                            );
                          },
                        ),
                        _buildGridItem(
                          context,
                          'Delivery Partner',
                          'assets/delivery_partner.png',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const PlaceholderScreen(
                                    title: 'Delivery Partner'),
                              ),
                            );
                          },
                        ),
                        _buildGridItem(
                          context,
                          'Track Parcel',
                          'assets/track_parcel.png',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const PlaceholderScreen(
                                    title: 'Track Parcel'),
                              ),
                            );
                          },
                        ),
                        _buildGridItem(
                          context,
                          'Support',
                          'assets/support.png',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const PlaceholderScreen(title: 'Support'),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  // Action Buttons
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Column(
                      children: [
                        ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const EdgeDetectionPage(),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size.fromHeight(50),
                            backgroundColor: const Color(0xFFB71C1C),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('Edge Detection'),
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const OptimizedRoutePage(),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size.fromHeight(50),
                            backgroundColor: const Color(0xFFB71C1C),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('Maps'),
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => WaypointAdderPage(),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size.fromHeight(50),
                            backgroundColor: const Color(0xFFB71C1C),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('Waypoint Adder QR'),
                        ),
                      ],
                    ),
                  ),
                  // Footer
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    color: const Color(0xFFB71C1C),
                    child: const Text(
                      'Powered by India Post\nDak Sewa - Jan Sewa',
                      style: TextStyle(color: Colors.white, fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper method to build grid items
  Widget _buildGridItem(BuildContext context, String title, String assetPath,
      {required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.yellow[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(assetPath, height: 50),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}

class PlaceholderScreen extends StatelessWidget {
  final String title;

  const PlaceholderScreen({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: const Color(0xFFB71C1C),
      ),
      body: Center(
        child: Text('This is the $title screen'),
      ),
    );
  }
}
