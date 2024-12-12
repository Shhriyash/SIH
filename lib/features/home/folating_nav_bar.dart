import 'package:flutter/material.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:dakmadad/core/theme/app_colors.dart';

class FloatingNavBar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onTabChange;
  final List<GButton> tabs;

  const FloatingNavBar({
    super.key,
    required this.selectedIndex,
    required this.onTabChange,
    required this.tabs,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 60, // Adjusted to make navbar narrower
      right: 60, // Adjusted to make navbar narrower
      bottom: 18,
      child: Container(
        height: 70, // Slimmer height
        // Removed 'width' property to avoid conflicts
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(50), // Rounded corners
          boxShadow: [
            BoxShadow(
              blurRadius: 10,
              color: Colors.black.withOpacity(0.2),
            )
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6.0),
          child: GNav(
            gap: 5, // Reduced gap between icon and text
            activeColor: Colors.white,
            color: Colors.black,
            iconSize: 24, // Adjusted icon size for better balance
            padding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 20,
            ), // Optimized padding
            duration: const Duration(
                milliseconds:
                    200), // Increased duration for smoother transitions
            tabBackgroundColor: AppColors.primaryRed,
            tabs: tabs,
            selectedIndex: selectedIndex,
            onTabChange: onTabChange,
          ),
        ),
      ),
    );
  }
}
