// lib/services/location_service.dart
import 'dart:async';

import 'package:geolocator/geolocator.dart';

/// Proste klasy błędów (możesz rozszerzyć)
class LocationServiceException implements Exception {
  final String message;
  final String code;
  LocationServiceException(this.code, this.message);
  @override
  String toString() => 'LocationServiceException($code): $message';
}

class LocationService {
  Stream<Position>? _positionBroadcast;

  /// Sprawdza aktualny status permisji (nie prosi jeszcze systemowego dialogu).
  Future<LocationPermission> checkPermissionStatus() async {
    return await Geolocator.checkPermission();
  }

  /// Prosi o permisję (systemowy dialog) i zwraca wynik.
  Future<LocationPermission> requestPermission() async {
    return await Geolocator.requestPermission();
  }

  /// Wygodne "ensure" - sprawdza service + permisję i zwraca true jeśli OK,
  /// lub rzuca LocationServiceException z kodem:
  /// 'service_disabled', 'permission_denied', 'permission_denied_forever'
  Future<bool> ensureLocationEnabledAndPermitted() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw LocationServiceException('service_disabled',
          'Location services are disabled. Please enable them in system settings.');
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw LocationServiceException(
            'permission_denied', 'Location permission denied by user.');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw LocationServiceException('permission_denied_forever',
          'Location permissions are permanently denied, open app settings to enable them.');
    }

    return true;
  }

  /// Zwraca aktualną pozycję z opcjonalnym timeoutem (np. 10s).
  Future<Position> getCurrentLocation(
      {Duration timeout = const Duration(seconds: 10)}) async {
    try {
      await ensureLocationEnabledAndPermitted();
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      ).timeout(timeout, onTimeout: () {
        throw LocationServiceException(
            'timeout', 'Timeout while fetching current location.');
      });
    } on LocationServiceException {
      rethrow;
    } catch (e) {
      throw LocationServiceException('unknown', 'Failed to get current location: $e');
    }
  }

  /// Zwraca broadcast stream pozycji. Pierwsze wywołanie utworzy i zapamięta stream
  /// (z podanymi ustawieniami). Kolejne wywołania zwrócą tę samą instancję broadcast.
  /// DODATKOWO: najpierw emituje jednorazowo bieżącą pozycję (jeśli się uda),
  /// a potem przekazuje dalsze aktualizacje z getPositionStream.
  Stream<Position> getLocationStream({
    LocationAccuracy accuracy = LocationAccuracy.high,
    int distanceFilter = 10,
  }) {
    if (_positionBroadcast != null) {
      return _positionBroadcast!;
    }

    final settings = LocationSettings(
      accuracy: accuracy,
      distanceFilter: distanceFilter,
    );

    // Generator: najpierw próbujemy zwrócić jednorazowo current position,
    // potem przekazujemy ciąg wydarzeń z getPositionStream.
    Stream<Position> positionSequence() async* {
      try {
        // krótki timeout na pobranie "pierwszej" pozycji — nie blokujemy zbyt długo
        final initial = await Geolocator.getCurrentPosition(
          desiredAccuracy: accuracy,
        ).timeout(const Duration(seconds: 5));
        print('[LocationService] initial position: $initial');
        yield initial;
      } catch (e) {
        // Jeżeli fail — logujemy, ale nie rzucamy (dalej przechodzimy do streamu zmian)
        print('[LocationService] could not get initial position quickly: $e');
      }

      // Następnie yieldujemy wszystkie przyszłe aktualizacje
      await for (final pos in Geolocator.getPositionStream(locationSettings: settings)) {
        print('[LocationService] stream position: $pos');
        yield pos;
      }
    }

    _positionBroadcast = positionSequence().asBroadcastStream(onListen: (sub) {
      // opcjonalny log
      print('[LocationService] position stream listened');
    }, onCancel: (sub) {
      print('[LocationService] position stream cancelled (listener removed)');
    });

    return _positionBroadcast!;
  }

  /// Otwiera ustawienia aplikacji (przydatne gdy permission == deniedForever).
  Future<bool> openAppSettings() async {
    return await Geolocator.openAppSettings();
  }

  /// Otwiera ustawienia lokalizacji systemu (przydatne gdy service disabled).
  Future<bool> openLocationSettings() async {
    return await Geolocator.openLocationSettings();
  }
}
