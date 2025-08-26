// lib/widgets/route_polyline_widget.dart
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class RoutePolylineWidget extends StatelessWidget {
  final List<LatLng>? points;
  final double strokeWidth;
  final Color startColor;
  final Color endColor;

  const RoutePolylineWidget({
    Key? key,
    required this.points,
    this.strokeWidth = 4.0,
    this.startColor = const Color(0xFF9B7BFF),
    this.endColor = const Color(0xFFFD4A9A),
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (points == null || points!.length < 2) return const SizedBox.shrink();

    final pts = points!;
    final int nSegments = pts.length - 1;
    final List<Polyline> segments = <Polyline>[];

    for (int i = 0; i < nSegments; i++) {
      final t = nSegments <= 1 ? 0.0 : (i / (nSegments - 1));
      final color = Color.lerp(startColor, endColor, t) ?? startColor;
      segments.add(
        Polyline(
          points: [pts[i], pts[i + 1]],
          strokeWidth: strokeWidth,
          color: color,
        ),
      );
    }

    return PolylineLayer(polylines: segments);
  }
}
