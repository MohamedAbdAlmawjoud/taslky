import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../controllers/auth_controller.dart';
import '../models/user_model.dart';

class AuthProvider extends ChangeNotifier {
  AuthProvider(this.controller) {
    _subscription = controller.authStateChanges.listen(
      _onUser,
      onError: (Object e) {
        error = e.toString();
        loading = false;
        notifyListeners();
      },
    );
  }
  final AuthController controller;
  StreamSubscription<User?>? _subscription;
  User? currentUser;
  UserModel? profile;
  bool loading = true;
  String? error;
  Future<void> _onUser(User? user) async {
    currentUser = user;
    profile = null;
    error = null;
    loading = true;
    notifyListeners();
    if (user != null) {
      try {
        profile = await controller.loadProfile(user);
      } catch (e) {
        error = _message(e);
      }
    }
    loading = false;
    notifyListeners();
  }

  String _message(Object e) =>
      e is FirebaseAuthException ? (e.message ?? e.code) : e.toString();
  Future<void> login(String email, String password) async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      await controller.login(email, password);
    } catch (e) {
      error = _message(e);
      rethrow;
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> register(String name, String email, String password) async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      await controller.register(name, email, password);
    } catch (e) {
      error = _message(e);
      rethrow;
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    loading = true;
    notifyListeners();
    try {
      await controller.logout();
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> resetPassword(String email) async {
    error = null;
    notifyListeners();
    try {
      await controller.resetPassword(email);
    } catch (e) {
      error = _message(e);
      rethrow;
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
