import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_map_app/models/achievement.dart';
import 'package:flutter_map_app/services/achievement_service.dart';
import '../models/city.dart';
import '../models/place.dart';
import '../models/user.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final AchievementService _achievementService = AchievementService();

  Future<List<City>> getCities() async {
    final snap = await _db.collection('cities').get();
    return snap.docs.map((d) => City.fromMap(d.id, d.data())).toList();
  }

  Future<List<Place>> getAllPlaces() async {
    final snap = await _db.collection('places').get();
    return snap.docs.map((d) => Place.fromMap(d.id, d.data())).toList();
  }

  Future<List<Place>> getPlacesForCity(String cityId) async {
    final snap =
        await _db
            .collection('places')
            .where('cityRef', isEqualTo: _db.doc('cities/$cityId'))
            .get();

    return snap.docs.map((d) => Place.fromMap(d.id, d.data())).toList();
  }


  Future<AppUser?> getUser(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    if (!doc.exists) return null;
    final data = doc.data() ?? <String, dynamic>{};
    return AppUser.fromMap(doc.id, data);
  }

  Future<int> getPlaceLikedCount(String placeId) async {
    final doc = await _db.collection('places').doc(placeId).get();
    if (!doc.exists) return 0;
    final data = doc.data() ?? <String, dynamic>{};
    return (data['likedCount'] as num?)?.toInt() ?? 0;
  }

  Stream<int> getPlaceLikedCountStream(String placeId) {
    return _db
        .collection('places')
        .doc(placeId)
        .snapshots()
        .map((doc) {
          final data = doc.data() ?? <String, dynamic>{};
          return (data['likedCount'] as num?)?.toInt() ?? 0;
        });
  }



  Future<bool> isPlaceFavorited(String uid, String placeId) async {
    final doc = await _db.collection('users').doc(uid).get();
    final data = doc.data();
    final favs = (data == null)
        ? <String>[]
        : (data['favouritePlaces'] as List<dynamic>?)?.cast<String>() ?? <String>[];
    return favs.contains(placeId);
  }

  Future<List<Achievement>> addPlaceToFavourites(String uid, String placeId) async {
    final userRef = _db.collection('users').doc(uid);

    debugPrint('[FirestoreService] addPlaceToFavourites called for user: $uid, placeId: $placeId');

    // Czytaj obecne dane
    final userSnap = await userRef.get();
    if (!userSnap.exists) {
      debugPrint('[FirestoreService] User does not exist');
      return [];
    }

    final currentUser = AppUser.fromSnapshot(userSnap);
    
    // Sprawdź czy już jest w ulubionych
    if (currentUser.favouritePlaces.contains(placeId)) {
      debugPrint('[FirestoreService] Place already in favorites');
      return [];
    }

    final newLikedCount = currentUser.totalPlacesLiked + 1;
    debugPrint('[FirestoreService] Current liked count: ${currentUser.totalPlacesLiked}, New count: $newLikedCount');

    // Zwiększ licznik dla użytkownika i licznik polubiań dla miejsca
    await userRef.set(
      {
        'favouritePlaces': FieldValue.arrayUnion([placeId]),
        'totalPlacesLiked': newLikedCount,
      },
      SetOptions(merge: true),
    );

    // Zwiększ licznik polubiań dla miejsca
    await _db.collection('places').doc(placeId).set(
      {
        'likedCount': FieldValue.increment(1),
      },
      SetOptions(merge: true),
    );

    debugPrint('[FirestoreService] Updated totalPlacesLiked to $newLikedCount and incremented place likedCount');

    // Sprawdź osiągnięcia bezpośrednio z licznika
    final newlyUnlocked = <Achievement>[];
    try {
      debugPrint('[FirestoreService] Fetching achievements with type: ${AchievementType.likePlace.asString}');
      
      final achQuery = await _db
          .collection('achievements')
          .where('type', isEqualTo: AchievementType.likePlace.asString)
          .get();

      debugPrint('[FirestoreService] Found ${achQuery.docs.length} achievements with type likePlace');

      for (final achDoc in achQuery.docs) {
        final achievement = Achievement.fromSnapshot(achDoc);
        final alreadyUnlocked = currentUser.achievementsSummary[achievement.id] == true;

        debugPrint('[FirestoreService] Checking achievement: ${achievement.title} (${achievement.id})');
        debugPrint('[FirestoreService]   Already unlocked: $alreadyUnlocked');
        debugPrint('[FirestoreService]   Target: ${achievement.criteria['target']}, Progress: $newLikedCount');

        if (alreadyUnlocked) {
          debugPrint('[FirestoreService]   -> Already unlocked, skipping');
          continue;
        }

        final criteria = achievement.criteria;
        final target = (criteria['target'] as num?)?.toInt() ?? 0;
        
        if (target > 0 && newLikedCount >= target) {
          debugPrint('[FirestoreService]   -> UNLOCKED!');
          newlyUnlocked.add(achievement);
          
          // Zapisz że osiągnięcie zostało zdobyte
          await userRef.set({
            'achievementsSummary': {achievement.id: true},
            'achievementsUnlockedAt': {achievement.id: FieldValue.serverTimestamp()},
          }, SetOptions(merge: true));
        } else {
          debugPrint('[FirestoreService]   -> Not yet reached (target: $target, progress: $newLikedCount)');
        }
      }
      
      debugPrint('[FirestoreService] Total unlocked achievements: ${newlyUnlocked.length}');
    } catch (e) {
      debugPrint('[FirestoreService] Error checking place like achievements: $e');
    }

    return newlyUnlocked;
  }


  Future<void> removePlaceFromFavourites(String uid, String placeId) async {
    await _db.collection('users').doc(uid).set(
      {
        'favouritePlaces': FieldValue.arrayRemove([placeId]),
        'totalPlacesLiked': FieldValue.increment(-1),
      },
      SetOptions(merge: true),
    );

    // Zmniejsz licznik polubiań dla miejsca
    await _db.collection('places').doc(placeId).set(
      {
        'likedCount': FieldValue.increment(-1),
      },
      SetOptions(merge: true),
    );
  }


  Future<PlaceVisitResult> reportPlaceVisit({
    required String uid,
    required Place place,
  }) async {
    final userRef = _db.collection('users').doc(uid);

    final userSnap = await userRef.get();
    if (!userSnap.exists) {
      return PlaceVisitResult(created: false, unlockedAchievements: []);
    }

    final user = AppUser.fromSnapshot(userSnap);
    if (user.visitedPlaces.contains(place.id)) {
      return PlaceVisitResult(created: false, unlockedAchievements: []);
    }

    await userRef.update({
      'visitedPlaces': FieldValue.arrayUnion([place.id]),
      'totalPlacesVisited': FieldValue.increment(1),
    });

    final updatedUser = await getUser(uid);
    if (updatedUser == null) {
      return PlaceVisitResult(created: true, unlockedAchievements: []);
    }

    final unlockedAchievements = await _achievementService.checkAndGrantAchievements(
        updatedUser, AchievementType.visit);

    return PlaceVisitResult(created: true, unlockedAchievements: unlockedAchievements);
  }

  Future<void> updateUserEquippedAchievements(String uid, List<String> achievementIds) async {
    await _db.collection('users').doc(uid).update({
      'equippedAchievements': achievementIds,
    });
  }

  Future<List<Achievement>> reportRouteCreation(String uid) async {
    final userRef = _db.collection('users').doc(uid);

    debugPrint('[FirestoreService] reportRouteCreation called for user: $uid');

    // Czytaj obecne dane zanim uaktualnisz
    final userSnap = await userRef.get();
    if (!userSnap.exists) {
      debugPrint('[FirestoreService] User does not exist, creating new entry');
      await userRef.set({
        'totalRoutesCreated': 1,
      }, SetOptions(merge: true));
      return [];
    }

    final currentUser = AppUser.fromSnapshot(userSnap);
    final newProgress = currentUser.totalRoutesCreated + 1;

    debugPrint('[FirestoreService] Current route count: ${currentUser.totalRoutesCreated}, New count: $newProgress');

    // Zwiększ licznik
    await userRef.set({
      'totalRoutesCreated': newProgress,
    }, SetOptions(merge: true));

    debugPrint('[FirestoreService] Updated totalRoutesCreated to $newProgress');

    // METODOLOGIA 1: Bezpośrednie sprawdzenie z Firestore
    final newlyUnlocked = <Achievement>[];
    try {
      debugPrint('[FirestoreService] METHOD 1: Fetching achievements with type: ${AchievementType.createRoute.asString}');
      
      final achQuery = await _db
          .collection('achievements')
          .where('type', isEqualTo: AchievementType.createRoute.asString)
          .get();

      debugPrint('[FirestoreService] Found ${achQuery.docs.length} achievements with type createRoute');
      
      if (achQuery.docs.isEmpty) {
        debugPrint('[FirestoreService] WARNING: No achievements found for type createRoute!');
        debugPrint('[FirestoreService] Available achievements:');
        
        // Debug: pokaz co jest w achievements
        final allAchs = await _db.collection('achievements').get();
        for (final ach in allAchs.docs) {
          final data = ach.data();
          debugPrint('[FirestoreService]   - ${ach.id}: type=${data['type']}, title=${data['title']}');
        }
      }

      for (final achDoc in achQuery.docs) {
        final achievement = Achievement.fromSnapshot(achDoc);
        final alreadyUnlocked = currentUser.achievementsSummary[achievement.id] == true;

        debugPrint('[FirestoreService] Checking achievement: ${achievement.title} (${achievement.id})');
        debugPrint('[FirestoreService]   Already unlocked: $alreadyUnlocked');
        debugPrint('[FirestoreService]   Target: ${achievement.criteria['target']}, Progress: $newProgress');

        if (alreadyUnlocked) {
          debugPrint('[FirestoreService]   -> Already unlocked, skipping');
          continue;
        }

        final criteria = achievement.criteria;
        final target = (criteria['target'] as num?)?.toInt() ?? 0;
        
        if (target > 0 && newProgress >= target) {
          debugPrint('[FirestoreService]   -> UNLOCKED!');
          newlyUnlocked.add(achievement);
          
          // Zapisz że osiągnięcie zostało zdobyte
          await userRef.set({
            'achievementsSummary': {achievement.id: true},
            'achievementsUnlockedAt': {achievement.id: FieldValue.serverTimestamp()},
          }, SetOptions(merge: true));
        } else {
          debugPrint('[FirestoreService]   -> Not yet reached (target: $target, progress: $newProgress)');
        }
      }
      
      debugPrint('[FirestoreService] METHOD 1: Total unlocked achievements: ${newlyUnlocked.length}');
    } catch (e, st) {
      debugPrint('[FirestoreService] Error in METHOD 1: $e\n$st');
    }

    // METODOLOGIA 2: Fallback - jeśli METHOD 1 nie znalazł nic, spróbuj ze wszystkich osiągnięć
    if (newlyUnlocked.isEmpty) {
      debugPrint('[FirestoreService] METHOD 2 FALLBACK: Checking all achievements');
      try {
        final allAchs = await _db.collection('achievements').get();
        for (final achDoc in allAchs.docs) {
          final achievement = Achievement.fromSnapshot(achDoc);
          
          if (achievement.type != AchievementType.createRoute) {
            continue;
          }

          final alreadyUnlocked = currentUser.achievementsSummary[achievement.id] == true;
          if (alreadyUnlocked) {
            continue;
          }

          final target = (achievement.criteria['target'] as num?)?.toInt() ?? 0;
          if (target > 0 && newProgress >= target) {
            debugPrint('[FirestoreService] FALLBACK: Unlocked ${achievement.title}');
            newlyUnlocked.add(achievement);
            
            await userRef.set({
              'achievementsSummary': {achievement.id: true},
              'achievementsUnlockedAt': {achievement.id: FieldValue.serverTimestamp()},
            }, SetOptions(merge: true));
          }
        }
        debugPrint('[FirestoreService] METHOD 2: Found ${newlyUnlocked.length} unlocked achievements');
      } catch (e) {
        debugPrint('[FirestoreService] Error in METHOD 2: $e');
      }
    }

    return newlyUnlocked;
  }
}

/// Result returned by [reportPlaceVisit]
class PlaceVisitResult {
  final bool created;
  final List<Achievement> unlockedAchievements;

  PlaceVisitResult({required this.created, required this.unlockedAchievements});
}
