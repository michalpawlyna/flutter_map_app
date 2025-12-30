import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AppUser {
  final String uid;
  final String email;
  final String username;
  final String displayName;
  final String? photoURL;
  final List<String> favouritePlaces;
  final String? role;
  final Timestamp? createdAt;
  final int totalPlacesVisited;
  final int totalPlacesLiked;
  final int totalRoutesCreated;
  final Map<String, bool> achievementsSummary;
  final Map<String, Timestamp?> achievementsUnlockedAt;
  final List<String> visitedPlaces;
  final List<String> equippedAchievements;

  AppUser({
    required this.uid,
    required this.email,
    this.username = '',
    this.displayName = '',
    this.photoURL,
    this.favouritePlaces = const <String>[],
    this.role,
    this.createdAt,
    this.totalPlacesVisited = 0,
    this.totalPlacesLiked = 0,
    this.totalRoutesCreated = 0,
    this.achievementsSummary = const <String, bool>{},
    this.achievementsUnlockedAt = const <String, Timestamp?>{},
    this.visitedPlaces = const <String>[],
    this.equippedAchievements = const <String>[],
  });

  factory AppUser.fromMap(String uid, Map<String, dynamic> data) {
    return AppUser(
      uid: uid,
      email: data['email'] as String? ?? '',
      username: data['username'] as String? ?? '',
      displayName: data['displayName'] as String? ?? '',
      photoURL: data['photoURL'] as String? ?? data['photoUrl'] as String?,
      favouritePlaces:
          (data['favouritePlaces'] as List<dynamic>?)?.cast<String>() ??
          <String>[],
      role: data['role'] as String?,
      createdAt: data['createdAt'] as Timestamp?,
      totalPlacesVisited: (data['totalPlacesVisited'] as num?)?.toInt() ?? 0,
      totalPlacesLiked: (data['totalPlacesLiked'] as num?)?.toInt() ?? 0,
      totalRoutesCreated: (data['totalRoutesCreated'] as num?)?.toInt() ?? 0,
      achievementsSummary:
          ((data['achievementsSummary'] as Map<String, dynamic>?)?.map(
            (k, v) => MapEntry(k, v as bool),
          )) ??
          <String, bool>{},
      achievementsUnlockedAt:
          ((data['achievementsUnlockedAt'] as Map<String, dynamic>?)?.map(
            (k, v) => MapEntry(k, v as Timestamp?),
          )) ??
          <String, Timestamp?>{},
      visitedPlaces:
          (data['visitedPlaces'] as List<dynamic>?)?.cast<String>() ??
          <String>[],
      equippedAchievements:
          (data['equippedAchievements'] as List<dynamic>?)?.cast<String>() ??
          <String>[],
    );
  }

  factory AppUser.fromSnapshot(DocumentSnapshot<Map<String, dynamic>> snap) {
    final data = snap.data() ?? <String, dynamic>{};
    return AppUser.fromMap(snap.id, data);
  }

  Map<String, dynamic> toMap({bool includeServerTimestamp = false}) {
    final map = <String, dynamic>{
      'uid': uid,
      'email': email,
      'username': username,
      'displayName': displayName,
      'photoURL': photoURL ?? '',
      'favouritePlaces': favouritePlaces,
      'role': role ?? '',
      'totalPlacesVisited': totalPlacesVisited,
      'totalPlacesLiked': totalPlacesLiked,
      'totalRoutesCreated': totalRoutesCreated,
      'achievementsSummary': achievementsSummary,
      'achievementsUnlockedAt': achievementsUnlockedAt,
      'visitedPlaces': visitedPlaces,
      'equippedAchievements': equippedAchievements,
    };

    if (includeServerTimestamp) {
      map['createdAt'] = FieldValue.serverTimestamp();
    } else if (createdAt != null) {
      map['createdAt'] = createdAt;
    }

    return map;
  }

  AppUser copyWith({
    String? uid,
    String? email,
    String? username,
    String? displayName,
    String? photoURL,
    List<String>? favouritePlaces,
    String? role,
    Timestamp? createdAt,
    int? totalPlacesVisited,
    int? totalPlacesLiked,
    int? totalRoutesCreated,
    Map<String, bool>? achievementsSummary,
    Map<String, Timestamp?>? achievementsUnlockedAt,
    List<String>? visitedPlaces,
    List<String>? equippedAchievements,
  }) {
    return AppUser(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      username: username ?? this.username,
      displayName: displayName ?? this.displayName,
      photoURL: photoURL ?? this.photoURL,
      favouritePlaces: favouritePlaces ?? this.favouritePlaces,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
      totalPlacesVisited: totalPlacesVisited ?? this.totalPlacesVisited,
      totalPlacesLiked: totalPlacesLiked ?? this.totalPlacesLiked,
      totalRoutesCreated: totalRoutesCreated ?? this.totalRoutesCreated,
      achievementsSummary: achievementsSummary ?? this.achievementsSummary,
      achievementsUnlockedAt:
          achievementsUnlockedAt ?? this.achievementsUnlockedAt,
      visitedPlaces: visitedPlaces ?? this.visitedPlaces,
      equippedAchievements: equippedAchievements ?? this.equippedAchievements,
    );
  }

  static AppUser fromFirebaseUser(User fbUser) {
    return AppUser(
      uid: fbUser.uid,
      email: fbUser.email ?? '',
      displayName: fbUser.displayName ?? '',
      photoURL: fbUser.photoURL,
    );
  }
}
