import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<User?> registerWithEmail(String email, String password) async {
    final creds = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    
    // Initialize avatar seed for new user
    if (creds.user != null) {
      await _initializeAvatarSeed(creds.user!.uid);
    }
    
    return creds.user;
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

  User? get currentUser => _auth.currentUser;

  // Initialize avatar seed for new user
  Future<void> _initializeAvatarSeed(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'avatar_seed_$userId';
    if (!prefs.containsKey(key)) {
      await prefs.setString(key, userId); // Default to user ID
    }
  }

  // Get avatar seed for current user
  Future<String?> getCurrentUserAvatarSeed() async {
    final user = currentUser;
    if (user == null) return null;
    
    final prefs = await SharedPreferences.getInstance();
    final key = 'avatar_seed_${user.uid}';
    return prefs.getString(key) ?? user.uid;
  }

  // Save avatar seed for current user
  Future<void> saveCurrentUserAvatarSeed(String seed) async {
    final user = currentUser;
    if (user == null) return;
    
    final prefs = await SharedPreferences.getInstance();
    final key = 'avatar_seed_${user.uid}';
    await prefs.setString(key, seed);
  }

  // Generate a random avatar seed
  String generateRandomAvatarSeed() {
    return DateTime.now().millisecondsSinceEpoch.toString() + 
           Random().nextInt(10000).toString();
  }
}