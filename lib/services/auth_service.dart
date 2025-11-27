import 'package:flutter/material.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final Map<String, String> _users = {};

  String? _currentUserEmail;

  Future<String> login(String email, String password) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 800));

    email = email.trim();
    password = password.trim();

    if (email.isEmpty || password.isEmpty) {
      return "Email and password must not be empty.";
    }
    if (!_isValidEmail(email)) {
      return "Please enter a valid email address.";
    }
    final stored = _users[email];
    if (stored == null) {
      return "No account found for that email.";
    }
    if (stored != password) {
      return "Invalid password.";
    }

    _currentUserEmail = email;
    return "ok";
  }

  Future<String> register(String email, String password) async {
    await Future.delayed(const Duration(milliseconds: 800));

    email = email.trim();
    password = password.trim();

    if (email.isEmpty || password.isEmpty) {
      return "Email and password must not be empty.";
    }
    if (!_isValidEmail(email)) {
      return "Please enter a valid email address.";
    }
    if (password.length < 6) {
      return "Password must be at least 6 characters.";
    }
    if (_users.containsKey(email)) {
      return "An account already exists for that email.";
    }

    _users[email] = password;
    _currentUserEmail = email;
    return "ok";
  }

  Future<void> signOut() async {
    await Future.delayed(const Duration(milliseconds: 200));
    _currentUserEmail = null;
  }

  String? get currentUserEmail => _currentUserEmail;

  bool _isValidEmail(String email) {
    final re = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    return re.hasMatch(email);
  }
}
