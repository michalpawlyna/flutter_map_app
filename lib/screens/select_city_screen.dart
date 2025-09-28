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
        backgroundColor: Colors.grey[50],
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
  late Future<List<City>> _future;
  String? _selectedCityId;
  String? _selectedCityName;

  @override
  void initState() {
    super.initState();
    _future = _fs.getCities();
  }

  Future<void> _onNext() async {
    if (_selectedCityId == null) return;
    final result = await Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => SelectPlacesScreen(
        cityId: _selectedCityId!,
        cityName: _selectedCityName ?? '',
      ),
    ));

    if (result != null) {
      Navigator.of(context).pop(result);
    }
  }

  MaterialColor _avatarColor(String id) {
    final hash = id.codeUnits.fold<int>(0, (p, n) => p + n);
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
          child: FutureBuilder<List<City>>(
            future: _future,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(child: Text('Błąd: ${snapshot.error}'));
              }

              final cities = snapshot.data ?? [];
              if (cities.isEmpty) {
                return const Center(child: Text('Brak miast w bazie'));
              }

              return ListView.separated(
                padding: const EdgeInsets.all(12),
                itemCount: cities.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final c = cities[index];
                  final selected = _selectedCityId == c.id;

                  return InkWell(
                    onTap: () {
                      setState(() {
                        _selectedCityId = c.id;
                        _selectedCityName = c.name;
                      });
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      constraints: const BoxConstraints(minHeight: 80),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 16,
                      ),
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
                              color: _avatarColor(c.id).shade100,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                c.name.isNotEmpty ? c.name[0].toUpperCase() : '?',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: _avatarColor(c.id).shade700,
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
                                  c.name,
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Container(
                                  height: 6,
                                  width: 60,
                                  decoration: BoxDecoration(
                                    color: _avatarColor(c.id).shade100,
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
              onPressed: _selectedCityId == null ? null : _onNext,
              icon: const Icon(Icons.map_outlined),
              label: const Text('Dalej'),
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
