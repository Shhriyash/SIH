import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String? _verificationId;

  static const String isLoggedInKey = 'isLoggedIn';

  // Email and Password Login
  Future<String?> loginWithEmail(String email, String password) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
          email: email, password: password);

      // Save login state
      await _saveLoginState(true);

      notifyListeners();
      return null; // Success
    } on FirebaseAuthException catch (e) {
      return e.message; // Return error message
    } catch (e) {
      return 'An unexpected error occurred';
    }
  }

  // Email and Password Registration
  Future<String?> registerWithEmail(String email, String password) async {
    try {
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);

      // Save login state
      await _saveLoginState(true);

      notifyListeners();
      return null; // Success
    } on FirebaseAuthException catch (e) {
      return e.message; // Return error message
    } catch (e) {
      return 'An unexpected error occurred';
    }
  }

  // Phone Login: Send OTP
  Future<String?> sendPhoneVerification(String phoneNumber) async {
    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) async {
          await _auth.signInWithCredential(credential);
          await _saveLoginState(true);
          notifyListeners(); // Notify listeners if login is completed automatically
        },
        verificationFailed: (FirebaseAuthException e) {
          // Handle verification failure
          // Consider logging or notifying the user
        },
        codeSent: (String verificationId, int? resendToken) {
          _verificationId = verificationId;
          notifyListeners(); // Notify listeners when OTP is sent
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          _verificationId = verificationId;
        },
        timeout: const Duration(seconds: 60),
      );
      return null; // Success
    } catch (e) {
      return e.toString(); // Return error message
    }
  }

  // Phone Login: Verify OTP
  Future<String?> verifyPhoneOTP(String otp) async {
    try {
      if (_verificationId == null) {
        return 'Verification ID not found. Please resend the OTP.';
      }
      final AuthCredential credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: otp,
      );
      await _auth.signInWithCredential(credential);

      // Save login state
      await _saveLoginState(true);

      notifyListeners(); // Notify listeners after successful login
      return null; // Success
    } catch (e) {
      return e.toString(); // Return error message
    }
  }

  // Sign Out
  Future<void> signOut() async {
    await _auth.signOut();
    await _saveLoginState(false);
    notifyListeners(); // Notify listeners after signing out
  }

  // Get Current User
  User? get currentUser => _auth.currentUser;

  // Save login state to SharedPreferences
  Future<void> _saveLoginState(bool isLoggedIn) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool(isLoggedInKey, isLoggedIn);
  }

  // Retrieve login state from SharedPreferences
  Future<bool> getLoginState() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(isLoggedInKey) ?? false;
  }
}
