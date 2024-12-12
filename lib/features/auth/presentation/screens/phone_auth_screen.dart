import 'package:dakmadad/core/theme/app_colors.dart';
import 'package:dakmadad/features/auth/domain/services/auth_service.dart';
import 'package:dakmadad/features/home/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class PhoneAuthScreen extends StatefulWidget {
  final void Function(Locale locale) onLanguageChange;
  final void Function(ThemeMode mode) onThemeChange;

  const PhoneAuthScreen({
    super.key,
    required this.onLanguageChange,
    required this.onThemeChange,
  });

  @override
  State<PhoneAuthScreen> createState() => _PhoneAuthScreenState();
}

class _PhoneAuthScreenState extends State<PhoneAuthScreen> {
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController otpController = TextEditingController();
  bool isOTPFieldVisible = false; // Controls OTP field visibility
  bool isLoading = false; // Controls loading state

  @override
  void dispose() {
    phoneController.dispose();
    otpController.dispose();
    super.dispose();
  }

  /// Sends the OTP to the user's phone number.
  void _sendOTP(BuildContext context) async {
    final authService = Provider.of<AuthService>(context, listen: false);

    setState(() {
      isLoading = true;
    });

    final result =
        await authService.sendPhoneVerification(phoneController.text.trim());
    setState(() {
      isLoading = false;
    });

    if (result == null) {
      setState(() {
        isOTPFieldVisible = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('OTP sent successfully!')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result)),
      );
    }
  }

  /// Verifies the OTP entered by the user.
  void _verifyOTP(BuildContext context) async {
    final authService = Provider.of<AuthService>(context, listen: false);

    setState(() {
      isLoading = true;
    });

    final result = await authService.verifyPhoneOTP(otpController.text.trim());
    setState(() {
      isLoading = false;
    });

    if (result == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Login successful!')),
      );
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => HomeScreen(
            onThemeChange: widget.onThemeChange,
            onLanguageChange: widget.onLanguageChange,
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Header
              Text(
                isOTPFieldVisible ? "Enter OTP" : "Verify Your Phone",
                style: GoogleFonts.montserrat(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryRed,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                isOTPFieldVisible
                    ? "We sent a code to your phone"
                    : "Enter your phone number to receive an OTP",
                textAlign: TextAlign.center,
                style: GoogleFonts.montserrat(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 30),

              // Phone Number Field
              if (!isOTPFieldVisible)
                TextField(
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  style: GoogleFonts.montserrat(fontSize: 16),
                  decoration: InputDecoration(
                    labelText: "Phone Number",
                    hintText: "+1234567890",
                    labelStyle: GoogleFonts.montserrat(color: Colors.grey[600]),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade400),
                    ),
                    filled: true,
                    fillColor: Colors.grey[100],
                    prefixIcon:
                        const Icon(Icons.phone, color: AppColors.primaryRed),
                  ),
                ),

              // OTP Field
              if (isOTPFieldVisible)
                TextField(
                  controller: otpController,
                  keyboardType: TextInputType.number,
                  style: GoogleFonts.montserrat(fontSize: 16),
                  decoration: InputDecoration(
                    labelText: "Enter OTP",
                    hintText: "123456",
                    labelStyle: GoogleFonts.montserrat(color: Colors.grey[600]),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade400),
                    ),
                    filled: true,
                    fillColor: Colors.grey[100],
                    prefixIcon:
                        const Icon(Icons.lock, color: AppColors.primaryRed),
                  ),
                ),
              const SizedBox(height: 30),

              // Buttons
              if (isLoading)
                const CircularProgressIndicator()
              else
                ElevatedButton(
                  onPressed: () {
                    if (!isOTPFieldVisible) {
                      _sendOTP(context);
                    } else {
                      _verifyOTP(context);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                    backgroundColor: AppColors.primaryRed,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    isOTPFieldVisible ? "Verify OTP" : "Send OTP",
                    style: GoogleFonts.montserrat(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              const SizedBox(height: 20),

              // Resend OTP
              if (isOTPFieldVisible)
                TextButton(
                  onPressed: () => _sendOTP(context),
                  child: Text(
                    "Resend OTP",
                    style: GoogleFonts.montserrat(
                      fontSize: 16,
                      color: AppColors.primaryRed,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
