import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:geolocator/geolocator.dart';

import '../models/place.dart';
import '../services/firestore_service.dart';
import '../services/location_service.dart';
import '../services/route_service.dart';
import '../widgets/shimmer_placeholder_widget.dart';

class SelectPlacesScreen extends StatefulWidget {
  final String? cityId;
  final String cityName;

  const SelectPlacesScreen({Key? key, this.cityId, required this.cityName})
      : super(key: key);

  @override
  State<SelectPlacesScreen> createState() => _SelectPlacesScreenState();
}

class _SelectPlacesScreenState extends State<SelectPlacesScreen> {
  final List<String> _selectedPlaceIds = [];
  static const int maxSelection = 5;

  void _updateSelection(List<String> ids) {
    setState(() {
      _selectedPlaceIds.clear();
      _selectedPlaceIds.addAll(ids);
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_sharp),
            onPressed: () => Navigator.of(context).maybePop(),
            tooltip: 'Powrót',
          ),
          title: Text(
            'Wybierz miejsca',
            style: const TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.w600,
              fontSize: 20,
            ),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Text(
                  '${_selectedPlaceIds.length}/$maxSelection',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ),
            ),
          ],
          centerTitle: true,
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.black,
          elevation: 0,
        ),
        backgroundColor: Colors.white,
        body: _PlacesList(
          cityId: widget.cityId,
          cityName: widget.cityName,
          selectedPlaceIds: _selectedPlaceIds,
          onSelectionChanged: _updateSelection,
        ),
      );
}

class _PlacesList extends StatefulWidget {
  final String? cityId;
  final String cityName;
  final List<String> selectedPlaceIds;
  final Function(List<String>) onSelectionChanged;

  const _PlacesList({
    Key? key,
    this.cityId,
    required this.cityName,
    required this.selectedPlaceIds,
    required this.onSelectionChanged,
  }) : super(key: key);

  @override
  State<_PlacesList> createState() => _PlacesListState();
}

class _PlacesListState extends State<_PlacesList> {
  final FirestoreService _fs = FirestoreService();
  late Future<List<Place>> _future;
  final CacheManager _imageCacheManager = DefaultCacheManager();

  LatLng? _currentLocation;

  bool _loading = false;

  static const int maxSelection = 5;

  @override
  void initState() {
    super.initState();
    if (widget.cityId != null && widget.cityId!.isNotEmpty) {
      _future = _fs.getPlacesForCity(widget.cityId!);
    } else {
      _future = _fs.getAllPlaces();
    }

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        await LocationService().ensureLocationEnabledAndPermitted();

        final Position? last = await Geolocator.getLastKnownPosition();
        final Position pos = last ??
            await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);

        if (mounted) {
          setState(() {
            _currentLocation = LatLng(pos.latitude, pos.longitude);
          });
        }
      } catch (_) {
        // ignore
      }
    });
  }

  void _toggleSelectionById(String id) {
    final newSelection = List<String>.from(widget.selectedPlaceIds);
    if (newSelection.contains(id)) {
      newSelection.remove(id);
    } else {
      if (newSelection.length >= maxSelection) {
        return;
      }
      newSelection.add(id);
    }
    widget.onSelectionChanged(newSelection);
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

  String _formatDistance(double meters) {
    if (meters < 1000) {
      return '${meters.round()} m';
    }
    final km = (meters / 1000);
    return '${km.toStringAsFixed(1)} km';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: FutureBuilder<List<Place>>(
            future: _future,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(child: Text('Błąd: ${snapshot.error}'));
              }

              final places = snapshot.data ?? [];
              if (places.isEmpty) {
                return const Center(
                  child: Text('Brak miejsc w wybranym mieście'),
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.all(12),
                itemCount: places.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final p = places[index];
                  final key = p.id;
                  final selected = widget.selectedPlaceIds.contains(key);
                  final canSelect = selected || widget.selectedPlaceIds.length < maxSelection;

                  final photoUrl = p.photoUrl ?? '';
                  final thumbUrl = transformedCloudinaryUrl(photoUrl, width: 360);

                  double? distanceMeters;
                  if (_currentLocation != null) {
                    try {
                      final dist = Distance();
                      distanceMeters = dist(
                        _currentLocation!,
                        LatLng(p.lat, p.lng),
                      );
                    } catch (_) {
                      distanceMeters = null;
                    }
                  }

                  return Opacity(
                    opacity: canSelect ? 1.0 : 0.5,
                    child: InkWell(
                      onTap: canSelect ? () => _toggleSelectionById(key) : null,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        constraints: const BoxConstraints(minHeight: 90),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Container(
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(
                                color: Colors.grey[300],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              clipBehavior: Clip.hardEdge,
                              child: photoUrl.isNotEmpty
                                  ? CachedNetworkImage(
                                      imageUrl: thumbUrl,
                                      cacheManager: _imageCacheManager,
                                      width: 52,
                                      height: 52,
                                      fit: BoxFit.cover,
                                      fadeInDuration:
                                          const Duration(milliseconds: 300),
                                      placeholder: (context, url) => const ShimmerPlaceholder(
                                        width: 52,
                                        height: 52,
                                        borderRadius: BorderRadius.all(Radius.circular(8)),
                                      ),
                                      errorWidget: (context, url, error) => Container(
                                        color: Colors.grey[300],
                                        alignment: Alignment.center,
                                        child: const Icon(Icons.broken_image, color: Colors.grey),
                                      ),
                                    )
                                  : Center(
                                      child: Text(
                                        p.name.isNotEmpty ? p.name[0].toUpperCase() : '?',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ),
                            ),

                            const SizedBox(width: 14),

                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    p.name,
                                    style: const TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  
                                  if (distanceMeters != null)
                                    Text(
                                      _formatDistance(distanceMeters),
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: Colors.black54,
                                      ),
                                    ),
                                ],
                              ),
                            ),

                            const SizedBox(width: 8),

                            Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: selected ? Colors.black : Colors.transparent,
                                border: Border.all(
                                  color: selected ? Colors.black : Colors.grey,
                                  width: 2,
                                ),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: selected
                                  ? const Icon(
                                      Icons.check,
                                      size: 16,
                                      color: Colors.white,
                                    )
                                  : null,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),

        SafeArea(
          minimum: const EdgeInsets.all(12),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: (widget.selectedPlaceIds.isEmpty || _loading)
                  ? null
                  : () async {
                      setState(() => _loading = true);
                      try {
                        final snapshotPlaces = await _future;
                        final selectedPlaces = snapshotPlaces
                            .where((p) => widget.selectedPlaceIds.contains(p.id))
                            .toList();
                        await LocationService().ensureLocationEnabledAndPermitted();
                        Position? pos = await Geolocator.getLastKnownPosition();
                        if (pos == null) {
                          pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
                        }
                        final start = LatLng(pos.latitude, pos.longitude);

                        final List<Place> remaining = List.from(
                          selectedPlaces,
                        );
                        final List<Place> visitOrder = [];
                        LatLng current = start;
                        final Distance dist = Distance();

                        while (remaining.isNotEmpty) {
                          remaining.sort((a, b) {
                            final da = dist(current, LatLng(a.lat, a.lng));
                            final db = dist(current, LatLng(b.lat, b.lng));
                            return da.compareTo(db);
                          });
                          final next = remaining.removeAt(0);
                          visitOrder.add(next);
                          current = LatLng(next.lat, next.lng);
                        }

                        final waypoints = <LatLng>[start];
                        waypoints.addAll(
                          visitOrder.map((p) => LatLng(p.lat, p.lng)),
                        );

                        final route = await RouteService()
                            .getWalkingRouteFromWaypoints(waypoints);

                        if (mounted) {
                          Navigator.of(context).pop({
                            'route': route,
                            'places': visitOrder
                                .map((p) => {
                                      'id': p.id,
                                      'name': p.name,
                                      'photoUrl': p.photoUrl ?? '',
                                    })
                                .toList(),
                          });
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Błąd tworzenia trasy: ${e.toString()}',
                              ),
                            ),
                          );
                        }
                      } finally {
                        if (mounted) setState(() => _loading = false);
                      }
                    },
              icon: _loading
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.5,
                      ),
                    )
                  : const Icon(Icons.route),
              label: Text(_loading ? 'Tworzenie trasy...' : 'Stwórz trasę'),
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
        ),
      ],
    );
  }
}