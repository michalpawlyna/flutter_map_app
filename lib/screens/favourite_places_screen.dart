import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../models/place.dart';
import 'select_city_screen.dart';
import 'login_screen.dart';

class FavouritePlacesScreen extends StatefulWidget {
  const FavouritePlacesScreen({Key? key}) : super(key: key);

  @override
  State<FavouritePlacesScreen> createState() => _FavouritePlacesScreenState();
}

class _FavouritePlacesScreenState extends State<FavouritePlacesScreen> {
  final AuthService _auth = AuthService();
  final CacheManager _cacheManager = DefaultCacheManager();

  String transformedCloudinaryUrl(
    String? url, {
    int width = 300,
    int? height,
    String crop = 'fill',
  }) {
    if (url == null || url.isEmpty) return '';
    const uploadSegment = '/upload/';
    final idx = url.indexOf(uploadSegment);
    if (idx == -1) return url;

    final parts = <String>[];
    parts.add('w_$width');
    if (height != null) parts.add('h_$height');
    if (crop.isNotEmpty) parts.add('c_$crop');
    parts.add('q_auto');
    parts.add('f_auto');

    final transformation = parts.join(',');
    return url.replaceFirst(uploadSegment, '$uploadSegment$transformation/');
  }

  Future<List<Place>> _fetchPlacesByIds(List<String> ids) async {
    if (ids.isEmpty) return <Place>[];
    final db = FirebaseFirestore.instance;
    final List<Place> res = [];

    for (final id in ids) {
      try {
        final doc = await db.collection('places').doc(id).get();
        if (doc.exists) {
          final data = doc.data() as Map<String, dynamic>;
          res.add(Place.fromMap(doc.id, data));
        }
      } catch (_) {

      }
    }

    return res;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: _auth.authStateChanges,
      builder: (context, authSnap) {
        final user = authSnap.data ?? _auth.currentUser;

        return Scaffold(
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_sharp),
              onPressed: () => Navigator.of(context).maybePop(),
              tooltip: 'Powrót',
            ),
            title: const Text(
              'Ulubione miejsca',
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.w600,
                fontSize: 20,
              ),
            ),
            centerTitle: true,
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
            elevation: 0,
          ),
          backgroundColor: Colors.white,
          body: Builder(builder: (context) {
            if (user == null) {

              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.person_off, size: 72, color: Colors.grey),
                      const SizedBox(height: 12),
                      const Text(
                        'Nie jesteś zalogowany',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Aby zobaczyć ulubione miejsca, zaloguj się.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 14, color: Colors.black54),
                      ),
                      const SizedBox(height: 18),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const LoginScreen()),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text('Zaloguj się'),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }


            final userDocStream = FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots();

            return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              stream: userDocStream,
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snap.hasError) {
                  return Center(child: Text('Błąd: ${snap.error}'));
                }

                final data = snap.data?.data() ?? <String, dynamic>{};
                final favs = (data['favouritePlaces'] as List<dynamic>?)?.cast<String>() ?? <String>[];

                if (favs.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.favorite_border, size: 72, color: Colors.grey),
                          const SizedBox(height: 12),
                          const Text(
                            'Brak ulubionych miejsc',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Nie dodałeś jeszcze żadnego miejsca do ulubionych.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 14, color: Colors.black54),
                          ),
                          const SizedBox(height: 18),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(builder: (_) => const SelectCityScreen()),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.black,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: const Text('Przeglądaj miejsca'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }


                return FutureBuilder<List<Place>>(
                  future: _fetchPlacesByIds(favs),
                  builder: (context, placesSnap) {
                    if (placesSnap.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (placesSnap.hasError) {
                      return Center(child: Text('Błąd: ${placesSnap.error}'));
                    }

                    final places = placesSnap.data ?? <Place>[];
                    if (places.isEmpty) {
                      return const Center(child: Text('Brak miejsc do wyświetlenia'));
                    }

                    return ListView.separated(
                      padding: const EdgeInsets.all(12),
                      itemCount: places.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final p = places[index];
                        final photoUrl = p.photoUrl ?? '';
                        final thumb = transformedCloudinaryUrl(photoUrl, width: 360);

                        return InkWell(
                          onTap: () {

                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color.fromARGB(255, 239, 240, 241),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.transparent, width: 1.2),
                            ),
                            child: Row(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: CachedNetworkImage(
                                    cacheManager: _cacheManager,
                                    imageUrl: thumb.isEmpty ? '' : thumb,
                                    width: 84,
                                    height: 84,
                                    fit: BoxFit.cover,
                                    placeholder: (c, s) => Container(
                                      width: 84,
                                      height: 84,
                                      color: Colors.grey.shade200,
                                    ),
                                    errorWidget: (c, s, e) => Container(
                                      width: 84,
                                      height: 84,
                                      color: Colors.grey.shade200,
                                      child: const Icon(Icons.image_not_supported, color: Colors.grey),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        p.name,
                                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        p.address,
                                        style: const TextStyle(fontSize: 13, color: Colors.black54),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            );
          }),
        );
      },
    );
  }
}
