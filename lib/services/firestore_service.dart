import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/city.dart';
import '../models/place.dart';

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

  // -- Favourite places helpers ------------------------------------------------
  /// Checks whether [placeId] is present in the user's `favouritePlaces` array.
  Future<bool> isPlaceFavorited(String uid, String placeId) async {
    final doc = await _db.collection('users').doc(uid).get();
    final data = doc.data();
    final favs = (data == null)
        ? <String>[]
        : (data['favouritePlaces'] as List<dynamic>?)?.cast<String>() ?? <String>[];
    return favs.contains(placeId);
  }

  /// Adds [placeId] to users/{uid}.favouritePlaces using arrayUnion.
  Future<void> addPlaceToFavourites(String uid, String placeId) async {
    await _db.collection('users').doc(uid).set(
      {
        'favouritePlaces': FieldValue.arrayUnion([placeId]),
      },
      SetOptions(merge: true),
    );
  }

  /// Removes [placeId] from users/{uid}.favouritePlaces using arrayRemove.
  Future<void> removePlaceFromFavourites(String uid, String placeId) async {
    await _db.collection('users').doc(uid).set(
      {
        'favouritePlaces': FieldValue.arrayRemove([placeId]),
      },
      SetOptions(merge: true),
    );
  }
}
