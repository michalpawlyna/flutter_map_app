// auth_service.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn signIn = GoogleSignIn.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  Future<User?> registerWithEmail(String email, String password) async {
    final creds = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    final user = creds.user;
    if (user != null) {
      final usersRef = _firestore.collection('users').doc(user.uid);
      await usersRef.set({
        'uid': user.uid,
        'email': email,
        'username': '',
        'displayName': user.displayName ?? '',
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

  Future<User?> signInWithGoogle({String? serverClientId}) async {
    try {
      if (serverClientId != null && serverClientId.isNotEmpty) {
        await signIn.initialize(serverClientId: serverClientId);
      } else {
        await signIn.initialize();
      }
    } catch (e) {}

    final GoogleSignInAccount? googleAccount = await signIn.authenticate();
    if (googleAccount == null) {
      return null;
    }

    final googleAuth = await googleAccount.authentication;
    final String? idToken = googleAuth.idToken;

    AuthCredential credential;

    if (idToken != null && idToken.isNotEmpty) {
      credential = GoogleAuthProvider.credential(idToken: idToken);
    } else {
      try {
        final scopes = <String>['openid', 'email', 'profile'];
        final GoogleSignInClientAuthorization authorization =
            await googleAccount.authorizationClient.authorizeScopes(scopes);

        final String? accessToken = authorization.accessToken;
        if (accessToken == null || accessToken.isEmpty) {
          throw Exception(
            'Nie udało się pobrać accessToken. Sprawdź konfigurację OAuth (serverClientId, SHA-1/256, scopes).',
          );
        }

        credential = GoogleAuthProvider.credential(accessToken: accessToken);
      } catch (e) {
        throw Exception(
          'Nie udało się uzyskać tokenów z Google (idToken/accessToken). Sprawdź konfigurację Google/Firebase. Detale: $e',
        );
      }
    }

    final userCredential = await FirebaseAuth.instance.signInWithCredential(
      credential,
    );
    final user = userCredential.user;

    if (user != null) {
      final usersRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid);
      final snap = await usersRef.get();
      if (!snap.exists) {
        await usersRef.set({
          'uid': user.uid,
          'email': user.email ?? '',
          'username': '',
          'displayName': user.displayName ?? googleAccount.displayName ?? '',
          'photoURL': user.photoURL ?? googleAccount.photoUrl ?? '',
          'createdAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      } else {
        final data = snap.data() as Map<String, dynamic>? ?? {};
        final update = <String, dynamic>{};
        if ((data['displayName'] as String?)?.isEmpty ?? true) {
          update['displayName'] =
              user.displayName ?? googleAccount.displayName ?? '';
        }
        if ((data['photoURL'] as String?)?.isEmpty ?? true) {
          update['photoURL'] = user.photoURL ?? googleAccount.photoUrl ?? '';
        }
        if (update.isNotEmpty) {
          await usersRef.set(update, SetOptions(merge: true));
        }
      }
    }

    return user;
  }

  Future<void> signOut() async {
    await _auth.signOut();

    try {
      await signIn.signOut();
    } catch (_) {}
  }

  Future<void> updateUsername({required String newUsername}) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('Użytkownik nie jest zalogowany');
    }

    final uid = user.uid;
    final username = newUsername.trim();

    //regex walidacji (3-30 znaków, a-z0-9._-)
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

      final currentUsername =
          (userSnap.data() as Map<String, dynamic>?)?['username'] as String? ??
          '';

      if (currentUsername == username) return;

      tx.update(usersRef, {'username': username});
    });
  }
}
