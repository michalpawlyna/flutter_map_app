import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import '../models/place.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/tts_service.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import 'package:toastification/toastification.dart';
import 'shimmer_placeholder_widget.dart';

class PlaceDetailsSheet extends StatefulWidget {
  final Place place;
  final MapController? mapController;
  final Future<void> Function(Place)? onNavigate;

  const PlaceDetailsSheet({
    Key? key,
    required this.place,
    this.mapController,
    this.onNavigate,
  }) : super(key: key);

  @override
  State<PlaceDetailsSheet> createState() => _PlaceDetailsSheetState();
}

class _PlaceDetailsSheetState extends State<PlaceDetailsSheet> {
  bool _loading = false;
  late final TtsService _tts;
  late final CacheManager _imageCacheManager;
  final AuthService _auth = AuthService();
  final FirestoreService _firestore = FirestoreService();
  bool _isFavorited = false;
  bool _checkingFav = false;

  @override
  void initState() {
    super.initState();
    _tts = TtsService();
    _imageCacheManager = DefaultCacheManager();
    _initFavourite();
  }

  @override
  void dispose() {
    _tts.dispose();
    super.dispose();
  }

  Future<void> _initFavourite() async {
    final user = _auth.currentUser;
    if (user == null) return;
    setState(() => _checkingFav = true);
    try {
      final fav = await _firestore.isPlaceFavorited(user.uid, widget.place.id);
      if (mounted) setState(() => _isFavorited = fav);
    } catch (_) {}
    if (mounted) setState(() => _checkingFav = false);
  }

  Future<void> _toggleFavourite() async {
    final user = _auth.currentUser;
    if (user == null) return;

    setState(() => _checkingFav = true);
    try {
      if (_isFavorited) {
        await _firestore.removePlaceFromFavourites(user.uid, widget.place.id);
        if (mounted) setState(() => _isFavorited = false);
        toastification.show(
          context: context,
          title: const Text('Usunięto z ulubionych'),
          style: ToastificationStyle.flat,
          type: ToastificationType.success,
          autoCloseDuration: const Duration(seconds: 3),
          alignment: Alignment.bottomCenter,
          margin: const EdgeInsets.fromLTRB(12, 0, 12, 24),
        );
      } else {
        await _firestore.addPlaceToFavourites(user.uid, widget.place.id);
        if (mounted) setState(() => _isFavorited = true);
        toastification.show(
          context: context,
          title: const Text('Dodano do ulubionych'),
          style: ToastificationStyle.flat,
          type: ToastificationType.success,
          autoCloseDuration: const Duration(seconds: 3),
          alignment: Alignment.bottomCenter,
          margin: const EdgeInsets.fromLTRB(12, 0, 12, 24),
        );
      }
    } catch (e) {
      toastification.show(
        context: context,
        title: Text('Błąd: ${e.toString()}'),
        style: ToastificationStyle.flat,
        type: ToastificationType.error,
        autoCloseDuration: const Duration(seconds: 4),
        alignment: Alignment.bottomCenter,
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 24),
      );
    }
    if (mounted) setState(() => _checkingFav = false);
  }

  String _composeSpeechText() {
    final b = StringBuffer();
    b.write(widget.place.name);
    if (widget.place.desc.isNotEmpty) {
      b.write('. ');
      b.write(widget.place.desc);
    }
    return b.toString();
  }

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

  void _showFullImage(String? originalUrl) {
    final url = originalUrl ?? '';
    if (url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Brak zdjęcia do wyświetlenia')),
      );
      return;
    }

    final fullUrl = transformedCloudinaryUrl(url, width: 1200);

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.black,
          insetPadding: EdgeInsets.zero,
          child: Stack(
            children: [
              Positioned.fill(
                child: InteractiveViewer(
                  panEnabled: true,
                  boundaryMargin: const EdgeInsets.all(20),
                  minScale: 1.0,
                  maxScale: 5.0,
                  child: Center(
                    child: CachedNetworkImage(
                      imageUrl: fullUrl,
                      cacheManager: _imageCacheManager,
                      fadeInDuration: const Duration(milliseconds: 320),
                      placeholder: (context, url) => Center(
                        child: ShimmerPlaceholder(
                          width: double.infinity,
                          height: 300,
                        ),
                      ),
                      errorWidget: (context, url, error) => const Center(
                        child: Icon(
                          Icons.broken_image,
                          color: Colors.white,
                          size: 48,
                        ),
                      ),
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),

              Positioned(
                top: 32,
                right: 16,
                child: SafeArea(
                  child: IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final String originalPhotoUrl = widget.place.photoUrl ?? '';
    final String thumbUrl = transformedCloudinaryUrl(
      originalPhotoUrl,
      width: 360,
    );

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              InkWell(
                onTap: () => _showFullImage(originalPhotoUrl),
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  clipBehavior: Clip.hardEdge,
                  child: thumbUrl.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: thumbUrl,
                          cacheManager: _imageCacheManager,
                          width: 56,
                          height: 56,
                          fit: BoxFit.cover,
                          fadeInDuration: const Duration(milliseconds: 300),
                          placeholder: (context, url) => const ShimmerPlaceholder(
                            width: 56,
                            height: 56,
                            borderRadius: BorderRadius.all(Radius.circular(6)),
                          ),
                          errorWidget: (context, url, error) => Container(
                            color: Colors.grey.shade200,
                            alignment: Alignment.center,
                            child: const Icon(Icons.broken_image, color: Colors.grey),
                          ),
                        )
                      : Container(
                          color: Colors.grey.shade200,
                          alignment: Alignment.center,
                          child: const Icon(Icons.photo, color: Colors.grey),
                        ),
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.place.name,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 3),
                    if (widget.place.address.isNotEmpty)
                      Text(
                        widget.place.address,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                  ],
                ),
              ),
              if (_auth.currentUser != null)
                Padding(
                  padding: const EdgeInsets.only(left: 8.0),
                  child: SizedBox(
                    width: 44,
                    height: 44,
                    child: _checkingFav
                        ? const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)))
                        : IconButton(
                            onPressed: _toggleFavourite,
                            icon: Icon(
                              _isFavorited ? Icons.favorite : Icons.favorite_border,
                              color: _isFavorited ? Colors.red : Colors.black54,
                            ),
                          ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          // Visited badge: visible only for logged-in users and when the
          // user's `visitedPlaces` contains this place id.
          if (_auth.currentUser != null)
            StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(_auth.currentUser!.uid)
                  .snapshots(),
              builder: (context, userSnap) {
                final data = userSnap.data?.data() ?? <String, dynamic>{};
                final visited = (data['visitedPlaces'] as List<dynamic>?)?.cast<String>() ?? <String>[];
                final bool isVisited = visited.contains(widget.place.id);
                if (!isVisited) return const SizedBox.shrink();

                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.lightBlue[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check, color: Colors.blue.shade800, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        'Odwiedzono',
                        style: TextStyle(
                          color: Colors.blue.shade800,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          const Text(
            'O miejscu',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          if (widget.place.desc.isNotEmpty)
            Text(
              widget.place.desc,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black54,
                height: 1.4,
              ),
            ),
          const SizedBox(height: 20),

          Row(
            children: [
              SizedBox(
                width: 44,
                height: 44,
                child: ValueListenableBuilder<bool>(
                  valueListenable: _tts.isSpeaking,
                  builder: (context, speaking, _) {
                    return OutlinedButton(
                      onPressed: () async {
                        final text = _composeSpeechText();
                        await _tts.toggle(text);
                      },
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        side: BorderSide(color: Colors.black.withOpacity(0.08)),
                        backgroundColor: Colors.grey.shade100,
                        foregroundColor: Colors.black87,
                      ),
                      child: Icon(speaking ? Icons.stop : Icons.volume_up),
                    );
                  },
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: ElevatedButton.icon(
                  onPressed:
                      _loading
                          ? null
                          : () async {
                            if (widget.onNavigate != null) {
                              setState(() => _loading = true);
                              await widget.onNavigate!(widget.place);
                              if (mounted) setState(() => _loading = false);
                            }
                          },
                  icon:
                      _loading
                          ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                          : const Icon(Icons.navigation),
                  label: Text(_loading ? 'Tworzenie trasy...' : 'Nawiguj'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  static void show(
    BuildContext context,
    Place place, {
    MapController? mapController,
    Future<void> Function(Place)? onNavigate,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => PlaceDetailsSheet(
            place: place,
            mapController: mapController,
            onNavigate: onNavigate,
          ),
    );
  }
}
