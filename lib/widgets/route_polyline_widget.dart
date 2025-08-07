import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class RoutePolylineWidget extends StatelessWidget {
  final Polyline? polyline;

  const RoutePolylineWidget({Key? key, this.polyline}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (polyline == null) return const SizedBox.shrink();
    return PolylineLayer(polylines: [polyline!]);
  }
}
