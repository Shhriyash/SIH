// lib/features/auth/presentation/screens/login_screen.dart

import 'package:dakmadad/core/theme/app_colors.dart';
import 'package:dakmadad/features/auth/domain/services/auth_service.dart';
import 'package:dakmadad/features/camera/pages/edge_detection.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'register_screen.dart';
import 'phone_auth_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Controllers for email and password fields
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  // State variable to toggle password visibility
  bool _obscurePassword = true;

  @override
  void dispose() {
    // Dispose controllers to free resources
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Access AuthService using Provider
    final authService = Provider.of<AuthService>(context, listen: false);

    return Scaffold(
      backgroundColor: AppColors.white, // Use predefined white color
      body: Column(
        children: [
          Container(
            height: 250,
            width: double.infinity,
            decoration: const BoxDecoration(color: AppColors.primaryRed),
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      SizedBox(
                        height: 100,
                      ),
                      Text(
                        "Welcome Back!",
                        style: TextStyle(
                          fontSize: 24,
                          color: Color(0xFFFFD700), // Gold color
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),

                      SizedBox(height: 8),

                      // Sign-in prompt text
                      Text(
                        "Sign into your Account",
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                          color: AppColors.white, // Primary red color
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              ],
            ),
          ),
          SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 32),

                // Email field
                TextField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    prefixIcon: const Icon(
                      Icons.email,
                      color: AppColors.primaryRed, // Icon color
                    ),
                    filled: true,
                    fillColor: AppColors.white,
                    border: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(8), // Circular borders
                      borderSide: const BorderSide(
                        color: AppColors.primaryRed,
                        width: 1.0,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(
                        color: AppColors.primaryRed,
                        width: 1.0,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(
                        color: AppColors.primaryRed,
                        width: 1.0,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Password field
                TextField(
                  controller: passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: const Icon(
                      Icons.lock,
                      color: AppColors.primaryRed, // Icon color
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                        color: AppColors.primaryRed, // Icon color
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                    filled: true,
                    fillColor: AppColors.white,
                    border: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(8), // Circular borders
                      borderSide: const BorderSide(
                        color: AppColors.primaryRed,
                        width: 1.0,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(
                        color: AppColors.primaryRed,
                        width: 1.0,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(
                        color: AppColors.primaryRed,
                        width: 1.0,
                      ),
                    ),
                  ),
                ),

                // Forgot Password link
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      // Handle forgot password action, e.g., navigate to ForgotPasswordScreen
                    },
                    child: const Text(
                      'Forgot Password?',
                      style: TextStyle(
                        color: Colors.red,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Login button
                ElevatedButton(
                  onPressed: () async {
                    // Show a loading indicator while processing
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (context) => const Center(
                        child: CircularProgressIndicator(),
                      ),
                    );

                    // Attempt to login
                    final message = await authService.loginWithEmail(
                      emailController.text.trim(),
                      passwordController.text.trim(),
                    );

                    // Hide the loading indicator
                    Navigator.of(context).pop();

                    if (message == null) {
                      // Navigate to HomeScreen on successful login
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const EdgeDetectionPage(),
                        ),
                      );
                    } else {
                      // Show error message
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(message)),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        AppColors.primaryRed, // Use predefined primary red
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(8), // Circular borders
                    ),
                  ),
                  child: const SizedBox(
                    width: double.infinity,
                    child: Center(
                      child: Text(
                        "Login",
                        style: TextStyle(
                          fontSize: 16,
                          color: AppColors.white, // Use predefined white color
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Or login with divider
                Row(
                  children: [
                    Expanded(
                        child: Divider(
                      color: Colors.grey[300],
                      thickness: 2,
                    )),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        "Or login with",
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ),
                    Expanded(
                        child: Divider(
                      color: Colors.grey[300],
                      thickness: 2,
                    )),
                  ],
                ),

                const SizedBox(height: 24),

                // Phone login button
                OutlinedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const PhoneAuthScreen(),
                      ),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    side: const BorderSide(color: Colors.grey),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(8), // Circular borders
                    ),
                  ),
                  child: const SizedBox(
                    width: double.infinity,
                    child: Center(
                      child: Text("Login with Phone"),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Register link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      "Don't have an Account? ",
                      style: TextStyle(color: Colors.grey),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const RegisterScreen(),
                          ),
                        );
                      },
                      child: const Text(
                        "Register",
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
