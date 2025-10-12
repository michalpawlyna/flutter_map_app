import 'package:cloud_firestore/cloud_firestore.dart';

class Place {
  final String id;
  final String cityId;
  final String name;
  final String desc;
  final String address;
  final double lat, lng;
  final String? photoUrl;

  Place({
    required this.id,
    required this.cityId,
    required this.name,
    required this.desc,
    required this.address,
    required this.lat,
    required this.lng,
    this.photoUrl,
  });

  factory Place.fromMap(String id, Map<String, dynamic> data) {
    final geo = data['location'] as Map<String, dynamic>;
    final ref = data['cityRef'] as DocumentReference;
    return Place(
      id: id,
      cityId: ref.id,
      name: data['name'] as String,
      desc: data['desc'] as String? ?? '',
      address: data['address'] as String? ?? '',
      lat: (geo['lat'] as num).toDouble(),
      lng: (geo['long'] as num).toDouble(),
      photoUrl: data['photoUrl'] as String?,
    );
  }
}
