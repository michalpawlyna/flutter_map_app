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

  ProximityService({
    required this.places,
    required this.onDetected,
    this.cooldown = const Duration(minutes: 30),
    this.minEnterTimeSeconds = 2.0,
    this.defaultRadiusMeters = 50.0,
  });

  /// Wywołuj przy każdej aktualizacji pozycji
  void onPosition(Position pos) {
    if (_isAlertShowing) return;

    Place? nearest;
    double nearestDist = double.infinity;

    for (final p in places) {
      final dist = Geolocator.distanceBetween(
        pos.latitude,
        pos.longitude,
        p.lat,
        p.lng,
      ); // w metrach

      final radius = defaultRadiusMeters; // możesz rozszerzyć Place o własny radius
      if (dist <= radius) {
        if (dist < nearestDist) {
          nearest = p;
          nearestDist = dist;
        }
      }
    }

    if (nearest == null) {
      // nie jesteśmy w zasięgu żadnego miejsca -> czyść zapis wejść
      // ale nie czyścimy _lastShown (cooldown musi pozostać)
      _enteredAt.clear();
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
    if (now.difference(enteredAt).inSeconds < minEnterTimeSeconds) {
      return;
    }

    // zaakceptuj
    _isAlertShowing = true;
    _lastShown[key] = now;
    onDetected(nearest);
  }

  /// Wywołaj, gdy alert został zamknięty (np. user kliknął Zamknij lub Odczytaj)
  /// pozwala to ponownie reagować na kolejne wejścia
  void alertClosed() {
    _isAlertShowing = false;
    _enteredAt.clear();
  }

  /// Opcjonalnie zresetuj cooldown dla danego miejsca (np. do testów)
  void resetCooldownFor(String placeId) {
    _lastShown.remove(placeId);
  }
}
