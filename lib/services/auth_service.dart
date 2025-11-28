import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;

  /// LOGIN
  Future<String> login(String email, String password) async {
    email = email.trim();
    password = password.trim();

    if (email.isEmpty || password.isEmpty) {
      return "Email and password must not be empty.";
    }

    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      return "ok";
    } on FirebaseAuthException catch (e) {
      return e.message ?? "Login failed.";
    } catch (e) {
      return "An unexpected error occurred.";
    }
  }

  /// REGISTER
  Future<String> register({
    required String name,
    required String phone,
    required String email,
    required String password,
    required String preferredLanguage,
  }) async {
    email = email.trim();
    password = password.trim();
    name = name.trim();
    phone = phone.trim();

    if (email.isEmpty || password.isEmpty || name.isEmpty || phone.isEmpty) {
      return "All fields are required.";
    }
    if (password.length < 6) {
      return "Password must be at least 6 characters.";
    }

    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Store additional profile data in Firestore
      await _firestore.collection('farmers').doc(userCredential.user!.uid).set({
        'name': name,
        'phone': phone,
        'email': email,
        'preferred_language': preferredLanguage,
        'created_at': FieldValue.serverTimestamp(),
      });

      return "ok";
    } on FirebaseAuthException catch (e) {
      return e.message ?? "Registration failed.";
    } catch (e) {
      return "An unexpected error occurred.";
    }
  }

  /// SIGN OUT
  Future<void> signOut() async {
    await _auth.signOut();
  }

  /// GET PROFILE DATA
  Future<Map<String, dynamic>?> getProfile() async {
    if (currentUser == null) return null;
    final doc = await _firestore.collection('farmers').doc(currentUser!.uid).get();
    return doc.data();
  }
}
