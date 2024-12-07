import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dakmadad/core/theme/app_colors.dart';
import 'package:dakmadad/features/auth/domain/services/auth_service.dart';
import 'package:dakmadad/features/home/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

class RegisterScreen extends StatefulWidget {
  final void Function(Locale locale) onLanguageChange;
  final void Function(ThemeMode mode) onThemeChange;

  const RegisterScreen({
    super.key,
    required this.onThemeChange,
    required this.onLanguageChange,
  });

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();
  final TextEditingController phoneNumberController = TextEditingController();
  final TextEditingController ageController = TextEditingController();
  final TextEditingController designationController = TextEditingController();
  final TextEditingController pinCodeController = TextEditingController();

  String? selectedPostOffice;
  List<String> postOffices = [];
  String? selectedGender;
  final List<String> genderOptions = ['Male', 'Female', 'Other'];

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool isLoading = false;

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    phoneNumberController.dispose();
    ageController.dispose();
    designationController.dispose();
    pinCodeController.dispose();
    super.dispose();
  }

  Future<void> fetchPostOffices(String pinCode) async {
    final url = Uri.parse(
        "http://www.postalpincode.in/api/pincode/$pinCode"); // API endpoint

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['Status'] == 'Success') {
          final offices = data['PostOffice'] as List<dynamic>;
          setState(() {
            postOffices =
                offices.map((office) => office['Name'] as String).toList();
            selectedPostOffice = null; // Reset selection when new data loads
          });
        } else {
          setState(() {
            postOffices = [];
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("No post offices found.")),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to fetch post offices.")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error fetching post offices.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),

              // Header
              Text(
                "Create Your Account",
                style: GoogleFonts.montserrat(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryRed,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                "Please fill in your details to get started.",
                style: GoogleFonts.montserrat(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // Full Name field
              _buildTextField(nameController, "Full Name", Icons.person),
              const SizedBox(height: 16),

              // Email field
              _buildTextField(emailController, "Email", Icons.email,
                  keyboardType: TextInputType.emailAddress),
              const SizedBox(height: 16),

              // Phone Number field
              _buildTextField(
                  phoneNumberController, "Phone Number", Icons.phone,
                  keyboardType: TextInputType.phone),
              const SizedBox(height: 16),

              // Age field
              _buildTextField(ageController, "Age", Icons.calendar_today,
                  keyboardType: TextInputType.number),
              const SizedBox(height: 16),

              // Designation field
              _buildTextField(designationController, "Designation", Icons.work),
              const SizedBox(height: 16),

              // Pin Code Field and Fetch Post Offices Button
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                        pinCodeController, "Pin Code", Icons.location_pin,
                        keyboardType: TextInputType.number),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      if (pinCodeController.text.isNotEmpty) {
                        fetchPostOffices(pinCodeController.text.trim());
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text("Enter a valid pin code.")),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryRed,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                    child: const Text("Fetch"),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Post Office Dropdown
              DropdownButtonFormField<String>(
                value: selectedPostOffice,
                decoration: InputDecoration(
                  labelText: "Post Office",
                  prefixIcon: const Icon(Icons.location_city,
                      color: AppColors.primaryRed),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                items: postOffices
                    .map((office) => DropdownMenuItem<String>(
                          value: office,
                          child: Text(office),
                        ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    selectedPostOffice = value;
                  });
                },
              ),
              const SizedBox(height: 16),

              // Gender Dropdown
              DropdownButtonFormField<String>(
                value: selectedGender,
                decoration: InputDecoration(
                  labelText: "Gender",
                  prefixIcon: const Icon(Icons.transgender,
                      color: AppColors.primaryRed),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                items: genderOptions
                    .map((gender) => DropdownMenuItem<String>(
                          value: gender,
                          child: Text(gender),
                        ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    selectedGender = value;
                  });
                },
              ),
              const SizedBox(height: 16),

              // Password field
              _buildPasswordField(passwordController, "Password"),
              const SizedBox(height: 16),

              // Confirm Password field
              _buildPasswordField(
                  confirmPasswordController, "Confirm Password"),
              const SizedBox(height: 32),

              // Register Button
              ElevatedButton(
                onPressed: () async {
                  if (_validateInputs()) {
                    await _registerUser(authService, context);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryRed,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: isLoading
                    ? const CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.0,
                      )
                    : const Text(
                        "Register",
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
              const SizedBox(height: 24),

              // Login Link
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Already have an Account? "),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: const Text(
                      "Login",
                      style: TextStyle(color: AppColors.primaryRed),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
      TextEditingController controller, String label, IconData icon,
      {TextInputType keyboardType = TextInputType.text}) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppColors.primaryRed),
        filled: true,
        fillColor: Colors.grey[100],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.primaryRed),
        ),
      ),
    );
  }

  Widget _buildPasswordField(TextEditingController controller, String label) {
    return TextField(
      controller: controller,
      obscureText:
          label == "Password" ? _obscurePassword : _obscureConfirmPassword,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.lock, color: AppColors.primaryRed),
        suffixIcon: IconButton(
          icon: Icon(
            (label == "Password" ? _obscurePassword : _obscureConfirmPassword)
                ? Icons.visibility_off
                : Icons.visibility,
            color: AppColors.primaryRed,
          ),
          onPressed: () {
            setState(() {
              if (label == "Password") {
                _obscurePassword = !_obscurePassword;
              } else {
                _obscureConfirmPassword = !_obscureConfirmPassword;
              }
            });
          },
        ),
        filled: true,
        fillColor: Colors.grey[100],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.primaryRed),
        ),
      ),
    );
  }

  bool _validateInputs() {
    if (nameController.text.isEmpty ||
        emailController.text.isEmpty ||
        phoneNumberController.text.isEmpty ||
        ageController.text.isEmpty ||
        designationController.text.isEmpty ||
        selectedPostOffice == null ||
        selectedGender == null ||
        passwordController.text != confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill in all fields correctly.")),
      );
      return false;
    }
    return true;
  }

  Future<void> _registerUser(
      AuthService authService, BuildContext context) async {
    setState(() {
      isLoading = true;
    });

    // Call registerWithEmail with the required arguments
    final message = await authService.registerWithEmail(
      nameController.text.trim(), // Pass the user's name
      emailController.text.trim(),
      passwordController.text.trim(),
    );

    if (message == null) {
      // Fetch the user ID from the current user
      final String? userId = authService.currentUser?.uid;

      if (userId != null) {
        try {
          // Save user data to Firebase Firestore with user ID as the document ID
          await FirebaseFirestore.instance.collection('users').doc(userId).set({
            'uid': userId, // Store the UID explicitly
            'name': nameController.text.trim(),
            'email': emailController.text.trim(),
            'phoneNumber': phoneNumberController.text.trim(),
            'age': int.tryParse(ageController.text.trim()) ?? 0,
            'designation': designationController.text.trim(),
            'postOffice': selectedPostOffice,
            'gender': selectedGender,
          });

          // Navigate to the HomeScreen
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => HomeScreen(
                onThemeChange: widget.onThemeChange,
                onLanguageChange: widget.onLanguageChange,
              ),
            ),
          );
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Failed to save user data: $e")),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to fetch user ID.")),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }

    setState(() {
      isLoading = false;
    });
  }
}
