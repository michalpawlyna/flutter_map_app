// lib/widgets/user_location_widget.dart

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

class UserLocationWidget extends StatelessWidget {
  final Stream<Position> positionStream;
  final double minAccuracyRadius;

  const UserLocationWidget({
    required this.positionStream,
    this.minAccuracyRadius = 25.0,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Position>(
      stream: positionStream,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }

        final position = snapshot.data!;
        final latLng = LatLng(position.latitude, position.longitude);
        final accuracy = position.accuracy;
        final radius = max(minAccuracyRadius, accuracy);

        return Stack(
          children: [
            CircleLayer(
              circles: [
                CircleMarker(
                  point: latLng,
                  useRadiusInMeter: true,
                  radius: radius,
                  color: Colors.blue.withOpacity(0.18),
                ),
              ],
            ),
            MarkerLayer(
              markers: [
                Marker(
                  point: latLng,
                  width: 16,
                  height: 16,
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
      },
    );
  }
}