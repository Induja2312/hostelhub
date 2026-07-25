import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  AuthService() {
    // Only disable app verification in debug builds — never in production.
    if (kDebugMode) {
      _auth.setSettings(appVerificationDisabledForTesting: true);
    }
  }

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<UserModel?> signIn(String email, String password) async {
    UserCredential credential = await _auth.signInWithEmailAndPassword(
        email: email, password: password);
    if (credential.user == null) return null;
    try {
      DocumentSnapshot doc = await _firestore
          .collection('users')
          .doc(credential.user!.uid)
          .get();
      if (doc.exists) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isLoggedIn', true);
        return UserModel.fromMap(doc.data() as Map<String, dynamic>);
      }
    } catch (e) {
      debugPrint('Firestore read failed: $e');
    }
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

  /// Called after eCampus has already verified the credentials.
  /// Signs into Firebase (creating account if needed).
  /// If the student's eCampus password has changed since last login,
  /// re-authenticates with the old Firebase password is not possible
  /// client-side — instead we update the Firebase password to the new
  /// eCampus password so future logins stay in sync.
  Future<UserModel?> signInWithECampus(
      String rollNo, String ecampusPassword) async {
    final email = '${rollNo.toLowerCase()}@psgtech.ac.in';

    try {
      return await signIn(email, ecampusPassword);
    } on FirebaseAuthException catch (signInError) {
      // Account doesn't exist — create it using the eCampus password
      if (signInError.code == 'user-not-found') {
        final credential = await _auth.createUserWithEmailAndPassword(
            email: email, password: ecampusPassword);
        if (credential.user == null) return null;
        final userModel = UserModel(
          uid: credential.user!.uid,
          name: rollNo.toUpperCase(),
          email: email,
          role: 'student',
          roomNumber: '',
          hostelBlock: '',
          phone: '',
          createdAt: DateTime.now(),
        );
        await _firestore
            .collection('users')
            .doc(userModel.uid)
            .set(userModel.toMap());
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isLoggedIn', true);
        return userModel;
      }

      // Account exists but password doesn't match — eCampus password changed.
      // We can't re-authenticate without the old password, so use
      // sendPasswordResetEmail is not viable (async/email-based).
      // Best available option: inform the user clearly.
      if (signInError.code == 'wrong-password' ||
          signInError.code == 'invalid-credential' ||
          signInError.code == 'INVALID_LOGIN_CREDENTIALS') {
        throw Exception(
            'Your eCampus password has changed since your last login.\n'
            'Please use "Forgot Password" to reset your HostelHub password, '
            'then log in with your email ($email) and new password.');
      }

      rethrow;
    }
  }

  Future<UserModel?> register(String name, String email, String password,
      String role, String room, String block, String phone) async {
    try {
      final methods = await _auth.fetchSignInMethodsForEmail(email);
      debugPrint('Existing sign-in methods for $email: $methods');
      if (methods.isNotEmpty) {
        throw FirebaseAuthException(
          code: 'email-already-in-use',
          message:
              'An account already exists for $email. Please delete it from Firebase Console first.',
        );
      }
    } catch (e) {
      if (e is FirebaseAuthException) rethrow;
      debugPrint('fetchSignInMethods error: $e');
    }

    debugPrint('Creating auth user for $email...');
    UserCredential credential = await _auth.createUserWithEmailAndPassword(
        email: email, password: password);
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
      await _firestore
          .collection('users')
          .doc(userModel.uid)
          .set(userModel.toMap());
      debugPrint('Firestore write success!');
    } catch (e) {
      debugPrint('Firestore write failed: $e');
      await credential.user!.delete();
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
      DocumentSnapshot doc = await _firestore
          .collection('users')
          .doc(_auth.currentUser!.uid)
          .get();
      if (doc.exists) {
        return UserModel.fromMap(doc.data() as Map<String, dynamic>);
      }
    }
    return null;
  }
}
