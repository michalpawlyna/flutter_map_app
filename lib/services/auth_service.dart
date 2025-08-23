// auth_service.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  // Singleton
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Strumień zmian stanu uwierzytelnienia
  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  // Rejestracja + utworzenie dokumentu w Firestore (users/{uid})
  Future<User?> registerWithEmail(String email, String password) async {
    final creds = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    final user = creds.user;
    if (user != null) {
      // Utworzenie minimalnego profilu w Firestore (bez usernameLower)
      final usersRef = _firestore.collection('users').doc(user.uid);
      await usersRef.set({
        'uid': user.uid,
        'email': email,
        'username': '',
        'displayName': '',
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }
    return user;
  }

  Future<User?> loginWithEmail(String email, String password) async {
    final creds = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    return creds.user;
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  /// Prosta aktualizacja nazwy użytkownika:
  /// - waliduje nową nazwę
  /// - aktualizuje users/{uid}.username
  /// Rzuca [Exception] jeśli użytkownik nie jest zalogowany lub profil nie istnieje.
  Future<void> updateUsername({
    required String newUsername,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('Użytkownik nie jest zalogowany');
    }

    final uid = user.uid;
    final username = newUsername.trim();

    // prosty regex walidacji (3-30 znaków, a-z0-9._-)
    final usernameRegex = RegExp(r'^[a-z0-9._-]{3,30}$');
    if (!usernameRegex.hasMatch(username.toLowerCase())) {
      throw Exception('Nieprawidłowa nazwa (3-30 znaków, a-z0-9._-).');
    }

    final usersRef = _firestore.collection('users').doc(uid);

    await _firestore.runTransaction((tx) async {
      final userSnap = await tx.get(usersRef);

      if (!userSnap.exists) {
        throw Exception('Profil użytkownika nie istnieje.');
      }

      final currentUsername = (userSnap.data() as Map<String, dynamic>?)?['username'] as String? ?? '';

      // jeśli taka sama nazwa — nic nie robimy
      if (currentUsername == username) return;

      tx.update(usersRef, {
        'username': username,
      });
    });
  }
}
