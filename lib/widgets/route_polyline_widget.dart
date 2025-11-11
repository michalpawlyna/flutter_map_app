import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class RoutePolylineWidget extends StatefulWidget {
  final List<LatLng>? points;
  final double strokeWidth;
  final Color startColor;
  final Color endColor;
  final bool animate;
  final Duration? duration;

  const RoutePolylineWidget({
    Key? key,
    required this.points,
    this.strokeWidth = 3.0,
    this.startColor = const Color(0xFF9B7BFF),
    this.endColor = const Color(0xFFFD4A9A),
    this.animate = true,
    this.duration,
  }) : super(key: key);

  @override
  State<RoutePolylineWidget> createState() => _RoutePolylineWidgetState();
}

class _RoutePolylineWidgetState extends State<RoutePolylineWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this);
    _anim = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _startIfNeeded();
  }

  @override
  void didUpdateWidget(covariant RoutePolylineWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldPts = oldWidget.points;
    final newPts = widget.points;
    if (!_listEqualsLatLng(oldPts, newPts)) {
      _startIfNeeded();
    }
  }

  bool _listEqualsLatLng(List<LatLng>? a, List<LatLng>? b) {
    if (a == null && b == null) return true;
    if (a == null || b == null) return false;
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i].latitude != b[i].latitude || a[i].longitude != b[i].longitude) return false;
    }
    return true;
  }

  void _startIfNeeded() {
    final pts = widget.points;
    if (pts == null || pts.length < 2 || !widget.animate) {
      _controller.stop();
      _controller.value = widget.animate ? 0.0 : 1.0;
      return;
    }

    final nSegments = pts.length - 1;
    final intSegments = nSegments;
  final computedMs = (intSegments * 40) + 400;
  final ms = widget.duration?.inMilliseconds ?? computedMs.clamp(600, 3000);
  _controller.duration = Duration(milliseconds: ms);
    _controller.reset();
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final points = widget.points;
    if (points == null || points.length < 2) return const SizedBox.shrink();

    if (!widget.animate) {
      final pts = points;
      final int nSegments = pts.length - 1;
      final List<Polyline> segments = <Polyline>[];

      for (int i = 0; i < nSegments; i++) {
        final t = nSegments <= 1 ? 0.0 : (i / (nSegments - 1));
        final color = Color.lerp(widget.startColor, widget.endColor, t) ?? widget.startColor;
        segments.add(
          Polyline(
            points: [pts[i], pts[i + 1]],
            strokeWidth: widget.strokeWidth,
            color: color,
          ),
        );
      }

      return PolylineLayer(polylines: segments);
    }

    return AnimatedBuilder(
      animation: _anim,
      builder: (context, child) {
        final pts = points;
        final nSegments = pts.length - 1;
        final progress = _anim.value.clamp(0.0, 1.0);
        final total = progress * nSegments;
        final full = total.floor();
        final frac = total - full;

        final List<Polyline> segments = <Polyline>[];
        for (int i = 0; i < full; i++) {
          final t = nSegments <= 1 ? 0.0 : (i / (nSegments - 1));
          final color = Color.lerp(widget.startColor, widget.endColor, t) ?? widget.startColor;
          segments.add(
            Polyline(
              points: [pts[i], pts[i + 1]],
              strokeWidth: widget.strokeWidth,
              color: color,
            ),
          );
        }

        if (full < nSegments) {
          final a = pts[full];
          final b = pts[full + 1];
          final lat = a.latitude + (b.latitude - a.latitude) * frac;
          final lon = a.longitude + (b.longitude - a.longitude) * frac;
          final interm = LatLng(lat, lon);
          final t = nSegments <= 1 ? 0.0 : (full / (nSegments - 1));
          final color = Color.lerp(widget.startColor, widget.endColor, t) ?? widget.startColor;
          segments.add(
            Polyline(
              points: [a, interm],
              strokeWidth: widget.strokeWidth,
              color: color,
            ),
          );
        }

        return PolylineLayer(polylines: segments);
      },
    );
  }
}
