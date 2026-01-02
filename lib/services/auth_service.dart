import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Отримати поточного користувача
  User? get currentUser => _auth.currentUser;

  // Вхід (Login)
  Future<User?> signIn(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return result.user;
    } catch (e) {
      debugPrint("Помилка входу: $e");
      return null;
    }
  }

  // Реєстрація (Sign Up)
  Future<User?> signUp(String email, String password) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return result.user;
    } catch (e) {
      debugPrint("Помилка реєстрації: $e");
      return null;
    }
  }

  // Вихід (Logout)
  Future<void> signOut() async {
    await _auth.signOut();
  }
}
