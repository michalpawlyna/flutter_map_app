import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/city.dart';
import '../models/place.dart';
import '../models/user.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

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


  Future<bool> isPlaceFavorited(String uid, String placeId) async {
    final doc = await _db.collection('users').doc(uid).get();
    final data = doc.data();
    final favs = (data == null)
        ? <String>[]
        : (data['favouritePlaces'] as List<dynamic>?)?.cast<String>() ?? <String>[];
    return favs.contains(placeId);
  }

  Future<void> addPlaceToFavourites(String uid, String placeId) async {
    await _db.collection('users').doc(uid).set(
      {
        'favouritePlaces': FieldValue.arrayUnion([placeId]),
      },
      SetOptions(merge: true),
    );
  }


  Future<void> removePlaceFromFavourites(String uid, String placeId) async {
    await _db.collection('users').doc(uid).set(
      {
        'favouritePlaces': FieldValue.arrayRemove([placeId]),
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
    final userData = userSnap.data() ?? <String, dynamic>{};
    final visited = (userData['visitedPlaces'] as List<dynamic>?)?.cast<String>() ?? <String>[];
    if (visited.contains(place.id)) {
      return PlaceVisitResult(created: false, unlockedAchievementIds: <String>[]);
    }

    await userRef.set({
      'visitedPlaces': FieldValue.arrayUnion([place.id]),
      'totalPlacesVisited': FieldValue.increment(1),
    }, SetOptions(merge: true));

    final afterSnap = await userRef.get();
    final afterData = afterSnap.data() ?? <String, dynamic>{};
    final afterVisited = (afterData['visitedPlaces'] as List<dynamic>?)?.cast<String>() ?? <String>[];
    final visitedCount = afterVisited.length;
    final summary = (afterData['achievementsSummary'] as Map<String, dynamic>?) ?? <String, dynamic>{};

    final achQuery = await _db.collection('achievements').where('type', isEqualTo: 'visit').get();
    final List<String> unlocked = <String>[];
    for (final achDoc in achQuery.docs) {
      final achId = achDoc.id;
      final criteria = achDoc.data()['criteria'] as Map<String, dynamic>? ?? {};
      final target = (criteria['target'] as num?)?.toInt() ?? 0;

      final already = summary[achId] == true;
      if (!already && target > 0 && visitedCount >= target) {
        unlocked.add(achId);
        await userRef.set({
          'achievementsSummary': {achId: true},
          'achievementsUnlockedAt': {achId: FieldValue.serverTimestamp()},
        }, SetOptions(merge: true));
      }
    }

    return PlaceVisitResult(created: true, unlockedAchievementIds: unlocked);
  }
}

/// Result returned by [reportPlaceVisit]
class PlaceVisitResult {
  final bool created;
  final List<String> unlockedAchievementIds;

  PlaceVisitResult({required this.created, required this.unlockedAchievementIds});
}
