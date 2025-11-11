import 'package:flutter/material.dart';
import '../models/city.dart';
import '../services/firestore_service.dart';
import 'select_places_screen.dart';

class SelectCityScreen extends StatelessWidget {
  const SelectCityScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_sharp),
        onPressed: () => Navigator.of(context).maybePop(),
        tooltip: 'Powrót',
      ),
      title: const Text(
        'Wybierz miasto',
        style: TextStyle(
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
    backgroundColor: Colors.white,
    body: const _CitiesList(),
  );
}

class _CitiesList extends StatefulWidget {
  const _CitiesList({Key? key}) : super(key: key);

  @override
  State<_CitiesList> createState() => _CitiesListState();
}

class _CitiesListState extends State<_CitiesList> {
  final FirestoreService _fs = FirestoreService();
  late Future<void> _initFuture;
  List<City> _cities = [];
  final Map<String, int> _placesCount = {};

  @override
  void initState() {
    super.initState();
    _initFuture = _loadData();
  }

  Future<void> _loadData() async {
    final results = await Future.wait([
      _fs.getCities(),
      _fs.getAllPlaces(),
    ]);

    final cities = results[0] as List<City>;
    final places = results[1] as List<dynamic>;

    final Map<String, int> counts = {};
    for (final p in places) {
      // Place model sets cityId from DocumentReference.id
      try {
        final cityId = (p as dynamic).cityId as String?;
        if (cityId != null) {
          counts[cityId] = (counts[cityId] ?? 0) + 1;
        }
      } catch (_) {
        // ignore malformed place
      }
    }

    setState(() {
      _cities = cities;
      _placesCount.clear();
      _placesCount.addAll(counts);
    });
  }

  String _placesLabel(int count) {
    if (count == 1) return 'miejsce';
    final mod100 = count % 100;
    final mod10 = count % 10;
    if (mod100 >= 12 && mod100 <= 14) return 'miejsc';
    if (mod10 >= 2 && mod10 <= 4) return 'miejsca';
    return 'miejsc';
  }

  Future<void> _onCityTap(String cityId, String cityName) async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SelectPlacesScreen(
          cityId: cityId,
          cityName: cityName,
        ),
      ),
    );

    if (result != null) {
      Navigator.of(context).pop(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _initFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Błąd: ${snapshot.error}'));
        }

        if (_cities.isEmpty) {
          return const Center(child: Text('Brak miast w bazie'));
        }

        return ListView.separated(
          padding: const EdgeInsets.all(12),
          itemCount: _cities.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final c = _cities[index];
            final count = _placesCount[c.id] ?? 0;

            return InkWell(
              onTap: () => _onCityTap(c.id, c.name),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 18,
                ),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            c.name,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '$count ${_placesLabel(count)}',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 8),

                    Icon(
                      Icons.chevron_right,
                      color: Colors.grey.withOpacity(0.6),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}