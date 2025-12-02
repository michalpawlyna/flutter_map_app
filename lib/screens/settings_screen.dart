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

  Widget _buildTransportPill(TransportMode mode) {
    final isSelected = _mode == mode;
    return Expanded(
      child: GestureDetector(
        onTap: () async {
          await _saveMode(mode);
          setState(() => _mode = mode);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? Colors.black : const Color(0xFFF8F9FA),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? Colors.black : Colors.grey.shade200,
              width: 1.5,
            ),
            boxShadow: [
              if (isSelected)
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                )
              else
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _getIcon(mode),
                color: isSelected ? Colors.white : Colors.black87,
                size: 24,
              ),
              const SizedBox(height: 6),
              Text(
                _getLabel(mode),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ),
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
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Sposób poruszania',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 16),

                    Row(
                      children: [
                        _buildTransportPill(TransportMode.foot),
                        const SizedBox(width: 12),
                        _buildTransportPill(TransportMode.bike),
                        const SizedBox(width: 12),
                        _buildTransportPill(TransportMode.car),
                      ],
                    ),

                    const SizedBox(height: 32),


                    Row(
                      children: const [
                        Expanded(child: Divider()),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8),
                          child: Text("Więcej wkrótce"),
                        ),
                        Expanded(child: Divider()),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
}