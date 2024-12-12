import 'package:dakmadad/features/home/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'package:dakmadad/features/auth/presentation/screens/start_screen.dart';
import '../../domain/services/auth_service.dart';

class SplashScreen extends StatefulWidget {
  final void Function(Locale locale) onLanguageChange;
  final void Function(ThemeMode themeMode) onThemeChange;

  const SplashScreen({
    super.key,
    required this.onLanguageChange,
    required this.onThemeChange,
  });

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  late AuthService _authService;

  @override
  void initState() {
    super.initState();
    _authService = Provider.of<AuthService>(context, listen: false);
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    bool isLoggedIn = await _authService.getLoginState();
    if (isLoggedIn && _authService.currentUser != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => HomeScreen(
            onLanguageChange: widget.onLanguageChange,
            onThemeChange: widget.onThemeChange,
          ),
        ),
      );
    } else {
      // Navigate to StartScreen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => StartScreen(
            onLanguageChange: widget.onLanguageChange,
            onThemeChange: widget.onThemeChange,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(child: Lottie.asset('assets/jsons/delivery_animation.json')),
    );
  }
}
