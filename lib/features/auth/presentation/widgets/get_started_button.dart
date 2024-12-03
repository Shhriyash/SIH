import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class GetStartedButton extends StatelessWidget {
  final VoidCallback onPressed;

  const GetStartedButton({
    super.key,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {

    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primaryRed, AppColors.primaryRed],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "Get started",
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Colors.white),
            ),
            const SizedBox(width: 8),
            _buildForwardArrowIcon(),
          ],
        ),
      ),
    );
  }

  Widget _buildForwardArrowIcon() {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: AppColors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Center(
        child: Icon(
          Icons.arrow_forward,
          color: AppColors.white,
          size: 16,
        ),
      ),
    );
  }
}
