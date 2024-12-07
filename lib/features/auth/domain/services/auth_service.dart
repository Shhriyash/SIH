import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String? _verificationId;

  static const String isLoggedInKey = 'isLoggedIn';

  // Stream of authentication state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Get Current User
  User? get currentUser => _auth.currentUser;

  // Get User ID
  String? getCurrentUserId() {
    print('Fetching data for userId: ${_auth.currentUser?.uid}');
    return _auth.currentUser?.uid;
  }

  // Email and Password Login
  Future<String?> loginWithEmail(String email, String password) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

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
  Future<String?> registerWithEmail(String name, String email, String password) async {
    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Save user data to Firestore
      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'name': name,
        'email': email,
        // Add other fields as needed
      });

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
          // Automatically sign in with the received credential
          await _auth.signInWithCredential(credential);
          await _saveLoginState(true);
          notifyListeners();
        },
        verificationFailed: (FirebaseAuthException e) {
          // Handle verification failure
          // You can pass the error message to the UI via another method or a callback
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
      UserCredential userCredential = await _auth.signInWithCredential(credential);

      // Optionally, save user data to Firestore if needed
      // This depends on your app's requirements

      // Save login state
      await _saveLoginState(true);

      notifyListeners(); // Notify listeners after successful login
      return null; // Success
    } on FirebaseAuthException catch (e) {
      return e.message; // Return error message
    } catch (e) {
      return 'An unexpected error occurred';
    }
  }

  // Sign Out
  Future<void> signOut() async {
    await _auth.signOut();
    await _saveLoginState(false);
    notifyListeners(); // Notify listeners after signing out
  }

  // Fetch User Data
  Future<Map<String, dynamic>?> fetchUserData() async {
    try {
      if (_auth.currentUser == null) return null;
      DocumentSnapshot userDoc = await _firestore.collection('users').doc(_auth.currentUser!.uid).get();
      if (userDoc.exists) {
        return userDoc.data() as Map<String, dynamic>;
      } else {
        return null;
      }
    } catch (e) {
      print('Error fetching user data: $e');
      return null;
    }
  }

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
