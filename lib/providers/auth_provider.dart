import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  UserModel? currentUser;
  bool isLoading = false;
  String? errorMessage;

  // Signup
  Future<void> signup(UserModel user, String password) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      currentUser = await _authService.signup(user, password);
    } catch (e) {
      errorMessage = e.toString();
    }

    isLoading = false;
    notifyListeners();
  }

  // Login
  Future<void> login(String email, String password) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      currentUser = await _authService.login(email, password);
    } catch (e) {
      errorMessage = e.toString();
    }

    isLoading = false;
    notifyListeners();
  }

  // Logout
  Future<void> logout() async {
    isLoading = true;
    notifyListeners();

    await _authService.logout();
    currentUser = null;

    isLoading = false;
    notifyListeners();
  }

  // Fetch current user from Firebase (if logged in)
  Future<void> fetchCurrentUser() async {
    isLoading = true;
    notifyListeners();

    try {
      currentUser = await _authService.getCurrentUser();
    } catch (e) {
      errorMessage = e.toString();
    }

    isLoading = false;
    notifyListeners();
  }
}
