import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/city.dart';
import '../models/place.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Pobiera wszystkie miasta
  Future<List<City>> getCities() async {
    final snap = await _db.collection('cities').get();
    return snap.docs
      .map((d) => City.fromMap(d.id, d.data()))
      .toList();
  }

  /// Pobiera wszystkie miejsca z kolekcji root „places”
  Future<List<Place>> getAllPlaces() async {
    final snap = await _db.collection('places').get();
    return snap.docs
      .map((d) => Place.fromMap(d.id, d.data()))
      .toList();
  }

  /// Jeśli chcesz filtrować miejsca po mieście
  Future<List<Place>> getPlacesForCity(String cityId) async {
    final snap = await _db
      .collection('places')
      .where('cityRef', isEqualTo: _db.doc('cities/$cityId'))
      .get();

    return snap.docs
      .map((d) => Place.fromMap(d.id, d.data()))
      .toList();
  }
}
