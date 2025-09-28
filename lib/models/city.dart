//import 'package:cloud_firestore/cloud_firestore.dart';

class City {
  final String id;
  final String name;
  final double lat, lng;

  City({
    required this.id,
    required this.name,
    required this.lat,
    required this.lng
    });

  factory City.fromMap(String id, Map<String, dynamic> data) {
    final loc = data['location'] as Map<String, dynamic>; 
    return City(
      id: id,
      name: data['name'] as String,
      lat: (loc['lat'] as num).toDouble(),     
      lng: (loc['long'] as num).toDouble(),
    );
  }
}
