import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../services/notification_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService;
  final FirestoreService _firestoreService;

  UserModel? _currentUserModel;
  bool _isLoading = false;

  AuthProvider(this._authService, this._firestoreService) {
    _init();
  }

  UserModel? get currentUserModel => _currentUserModel;
  Object? get user => _currentUserModel;
  bool get isLoading => _isLoading;

  Future<void> _onUserLoaded(UserModel? user) async {
    if (user != null) {
      await NotificationService().saveToken(user.uid);
      NotificationService().listenForAlerts(user.uid);
    }
  }

  Future<void> _init() async {
    _currentUserModel = await _authService.getCurrentUser();
    await _onUserLoaded(_currentUserModel);
    _isLoading = false;
    notifyListeners();
  }

  Future<void> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();
    try {
      _currentUserModel = await _authService.signIn(email, password);
      await _onUserLoaded(_currentUserModel);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> register(String name, String email, String password,
      String role, String room, String block, String phone) async {
    _isLoading = true;
    notifyListeners();
    try {
      _currentUserModel = await _authService.register(
          name, email, password, role, room, block, phone);
      await _onUserLoaded(_currentUserModel);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateProfile(String uid, Map<String, dynamic> data) async {
    await _firestoreService.updateDocument('users', uid, data);
    _currentUserModel = await _authService.getCurrentUser();
    notifyListeners();
  }

  Future<void> forgotPassword(String email) async {
    await _authService.forgotPassword(email);
  }

  Future<void> logout() async {
    await _authService.signOut();
    _currentUserModel = null;
    notifyListeners();
  }
}
