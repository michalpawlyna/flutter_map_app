import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

class UserLocationWidget extends StatefulWidget {
  final Stream<Position> positionStream;
  final double minAccuracyRadius;

  const UserLocationWidget({
    required this.positionStream,
    this.minAccuracyRadius = 25.0,
    Key? key,
  }) : super(key: key);

  @override
  State<UserLocationWidget> createState() => _UserLocationWidgetState();
}

class _UserLocationWidgetState extends State<UserLocationWidget> {
  late final Stream<Position> _mergedStream;

  @override
  void initState() {
    super.initState();
    _mergedStream = _createMergedStream();
  }

  Stream<Position> _createMergedStream() async* {
    try {
      final last = await Geolocator.getLastKnownPosition();
      if (last != null) {
        yield last;
        yield* widget.positionStream;
        return;
      }

      try {
        final current = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.low);
        yield current;
      } catch (_) {

      }
    } catch (_) {

    }

    yield* widget.positionStream;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Position>(
      stream: _mergedStream,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }

        final position = snapshot.data!;
        final latLng = LatLng(position.latitude, position.longitude);
        final accuracy = position.accuracy;
        final radius = max(widget.minAccuracyRadius, accuracy);

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
                  width: 12,
                  height: 12,
                  alignment: Alignment.center,
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
