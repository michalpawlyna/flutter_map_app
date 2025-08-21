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
      // Utworzenie minimalnego profilu w Firestore
      final usersRef = _firestore.collection('users').doc(user.uid);
      await usersRef.set({
        'uid': user.uid,
        'email': email,
        'username': '',
        'usernameLower': '',
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

  /// Aktualizuje nazwę użytkownika w bezpieczny sposób:
  /// - tworzy dokument usernames/{usernameLower} (jeżeli nie istnieje)
  /// - aktualizuje users/{uid}.username i users/{uid}.usernameLower
  /// - usuwa stare usernames/{oldLower} mapowanie (jeśli istniało)
  ///
  /// Rzuca [Exception] z komunikatem gdy nazwa jest zajęta lub użytkownik nie jest zalogowany.
  Future<void> updateUsername({
    required String newUsername,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('Użytkownik nie jest zalogowany');
    }

    final uid = user.uid;
    final username = newUsername.trim();
    final usernameLower = username.toLowerCase();

    // prosty regex walidacji (3-30 znaków, a-z0-9._-)
    final usernameRegex = RegExp(r'^[a-z0-9._-]{3,30}$');
    if (!usernameRegex.hasMatch(usernameLower)) {
      throw Exception('Nieprawidłowa nazwa (3-30 znaków, a-z0-9._-).');
    }

    final usersRef = _firestore.collection('users').doc(uid);
    final newUsernameRef = _firestore.collection('usernames').doc(usernameLower);

    await _firestore.runTransaction((tx) async {
      // Czy nazwa jest już zajęta?
      final newSnap = await tx.get(newUsernameRef);
      if (newSnap.exists) {
        // jeśli istnieje i mapping wskazuje na tego samego usera, pozwól (nic nie rób)
        final existingUid = newSnap.data()?['uid'] as String?;
        if (existingUid != null && existingUid != uid) {
          throw Exception('Ta nazwa jest już zajęta.');
        }
        // jeśli mapping już wskazuje na nas — to nic do roboty
      }

      // Pobierz dokument użytkownika
      final userSnap = await tx.get(usersRef);
      if (!userSnap.exists) {
        throw Exception('Profil użytkownika nie istnieje.');
      }

      final userData = userSnap.data()!;
      final oldLower = (userData['usernameLower'] ?? '') as String;

      // Jeśli newLower == oldLower to nic nie zmieniamy (opcjonalnie zwracamy)
      if (oldLower == usernameLower) {
        return;
      }

      // Stwórz mapping username -> uid
      tx.set(newUsernameRef, {
        'uid': uid,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Zaktualizuj profil użytkownika
      tx.update(usersRef, {
        'username': username,
        'usernameLower': usernameLower,
      });

      // Usuń stare mapping jeśli istniało (i było inne niż nowe)
      if (oldLower.isNotEmpty && oldLower != usernameLower) {
        final oldRef = _firestore.collection('usernames').doc(oldLower);
        // upewnij się, że stary mapping nadal wskazuje na tego usera przed usunięciem
        final oldSnap = await tx.get(oldRef);
        if (oldSnap.exists) {
          final oldUid = oldSnap.data()?['uid'] as String?;
          if (oldUid == uid) {
            tx.delete(oldRef);
          }
        }
      }
    });
  }
}
