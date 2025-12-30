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

  InputDecoration _fieldDecoration({required String label, Widget? suffix}) {
    return InputDecoration(
      filled: true,
      fillColor: Colors.white,
      labelText: label,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
      suffixIcon: suffix,
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
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 12),

            LayoutBuilder(
              builder: (context, constraints) {
                return PopupMenuButton<TransportMode>(
                  position: PopupMenuPosition.under,

                  constraints: BoxConstraints.tightFor(
                    width: constraints.maxWidth,
                  ),

                  offset: const Offset(0, 4),
                  color: Colors.white,
                  surfaceTintColor: Colors.white,
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  tooltip: 'Wybierz sposób poruszania',
                  initialValue: _mode,

                  child: InputDecorator(
                    decoration: _fieldDecoration(
                      label: 'Wybierz sposób poruszania',

                      suffix: const Icon(Icons.expand_more),
                    ),
                    child: Row(
                      children: [
                        Icon(_getIcon(_mode), color: Colors.black87),
                        const SizedBox(width: 12),
                        Text(
                          _getLabel(_mode),
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),

                  onSelected: (TransportMode mode) async {
                    await _saveMode(mode);
                    setState(() => _mode = mode);
                  },
                  itemBuilder: (BuildContext context) {
                    return TransportMode.values.map((mode) {
                      return PopupMenuItem<TransportMode>(
                        value: mode,
                        child: Row(
                          children: [
                            Icon(_getIcon(mode), color: Colors.black87),
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
                    }).toList();
                  },
                );
              },
            ),

            const SizedBox(height: 8),
          ],
        ),
      ),
    ),
  );
}
