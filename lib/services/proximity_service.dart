// lib/services/proximity_service.dart
import 'dart:async';
import 'package:geolocator/geolocator.dart';
import '../models/place.dart';

typedef OnProximityDetected = void Function(Place place);

class ProximityService {
  final List<Place> places;
  final OnProximityDetected onDetected;

  /// Cooldown od ostatniego pokazania alertu dla danego place
  final Duration cooldown;

  /// Ile sekund użytkownik musi być wewnątrz radiusu zanim zaakceptujemy wejście
  final double minEnterTimeSeconds;

  /// Domyślny radius jeśli Place nie ma własnego pola
  final double defaultRadiusMeters;

  final Map<String, DateTime> _lastShown = {};
  final Map<String, DateTime> _enteredAt = {};

  bool _isAlertShowing = false;

  /// ostatnia pozycja otrzymana przez onPosition
  Position? _lastPosition;

  /// timery planujące sprawdzenie po upływie minEnterTimeSeconds
  final Map<String, Timer> _timers = {};

  ProximityService({
    required this.places,
    required this.onDetected,
    this.cooldown = const Duration(minutes: 30),
    this.minEnterTimeSeconds = 2.0,
    this.defaultRadiusMeters = 50.0,
  });

  /// Wywołuj przy każdej aktualizacji pozycji
  void onPosition(Position pos) {
    // zapamiętujemy ostatnią pozycję niezależnie od stanu
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
      ); // w metrach

      if (dist <= radius) {
        if (dist < nearestDist) {
          nearest = p;
          nearestDist = dist;
        }
      }
    }

    if (nearest == null) {
      // nie jesteśmy w zasięgu żadnego miejsca -> czyść zapis wejść i anuluj timery
      _enteredAt.clear();
      _cancelAllTimers();
      return;
    }

    final key = nearest.id;
    final now = DateTime.now();

    // cooldown - nie pokazuj ponownie jeśli ostatnio pokazane dla tego miejsca
    final last = _lastShown[key];
    if (last != null && now.difference(last) < cooldown) {
      return;
    }

    // debounce: musimy być wewnątrz radiusu przez minEnterTimeSeconds
    _enteredAt.putIfAbsent(key, () => now);
    final enteredAt = _enteredAt[key]!;
    final elapsedSec = now.difference(enteredAt).inMilliseconds / 1000.0;

    if (elapsedSec >= minEnterTimeSeconds) {
      // wystarczająco długo -> zaakceptuj natychmiast
      _triggerAlert(key, nearest);
      return;
    }

    // jeśli jeszcze nie minęło, zaplanuj sprawdzenie po pozostałym czasie
    _scheduleEnterCheck(key, nearest, radius, elapsedSec);
  }

  void _scheduleEnterCheck(String key, Place place, double radius, double elapsedSec) {
    // jeśli timer już istnieje dla tego miejsca -> nie zakładamy nowego
    if (_timers.containsKey(key)) return;

    final remaining = (minEnterTimeSeconds - elapsedSec).clamp(0.0, minEnterTimeSeconds);
    final ms = (remaining * 1000).round();
    final timer = Timer(Duration(milliseconds: ms), () {
      // timer fired - sprawdź czy wciąż mamy ostatnią pozycję i czy dalej jesteśmy w radiusie
      try {
        if (_isAlertShowing) {
          _timers.remove(key)?.cancel();
          return;
        }

        final last = _lastShown[key];
        final now = DateTime.now();
        if (last != null && now.difference(last) < cooldown) {
          // cooldown aktywny - usuń wpisy i timer
          _enteredAt.remove(key);
          _timers.remove(key)?.cancel();
          return;
        }

        final pos = _lastPosition;
        if (pos == null) {
          // brak pozycji - nie możemy zaakceptować
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
          // dalej w radiusie -> wyzwól alert
          _triggerAlert(key, place);
        } else {
          // już poza zasięgiem -> czyść i anuluj timer
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
    // final checks
    if (_isAlertShowing) return;

    final now = DateTime.now();
    final last = _lastShown[key];
    if (last != null && now.difference(last) < cooldown) {
      // jednak w cooldownie -> nie pokazujemy
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

  /// Wywołaj, gdy alert został zamknięty (np. user kliknął Zamknij lub Odczytaj)
  /// pozwala to ponownie reagować na kolejne wejścia
  void alertClosed() {
    _isAlertShowing = false;
    _enteredAt.clear();
    _cancelAllTimers();
  }

  /// Opcjonalnie zresetuj cooldown dla danego miejsca (np. do testów)
  void resetCooldownFor(String placeId) {
    _lastShown.remove(placeId);
  }
}
