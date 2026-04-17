import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  AuthService() {
    // Force reCAPTCHA verification instead of Google Play Services
    _auth.setSettings(appVerificationDisabledForTesting: true);
  }

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<UserModel?> signIn(String email, String password) async {
    UserCredential credential = await _auth.signInWithEmailAndPassword(email: email, password: password);
    if (credential.user == null) return null;
    try {
      DocumentSnapshot doc = await _firestore.collection('users').doc(credential.user!.uid).get();
      if (doc.exists) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isLoggedIn', true);
        return UserModel.fromMap(doc.data() as Map<String, dynamic>);
      }
    } catch (e) {
      debugPrint('Firestore read failed: $e');
    }
    // Firestore failed but auth succeeded — return minimal user so router can redirect
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', true);
    return UserModel(
      uid: credential.user!.uid,
      name: '',
      email: email,
      role: 'student',
      roomNumber: '',
      hostelBlock: '',
      phone: '',
      createdAt: DateTime.now(),
    );
  }

  Future<UserModel?> register(String name, String email, String password, String role, String room, String block, String phone) async {
    // Check if auth user already exists by trying to fetch sign-in methods
    try {
      final methods = await _auth.fetchSignInMethodsForEmail(email);
      debugPrint('Existing sign-in methods for $email: $methods');
      if (methods.isNotEmpty) {
        throw FirebaseAuthException(
          code: 'email-already-in-use',
          message: 'An account already exists for $email. Please delete it from Firebase Console first.',
        );
      }
    } catch (e) {
      if (e is FirebaseAuthException) rethrow;
      debugPrint('fetchSignInMethods error: $e');
    }

    debugPrint('Creating auth user for $email...');
    UserCredential credential = await _auth.createUserWithEmailAndPassword(email: email, password: password);
    debugPrint('Auth user created: ${credential.user?.uid}');
    if (credential.user == null) return null;
    final userModel = UserModel(
      uid: credential.user!.uid,
      name: name,
      email: email,
      role: role,
      roomNumber: room,
      hostelBlock: block,
      phone: phone,
      createdAt: DateTime.now(),
    );
    try {
      debugPrint('Writing to Firestore...');
      await _firestore.collection('users').doc(userModel.uid).set(userModel.toMap());
      debugPrint('Firestore write success!');
    } catch (e) {
      debugPrint('Firestore write failed: $e');
      await credential.user!.delete();
      debugPrint('Auth user deleted due to Firestore failure');
      rethrow;
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', true);
    return userModel;
  }

  Future<void> forgotPassword(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  Future<void> signOut() async {
    await _auth.signOut();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('isLoggedIn');
  }

  Future<UserModel?> getCurrentUser() async {
    if (_auth.currentUser != null) {
      DocumentSnapshot doc = await _firestore.collection('users').doc(_auth.currentUser!.uid).get();
      if (doc.exists) {
        return UserModel.fromMap(doc.data() as Map<String, dynamic>);
      }
    }
    return null;
  }
}
