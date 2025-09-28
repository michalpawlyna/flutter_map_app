import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../models/place.dart';
import '../services/firestore_service.dart';
import '../services/location_service.dart';
import '../services/route_service.dart';

class SelectPlacesScreen extends StatelessWidget {
  final String? cityId;
  final String cityName;

  const SelectPlacesScreen({
    Key? key,
    this.cityId,
    required this.cityName,
  }) : super(key: key);

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
          centerTitle: true,
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.black,
          elevation: 0,
        ),
        backgroundColor: Colors.grey[50],
        body: _PlacesList(cityId: cityId, cityName: cityName),
      );
}

class _PlacesList extends StatefulWidget {
  final String? cityId;
  final String cityName;

  const _PlacesList({Key? key, this.cityId, required this.cityName}) : super(key: key);

  @override
  State<_PlacesList> createState() => _PlacesListState();
}

class _PlacesListState extends State<_PlacesList> {
  final FirestoreService _fs = FirestoreService();
  late Future<List<Place>> _future;
  final List<String> _selectedPlaceIds = [];

  static const int maxSelection = 5;  //Max places

  @override
  void initState() {
    super.initState();
    if (widget.cityId != null && widget.cityId!.isNotEmpty) {
      _future = _fs.getPlacesForCity(widget.cityId!);
    } else {
      _future = _fs.getAllPlaces();
    }
  }

  void _toggleSelectionById(String id) {
    setState(() {
      if (_selectedPlaceIds.contains(id)) {
        _selectedPlaceIds.remove(id);
      } else {
        if (_selectedPlaceIds.length >= maxSelection) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Możesz wybrać maksymalnie $maxSelection miejsc')),
          );
          return;
        }
        _selectedPlaceIds.add(id);
      }
    });
  }

  MaterialColor _avatarColor(String key) {
    final hash = key.codeUnits.fold<int>(0, (p, n) => p + n);
    final colors = <MaterialColor>[
      Colors.teal,
      Colors.indigo,
      Colors.deepOrange,
      Colors.purple,
      Colors.blue,
      Colors.brown,
      Colors.cyan,
      Colors.green,
    ];
    return colors[hash % colors.length];
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
                return const Center(child: Text('Brak miejsc w wybranym mieście'));
              }

              return ListView.separated(
                padding: const EdgeInsets.all(12),
                itemCount: places.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final p = places[index];
                  final key = p.id;
                  final selected = _selectedPlaceIds.contains(key);
                  final avatarColor = _avatarColor(key);

                  return InkWell(
                    onTap: () => _toggleSelectionById(key),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      constraints: const BoxConstraints(minHeight: 90),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                      decoration: BoxDecoration(
                        color: selected ? Colors.grey[100] : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: selected ? Colors.black : Colors.grey.withOpacity(0.12),
                          width: selected ? 1.6 : 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.03),
                            blurRadius: selected ? 10 : 6,
                            offset: const Offset(0, 2),
                          )
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              color: avatarColor.shade100,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                p.name.isNotEmpty ? p.name[0].toUpperCase() : '?',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: avatarColor.shade700,
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
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  p.address.isNotEmpty ? p.address : (p.desc.isNotEmpty ? p.desc : ''),
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.black54,
                                    height: 1.3,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  height: 6,
                                  width: 60,
                                  decoration: BoxDecoration(
                                    color: avatarColor.shade100,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          Icon(
                            Icons.chevron_right,
                            color: selected ? Colors.black : Colors.grey.withOpacity(0.6),
                          ),
                        ],
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
              onPressed: _selectedPlaceIds.isEmpty
                  ? null
                  : () async {
                      final snapshotPlaces = await _future;
                      final selectedPlaces = snapshotPlaces
                          .where((p) => _selectedPlaceIds.contains(p.id))
                          .toList();
                      try {
                        final pos = await LocationService().getCurrentLocation();
                        final start = LatLng(pos.latitude, pos.longitude);

                        final List<Place> remaining = List.from(selectedPlaces);
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
                        waypoints.addAll(visitOrder.map((p) => LatLng(p.lat, p.lng)));

                        final route = await RouteService().getWalkingRouteFromWaypoints(waypoints);

                        Navigator.of(context).pop({
                          'route': route,
                          'places': visitOrder.map((p) => p.name).toList(),
                        });
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Błąd tworzenia trasy: ${e.toString()}')),
                        );
                      }
                    },
              icon: const Icon(Icons.route),
              label: const Text('Stwórz trasę'),
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
