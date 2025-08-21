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
      // 1) WSZYSTKIE ODCZYTY NA POCZĄTKU
      final newSnap = await tx.get(newUsernameRef);
      final userSnap = await tx.get(usersRef);

      if (!userSnap.exists) {
        throw Exception('Profil użytkownika nie istnieje.');
      }

      final userData = userSnap.data() as Map<String, dynamic>;
      final oldLower = (userData['usernameLower'] ?? '') as String;

      // Jeśli newLower == oldLower to nic nie zmieniamy
      if (oldLower == usernameLower) {
        return;
      }

      DocumentReference<Map<String, dynamic>>? oldRef;
      DocumentSnapshot<Map<String, dynamic>>? oldSnap;
      if (oldLower.isNotEmpty && oldLower != usernameLower) {
        oldRef = _firestore.collection('usernames').doc(oldLower);
        oldSnap = await tx.get(oldRef);
      }

      // Sprawdź dostępność nowej nazwy
      if (newSnap.exists) {
        final existingUid =
            (newSnap.data() as Map<String, dynamic>?)?['uid'] as String?;
        if (existingUid != null && existingUid != uid) {
          throw Exception('Ta nazwa jest już zajęta.');
        }
        // jeśli mapping już wskazuje na nas — przejdziemy dalej i zaktualizujemy profil
      }

      // 2) DOPIERO TERAZ ZAPISY
      tx.set(newUsernameRef, {
        'uid': uid,
        'createdAt': FieldValue.serverTimestamp(),
      });

      tx.update(usersRef, {
        'username': username,
        'usernameLower': usernameLower,
      });

      if (oldRef != null && oldSnap != null && oldSnap.exists) {
        final oldUid =
            (oldSnap.data() as Map<String, dynamic>?)?['uid'] as String?;
        if (oldUid == uid) {
          tx.delete(oldRef);
        }
      }
    });
  }
}