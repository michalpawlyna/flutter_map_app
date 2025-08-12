// lib/widgets/user_location_widget.dart

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

class UserLocationWidget extends StatelessWidget {
  /// Strumień pozycji użytkownika, dostarczany z zewnątrz.
  final Stream<Position> positionStream;

  /// Minimalny promień rysowanego kręgu (jeśli GPS zwróci mniejszą wartość).
  final double minAccuracyRadius;

  const UserLocationWidget({
    required this.positionStream,
    this.minAccuracyRadius = 25.0,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Używamy StreamBuilder, który automatycznie nasłuchuje na strumieniu
    // i przebudowuje UI, gdy pojawią się nowe dane.
    return StreamBuilder<Position>(
      stream: positionStream,
      builder: (context, snapshot) {
        // Jeśli nie ma jeszcze danych (lub jest błąd), nie rysuj nic.
        // Dzięki zmianom w LocationService pierwszy event (current position)
        // powinien nadejść szybko — wtedy marker się pojawi.
        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }

        final position = snapshot.data!;
        final latLng = LatLng(position.latitude, position.longitude);
        final accuracy = position.accuracy;
        final radius = max(minAccuracyRadius, accuracy);

        return Stack(
          children: [
            // Accuracy circle
            CircleLayer(
              circles: [
                CircleMarker(
                  point: latLng,
                  useRadiusInMeter: true,
                  radius: radius,
                  color: Colors.blue.withOpacity(0.18),
                  borderStrokeWidth: 1.2,
                  borderColor: Colors.blueAccent,
                ),
              ],
            ),
            // User marker
            MarkerLayer(
              markers: [
                Marker(
                  point: latLng,
                  width: 36,
                  height: 36,
                  // DLA flutter_map >6: używamy child:, nie builder:
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.25),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.my_location,
                        size: 16,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}
