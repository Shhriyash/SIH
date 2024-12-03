import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AuthService with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String? _verificationId;

  // Email and Password Login
  Future<String?> loginWithEmail(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      return null; // Success
    } catch (e) {
      return e.toString(); // Return error message
    }
  }

  // Email and Password Registration
  Future<String?> registerWithEmail(String email, String password) async {
    try {
      await _auth.createUserWithEmailAndPassword(
          email: email, password: password);
      return null; // Success
    } catch (e) {
      return e.toString(); // Return error message
    }
  }

  // Phone Login: Send OTP
  Future<String?> sendPhoneVerification(String phoneNumber) async {
    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) async {
          await _auth.signInWithCredential(credential);
          notifyListeners(); // Notify listeners if login is completed automatically
        },
        verificationFailed: (FirebaseAuthException e) {
          // Instead of returning, handle the error inside the callback
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
      notifyListeners(); // Notify listeners after successful login
      return null; // Success
    } catch (e) {
      return e.toString(); // Return error message
    }
  }

  // Sign Out
  Future<void> signOut() async {
    await _auth.signOut();
    notifyListeners(); // Notify listeners after signing out
  }

  // Get Current User
  User? get currentUser => _auth.currentUser;
}
