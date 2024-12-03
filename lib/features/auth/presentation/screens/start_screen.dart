import 'package:dakmadad/features/auth/presentation/screens/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../widgets/custom_divider.dart';
import '../widgets/get_started_button.dart';

class StartScreen extends StatelessWidget {
  const StartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(60.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),
              Text(
                "Welcome to\nDak Madad",
                style: textTheme.displayLarge,
              ),
              const SizedBox(height: 20),
              Center(
                child: SvgPicture.asset(
                  'assets/svg/delivery-person-holding-package.svg',
                  height: 300,
                  width: 200,
                  fit: BoxFit.contain,
                ),
                // Alternatively, use SVG
                // child: SvgPicture.asset(
                //   'assets/icons/delivery.svg',
                //   height: size.height * 0.15,
                // ),
              ),
              const SizedBox(height: 24),
              Center(
                child: Column(
                  children: [
                    Text(
                      "Powered by India Post",
                      style: textTheme.bodyLarge,
                    ),
                    Text(
                      "Dak Sewa - Jan Sewa",
                      style: textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              const Spacer(),
              GetStartedButton(onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const LoginScreen(),
                  ),
                );
              }),
              const SizedBox(height: 24),
              const SizedBox(height: 60),
              const CustomDivider(),
            ],
          ),
        ),
      ),
    );
  }
}
