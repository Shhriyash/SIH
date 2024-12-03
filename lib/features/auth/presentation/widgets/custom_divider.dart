import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class CustomDivider extends StatelessWidget {
  const CustomDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.primaryRed,
        borderRadius: BorderRadius.circular(10),
      ),
      height: 6,
      width: double.infinity,
    );
  }
}
