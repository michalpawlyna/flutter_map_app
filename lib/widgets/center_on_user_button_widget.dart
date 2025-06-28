import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../services/location_service.dart';

class CenterOnUserButton extends StatelessWidget {
  final MapController mapController;
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
      mapController.move(
        LatLng(last.latitude, last.longitude),
        zoom,
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
        mapController.move(
          LatLng(pos.latitude, pos.longitude),
          zoom,
        );
      }
    } catch (_) {
      // ignoruj — zostaliśmy już gdzieś wycentrowani
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 76,
      right: 16,
      child: GestureDetector(
        onTap: _centerImmediately,
        child: Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.grey.shade200,
              width: 1,
            ),
          ),
          alignment: Alignment.center,
          child: const Icon(
            Icons.my_location,
            color: Colors.black,
            size: 24,
          ),
        ),
      ),
    );
  }
}