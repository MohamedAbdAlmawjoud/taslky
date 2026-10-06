import 'package:firebase_auth/firebase_auth.dart';

import '../models/user_model.dart';
import '../services/auth_service.dart';

class AuthController {
  AuthController(this.service);
  final AuthService service;
  Stream<User?> get authStateChanges => service.authStateChanges;
  Future<UserModel?> loadProfile(User user) => service.loadProfile(user);
  Future<void> login(String email, String password) =>
      service.login(email, password);
  Future<void> register(String name, String email, String password) =>
      service.register(name, email, password);
  Future<void> logout() => service.logout();
  Future<void> resetPassword(String email) => service.resetPassword(email);
}
