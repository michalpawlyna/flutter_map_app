import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import '../services/location_service.dart';
import '../services/route_service.dart';
import '../models/place.dart';

class RouteInfoWidget extends StatefulWidget {
  final RouteResult? route;
  final VoidCallback onClear;
  final String? destinationName;
  final LocationService locationService;
  final List<Place> visitedPlaces;

  const RouteInfoWidget({
    Key? key,
    required this.route,
    required this.onClear,
    required this.locationService,
    this.destinationName,
    this.visitedPlaces = const [],
  }) : super(key: key);

  @override
  State<RouteInfoWidget> createState() => _RouteInfoWidgetState();
}

class _RouteInfoWidgetState extends State<RouteInfoWidget> {
  static const _prefsKey = 'transport_mode';
  TransportMode _mode = TransportMode.foot;
  Timer? _timer;
  int _elapsedSeconds = 0;
  bool _isNavigating = false;
  bool _isPaused = false;
  double _traveledMeters = 0.0;
  StreamSubscription<Position>? _posSub;
  Position? _lastPosition;

  @override
  void initState() {
    super.initState();
    _loadMode();
  }

  @override
  void didUpdateWidget(covariant RouteInfoWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.route != oldWidget.route ||
        widget.destinationName != oldWidget.destinationName) {
      _loadMode();
    }
  }

  Future<void> _loadMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final val = prefs.getString(_prefsKey);
      setState(() {
        _mode = TransportModeValues.fromStringValue(val);
      });
    } catch (_) {}
  }

  void _startNavigation() {
    if (widget.route == null) return;
    setState(() {
      _isNavigating = true;
      _isPaused = false;
      _elapsedSeconds = 0;
      _traveledMeters = 0.0;
    });
    try {
      widget.locationService.setMode(LocationMode.tracking);
    } catch (_) {}

    _posSub?.cancel();
    _lastPosition = null;
    _posSub = widget.locationService.positionStream.listen((pos) {
      if (!_isNavigating) return;
      if (_isPaused) {
        _lastPosition = pos;
        return;
      }

      if (_lastPosition != null) {
        final delta = Geolocator.distanceBetween(
          _lastPosition!.latitude,
          _lastPosition!.longitude,
          pos.latitude,
          pos.longitude,
        );
        setState(() {
          _traveledMeters = (_traveledMeters + delta).clamp(
            0.0,
            widget.route!.distanceMeters,
          );
        });
      }
      _lastPosition = pos;
    }, onError: (_) {});

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_isPaused) return;
      setState(() {
        _elapsedSeconds++;
        if (_traveledMeters >= widget.route!.distanceMeters) {
          _timer?.cancel();
          _isNavigating = false;
        }
      });
    });
  }

  void _togglePause() {
    if (!_isNavigating) return;
    setState(() {
      _isPaused = !_isPaused;
    });
    try {
      widget.locationService.setMode(
        _isPaused ? LocationMode.normal : LocationMode.tracking,
      );
    } catch (_) {}
  }

  Future<void> _finishNavigation() async {
    _timer?.cancel();
    await _posSub?.cancel();
    try {
      widget.locationService.setMode(LocationMode.normal);
    } catch (_) {}

    await _saveRouteHistory(_traveledMeters);

    setState(() {
      _isNavigating = false;
      _isPaused = false;
      _elapsedSeconds = 0;
      _traveledMeters = 0.0;
      _lastPosition = null;
    });

    widget.onClear();
  }

  Future<void> _saveRouteHistory(double meters) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final km = meters / 1000.0;
      final entry =
          '${DateTime.now().toIso8601String()}|${km.toStringAsFixed(2)}';
      final List<String> list =
          prefs.getStringList('route_history') ?? <String>[];
      list.insert(0, entry);
      await prefs.setStringList('route_history', list);
      final prev = prefs.getDouble('total_km') ?? 0.0;
      await prefs.setDouble(
        'total_km',
        (prev + double.parse(km.toStringAsFixed(2))),
      );
    } catch (_) {}
  }

  String _formatDuration(double seconds) {
    if (seconds < 60) {
      return '${seconds.toStringAsFixed(0)}s';
    } else if (seconds < 3600) {
      final minutes = (seconds / 60).toStringAsFixed(0);
      return '${minutes} min';
    } else {
      final hours = (seconds ~/ 3600);
      final minutes = ((seconds % 3600) ~/ 60);
      return '${hours}h ${minutes}min';
    }
  }

  String _formatElapsedShort(int seconds) {
    if (seconds < 3600) {
      final m = (seconds ~/ 60).toString().padLeft(2, '0');
      final s = (seconds % 60).toString().padLeft(2, '0');
      return '$m:$s';
    } else {
      final h = (seconds ~/ 3600).toString().padLeft(2, '0');
      final m = ((seconds % 3600) ~/ 60).toString().padLeft(2, '0');
      final s = (seconds % 60).toString().padLeft(2, '0');
      return '$h:$m:$s';
    }
  }

  String _formatKm(double meters, {int decimals = 1}) {
    final km = meters / 1000.0;
    return km.toStringAsFixed(decimals).replaceAll('.', ',');
  }

  @override
  Widget build(BuildContext context) {
    if (widget.route == null) return const SizedBox.shrink();
    const background = Colors.white;

    return Positioned(
      bottom: 16,
      left: 16,
      right: 16,
      child: SafeArea(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child:
              _isNavigating
                  ? _buildNavigatingView(context)
                  : _buildPreStartView(context),
        ),
      ),
    );
  }

  Widget _buildPreStartView(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _formatDuration(widget.route!.durationSeconds),
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: Colors.black,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${_formatKm(widget.route!.distanceMeters, decimals: 1)} km',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade500,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _buildDestinationInfo(),
                ],
              ),
            ),

            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Icon(
                  _mode == TransportMode.car
                      ? Icons.directions_car
                      : _mode == TransportMode.bike
                      ? Icons.pedal_bike
                      : Icons.directions_walk,
                  color: Colors.black,
                  size: 22,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _startNavigation,
                icon: const Icon(Icons.navigation, size: 20),
                label: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 14),
                  child: Text(
                    'Start',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDestinationInfo() {
    if (widget.visitedPlaces.isEmpty) {
      return const SizedBox.shrink();
    }

    final firstPlace = widget.visitedPlaces.first;
    final remainingCount = widget.visitedPlaces.length - 1;

    return Row(
      children: [
        Icon(
          Icons.location_on,
          size: 16,
          color: Colors.grey.shade500,
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Row(
            children: [
              Expanded(
                child: Text(
                  firstPlace.name,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (remainingCount > 0)
                Padding(
                  padding: const EdgeInsets.only(left: 6),
                  child: Text(
                    '+$remainingCount więcej',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade500,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNavigatingView(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'CZAS TRWANIA',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade500,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _formatElapsedShort(_elapsedSeconds),
                    style: const TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.w900,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'PRZEBYTY DYSTANS',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade500,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${_formatKm(_traveledMeters, decimals: 1)} km',
                    style: const TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.w900,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 14),

        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _finishNavigation,
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: Colors.transparent),
                  foregroundColor: Colors.black,
                  backgroundColor: Colors.grey.shade200,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Zakończ',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                ),
              ),
            ),

            const SizedBox(width: 12),

            Expanded(
              child: ElevatedButton.icon(
                onPressed: _togglePause,
                icon: Icon(_isPaused ? Icons.play_arrow : Icons.pause),
                label: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    _isPaused ? 'Wznów' : 'Pauza',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _posSub?.cancel();
    super.dispose();
  }
}
