// lib/services/proximity_service.dart
import 'dart:async';
import 'package:geolocator/geolocator.dart';
import '../models/place.dart';

typedef OnProximityDetected = void Function(Place place);

class ProximityService {
  final List<Place> places;
  final OnProximityDetected onDetected;

  final Duration cooldown;

  final double minEnterTimeSeconds;

  final double defaultRadiusMeters;

  final Map<String, DateTime> _lastShown = {};
  final Map<String, DateTime> _enteredAt = {};

  bool _isAlertShowing = false;

  Position? _lastPosition;
  final Map<String, Timer> _timers = {};

  ProximityService({
    required this.places,
    required this.onDetected,
    this.cooldown = const Duration(minutes: 30),
    this.minEnterTimeSeconds = 2.0,
    this.defaultRadiusMeters = 50.0,
  });

  void onPosition(Position pos) {
    _lastPosition = pos;

    if (_isAlertShowing) return;

    Place? nearest;
    double nearestDist = double.infinity;
    final radius = defaultRadiusMeters;

    for (final p in places) {
      final dist = Geolocator.distanceBetween(
        pos.latitude,
        pos.longitude,
        p.lat,
        p.lng,
      );

      if (dist <= radius) {
        if (dist < nearestDist) {
          nearest = p;
          nearestDist = dist;
        }
      }
    }

    if (nearest == null) {
      _enteredAt.clear();
      _cancelAllTimers();
      return;
    }

    final key = nearest.id;
    final now = DateTime.now();

    final last = _lastShown[key];
    if (last != null && now.difference(last) < cooldown) {
      return;
    }

    _enteredAt.putIfAbsent(key, () => now);
    final enteredAt = _enteredAt[key]!;
    final elapsedSec = now.difference(enteredAt).inMilliseconds / 1000.0;

    if (elapsedSec >= minEnterTimeSeconds) {
      _triggerAlert(key, nearest);
      return;
    }
    _scheduleEnterCheck(key, nearest, radius, elapsedSec);
  }

  void _scheduleEnterCheck(String key, Place place, double radius, double elapsedSec) {

    if (_timers.containsKey(key)) return;

    final remaining = (minEnterTimeSeconds - elapsedSec).clamp(0.0, minEnterTimeSeconds);
    final ms = (remaining * 1000).round();
    final timer = Timer(Duration(milliseconds: ms), () {

      try {
        if (_isAlertShowing) {
          _timers.remove(key)?.cancel();
          return;
        }

        final last = _lastShown[key];
        final now = DateTime.now();
        if (last != null && now.difference(last) < cooldown) {
          _enteredAt.remove(key);
          _timers.remove(key)?.cancel();
          return;
        }

        final pos = _lastPosition;
        if (pos == null) {
          _enteredAt.remove(key);
          _timers.remove(key)?.cancel();
          return;
        }

        final dist = Geolocator.distanceBetween(
          pos.latitude,
          pos.longitude,
          place.lat,
          place.lng,
        );

        if (dist <= radius) {
          _triggerAlert(key, place);
        } else {
          _enteredAt.remove(key);
          _timers.remove(key)?.cancel();
        }
      } catch (_) {
        _timers.remove(key)?.cancel();
      }
    });

    _timers[key] = timer;
  }

  void _triggerAlert(String key, Place place) {
    if (_isAlertShowing) return;

    final now = DateTime.now();
    final last = _lastShown[key];
    if (last != null && now.difference(last) < cooldown) {
      _enteredAt.remove(key);
      _cancelTimer(key);
      return;
    }

    _isAlertShowing = true;
    _lastShown[key] = now;
    _cancelTimer(key);
    _enteredAt.remove(key);
    onDetected(place);
  }

  void _cancelTimer(String key) {
    final t = _timers.remove(key);
    t?.cancel();
  }

  void _cancelAllTimers() {
    for (final t in _timers.values) {
      t.cancel();
    }
    _timers.clear();
  }

  void alertClosed() {
    _isAlertShowing = false;
    _enteredAt.clear();
    _cancelAllTimers();
  }

  void resetCooldownFor(String placeId) {
    _lastShown.remove(placeId);
  }
}
