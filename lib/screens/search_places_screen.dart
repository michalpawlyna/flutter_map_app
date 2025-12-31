import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

import '../models/place.dart';

class SearchPlacesScreen extends StatefulWidget {
  const SearchPlacesScreen({Key? key}) : super(key: key);

  @override
  State<SearchPlacesScreen> createState() => _SearchPlacesScreenState();
}

class _SearchPlacesScreenState extends State<SearchPlacesScreen> {
  final TextEditingController _controller = TextEditingController();
  final CacheManager _cacheManager = DefaultCacheManager();
  List<Place> _results = [];
  bool _loading = false;

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

  Future<void> _search(String q) async {
    final query = (q ?? '').trim();
    if (query.isEmpty) {
      setState(() {
        _results = [];
        _loading = false;
      });
      return;
    }

    setState(() => _loading = true);

    try {
      final db = FirebaseFirestore.instance;

      final snap = await db.collection('places').limit(200).get();

      final qlow = query.toLowerCase();
      final list = <Place>[];
      for (final doc in snap.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final p = Place.fromMap(doc.id, data);
        final name = p.name.toLowerCase();
        if (name.startsWith(qlow)) list.add(p);
      }

      if (mounted) setState(() => _results = list);
    } catch (e) {
      if (mounted) setState(() => _results = []);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_sharp),
          onPressed: () => Navigator.of(context).maybePop(),
          tooltip: 'Powrót',
        ),
        title: const Text(
          'Wyszukaj miejsce',
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
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextFormField(
              controller: _controller,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                labelText: 'Szukaj',
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 18,
                ),
                border: const OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.black12),
                ),
                enabledBorder: const OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.black12),
                ),
                focusedBorder: const OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.black, width: 2),
                ),
                floatingLabelStyle: const TextStyle(color: Colors.black),
                suffixIcon:
                    _controller.text.isNotEmpty
                        ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _controller.clear();
                            _search('');
                          },
                          tooltip: 'Wyczyść',
                          splashRadius: 18,
                          constraints: const BoxConstraints(
                            minWidth: 40,
                            minHeight: 40,
                          ),
                        )
                        : null,
              ),
              onChanged: (v) => _search(v),
            ),
            const SizedBox(height: 12),
            Expanded(
              child:
                  _loading
                      ? const Center(child: CircularProgressIndicator())
                      : _results.isEmpty
                      ? const Center(child: Text('Brak wyników'))
                      : ListView.separated(
                        itemCount: _results.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final p = _results[index];
                          final photoUrl = p.photoUrl ?? '';
                          final thumb = transformedCloudinaryUrl(
                            photoUrl,
                            width: 360,
                          );

                          return InkWell(
                            onTap: () {
                              Navigator.of(
                                context,
                              ).pop(<String, dynamic>{'placeId': p.id});
                            },
                            borderRadius: BorderRadius.circular(4),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.black12,
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: SizedBox(
                                      width: 64,
                                      height: 64,
                                      child:
                                          thumb.isEmpty
                                              ? Container(
                                                color: Colors.grey[200],
                                              )
                                              : CachedNetworkImage(
                                                imageUrl: thumb,
                                                fit: BoxFit.cover,
                                                cacheManager: _cacheManager,
                                                placeholder:
                                                    (c, u) => Container(
                                                      color: Colors.grey[200],
                                                    ),
                                                errorWidget:
                                                    (c, u, e) => Container(
                                                      color: Colors.grey[200],
                                                    ),
                                              ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          p.name,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        if (p.address.isNotEmpty)
                                          Text(
                                            p.address,
                                            style: const TextStyle(
                                              fontSize: 13,
                                              color: Colors.black54,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  const Icon(
                                    Icons.chevron_right,
                                    color: Colors.black38,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
            ),
          ],
        ),
      ),
    );
  }
}
