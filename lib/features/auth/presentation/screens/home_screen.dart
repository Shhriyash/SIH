import 'package:dakmadad/features/auth/presentation/screens/login_screen.dart';
import 'package:dakmadad/features/camera/pages/edge_detection.dart';
import 'package:dakmadad/features/routeoptimization/optimized_route_page.dart';
import 'package:dakmadad/features/routeoptimization/waypoint_adder.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../domain/services/auth_service.dart';
import '../../../../main.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final themeNotifier = Provider.of<ThemeNotifier>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        actions: [
          // Theme toggle button
          IconButton(
            icon: Icon(themeNotifier.themeMode == ThemeMode.light
                ? Icons.dark_mode
                : Icons.light_mode),
            onPressed: () {
              themeNotifier.toggleTheme();
            },
          ),
          // Logout button
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await authService.signOut();
              if (context.mounted) {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                );
              }
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Welcome message
            Text('Welcome ${authService.currentUser?.phoneNumber ?? ""}'),
            const SizedBox(height: 20),

            // Sign out button
            ElevatedButton(
              onPressed: () async {
                await authService.signOut();
                if (context.mounted) {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (context) => const LoginScreen(),
                    ),
                  );
                }
              },
              child: const Text('Sign Out'),
            ),

            // Navigate to Edge Detection Page
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => EdgeDetectionPage()),
                );
              },
              child: const Text('Edge Detection'),
            ),

            // Navigate to Maps (Optimized Route Page)
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => OptimizedRoutePage()),
                );
              },
              child: const Text('Maps'),
            ),

            // Navigate to Waypoint Adder QR Page
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => WaypointAdderPage(
                      onWaypointsAdded: (waypoints) {
                        // Handle the added waypoints as needed
                        // You can store these waypoints or update a global state
                      },
                    ),
                  ),
                );
              },
              child: const Text('Waypoint Adder QR'),
            ),
          ],
        ),
      ),
    );
  }
}
