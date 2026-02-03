import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

class UserLocationWidget extends StatefulWidget {
  final Stream<Position> positionStream;
  final double minAccuracyRadius;
  final double minMovementThreshold;
  final double smoothingFactor;

  const UserLocationWidget({
    required this.positionStream,
    this.minAccuracyRadius = 25.0,
    this.minMovementThreshold = 0.0,
    this.smoothingFactor = 0.3,
    Key? key,
  }) : super(key: key);

  @override
  State<UserLocationWidget> createState() => _UserLocationWidgetState();
}

class _UserLocationWidgetState extends State<UserLocationWidget> {
  late final Stream<Position> _mergedStream;
  Position? _lastPosition;

  @override
  void initState() {
    super.initState();
    _mergedStream = _createMergedStream();
  }

  double _calculateDistance(Position pos1, Position pos2) {
    const distance = Distance();
    return distance(
      LatLng(pos1.latitude, pos1.longitude),
      LatLng(pos2.latitude, pos2.longitude),
    );
  }

  Position _smoothPosition(Position newPosition, Position lastPosition) {
    final factor = widget.smoothingFactor;

    return Position(
      latitude:
          lastPosition.latitude +
          (newPosition.latitude - lastPosition.latitude) * factor,
      longitude:
          lastPosition.longitude +
          (newPosition.longitude - lastPosition.longitude) * factor,
      timestamp: newPosition.timestamp,
      accuracy:
          lastPosition.accuracy +
          (newPosition.accuracy - lastPosition.accuracy) * factor,
      altitude:
          lastPosition.altitude +
          (newPosition.altitude - lastPosition.altitude) * factor,
      altitudeAccuracy:
          lastPosition.altitudeAccuracy +
          (newPosition.altitudeAccuracy - lastPosition.altitudeAccuracy) *
              factor,
      heading:
          lastPosition.heading +
          (newPosition.heading - lastPosition.heading) * factor,
      headingAccuracy:
          lastPosition.headingAccuracy +
          (newPosition.headingAccuracy - lastPosition.headingAccuracy) * factor,
      speed:
          lastPosition.speed +
          (newPosition.speed - lastPosition.speed) * factor,
      speedAccuracy:
          lastPosition.speedAccuracy +
          (newPosition.speedAccuracy - lastPosition.speedAccuracy) * factor,
    );
  }

  Stream<Position> _createMergedStream() async* {
    try {
      final last = await Geolocator.getLastKnownPosition();
      if (last != null) {
        _lastPosition = last;
        yield last;
      }

      try {
        final current = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.low,
        );
        _lastPosition = current;
        yield current;
      } catch (_) {}
    } catch (_) {}

    await for (final position in widget.positionStream) {
      if (_lastPosition == null) {
        _lastPosition = position;
        yield position;
        continue;
      }

      final distance = _calculateDistance(position, _lastPosition!);

      if (distance >= widget.minMovementThreshold) {
        final smoothed = _smoothPosition(position, _lastPosition!);
        _lastPosition = position;
        yield smoothed;
      }
    }
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

        return MarkerLayer(
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
        );
      },
    );
  }
}
