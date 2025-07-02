import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../services/location_service.dart';

class UserLocationWidget extends StatefulWidget {
  final MapController mapController;
  final double accuracyRadius;

  const UserLocationWidget({
    required this.mapController,
    this.accuracyRadius = 25.0, // domyślnie 50 metrów
    Key? key,
  }) : super(key: key);

  @override
  _UserLocationWidgetState createState() => _UserLocationWidgetState();
}

class _UserLocationWidgetState extends State<UserLocationWidget> {
  LatLng? _position;

  @override
  void initState() {
    super.initState();
    _initLocation();
  }

  Future<void> _initLocation() async {
    try {
      final pos = await LocationService().getCurrentLocation();
      setState(() {
        _position = LatLng(pos.latitude, pos.longitude);
      });
    } catch (e) {
      debugPrint('Nie udało się pobrać lokalizacji: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_position == null) return const SizedBox.shrink();

    return Stack(
      children: [
        /// Okrąg precyzji w metrach (CircleLayer)
        CircleLayer(
          circles: [
            CircleMarker(
              point: _position!,
              useRadiusInMeter: true,
              radius: widget.accuracyRadius,
              color: Colors.blue.withOpacity(0.2),
              // borderStrokeWidth: 1,
              // borderColor: Colors.blue.withOpacity(0.4),
            ),
          ],
        ),
        /// Kropka (MarkerLayer)
        MarkerLayer(
          markers: [
            Marker(
              point: _position!,
              width: 20,
              height: 20,
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.blue,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
