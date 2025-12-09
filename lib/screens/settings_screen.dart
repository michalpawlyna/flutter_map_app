import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum TransportMode { foot, bike, car }

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  static const _prefsKeyTransport = 'transport_mode';

  TransportMode _mode = TransportMode.foot;

  @override
  void initState() {
    super.initState();
    _loadMode();
  }

  Future<void> _loadMode() async {
    final prefs = await SharedPreferences.getInstance();
    final val = prefs.getString(_prefsKeyTransport);
    setState(() {
      _mode = _fromStringValue(val);
    });
  }

  Future<void> _saveMode(TransportMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKeyTransport, _stringOf(mode));
  }

  String _stringOf(TransportMode mode) {
    switch (mode) {
      case TransportMode.foot:
        return 'foot-walking';
      case TransportMode.bike:
        return 'cycling-regular';
      case TransportMode.car:
        return 'driving-car';
    }
  }

  TransportMode _fromStringValue(String? s) {
    switch (s) {
      case 'cycling-regular':
        return TransportMode.bike;
      case 'driving-car':
        return TransportMode.car;
      case 'foot-walking':
      default:
        return TransportMode.foot;
    }
  }

  IconData _getIcon(TransportMode mode) {
    switch (mode) {
      case TransportMode.foot:
        return Icons.directions_walk;
      case TransportMode.bike:
        return Icons.directions_bike;
      case TransportMode.car:
        return Icons.directions_car;
    }
  }

  String _getLabel(TransportMode mode) {
    switch (mode) {
      case TransportMode.foot:
        return 'Pieszo';
      case TransportMode.bike:
        return 'Rower';
      case TransportMode.car:
        return 'Samochód';
    }
  }

  // Dekoracja pola zgodna ze stylem z ProfileScreen
  InputDecoration _fieldDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.black54),
      filled: true,
      fillColor: const Color.fromARGB(255, 239, 240, 241),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.black, width: 1),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_sharp),
            onPressed: () => Navigator.of(context).maybePop(),
            tooltip: 'Powrót',
          ),
          title: const Text(
            'Ustawienia',
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
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Section title
                const Text(
                  'Sposób poruszania',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),

                // Exposed dropdown styled like text inputs from ProfileScreen
                DropdownButtonFormField<TransportMode>(
                  value: _mode,
                  decoration: _fieldDecoration('Wybierz sposób poruszania'),
                  isExpanded: true,
                  icon: const Icon(Icons.expand_more),
                  dropdownColor: Colors.white,
                  menuMaxHeight: 300,
                  items: TransportMode.values.map((mode) {
                    return DropdownMenuItem<TransportMode>(
                      value: mode,
                      child: Row(
                        children: [
                          Icon(_getIcon(mode)),
                          const SizedBox(width: 12),
                          Text(
                            _getLabel(mode),
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (mode) async {
                    if (mode == null) return;
                    await _saveMode(mode);
                    setState(() => _mode = mode);
                  },
                ),
              ],
            ),
          ),
        ),
      );
}