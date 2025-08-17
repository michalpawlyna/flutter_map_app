import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map_animations/flutter_map_animations.dart';
import '../services/location_service.dart';

class CenterOnUserButton extends StatelessWidget {
  final AnimatedMapController mapController;
  final double zoom;

  const CenterOnUserButton({
    Key? key,
    required this.mapController,
    this.zoom = 16.0,
  }) : super(key: key);

  Future<void> _centerImmediately() async {
    // 1) Spróbuj pobrać ostatnią znaną pozycję
    final last = await Geolocator.getLastKnownPosition();
    if (last != null) {
      // Użyj animateTo zamiast move dla płynnej animacji
      mapController.animateTo(
        dest: LatLng(last.latitude, last.longitude),
        zoom: zoom,
      );
    }
    // 2) Równolegle pobierz dokładną lokalizację
    try {
      final pos = await LocationService().getCurrentLocation();
      // sprawdź, czy znacząco się zmieniła (np. >5 m)
      if (last == null ||
          Geolocator.distanceBetween(
                last.latitude, last.longitude,
                pos.latitude, pos.longitude,
              ) >
              5) {
        // Użyj animateTo zamiast move dla płynnej animacji
        mapController.animateTo(
          dest: LatLng(pos.latitude, pos.longitude),
          zoom: zoom,
        );
      }
    } catch (_) {
      // ignoruj — zostaliśmy już gdzieś wycentrowani
    }
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 16,
      right: 16,
      child: SafeArea(
        child: GestureDetector(
          onTap: _centerImmediately,
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: const Icon(
              Icons.my_location,
              color: Colors.black,
              size: 24,
            ),
          ),
        ),
      ),
    );
  }
}