// lib/services/location_service.dart
import 'dart:async';

import 'package:geolocator/geolocator.dart';

class LocationServiceException implements Exception {
  final String message;
  final String code;
  LocationServiceException(this.code, this.message);
  @override
  String toString() => 'LocationServiceException($code): $message';
}

class LocationService {
  Stream<Position>? _positionBroadcast;

  Future<LocationPermission> checkPermissionStatus() async {
    return await Geolocator.checkPermission();
  }

  Future<LocationPermission> requestPermission() async {
    return await Geolocator.requestPermission();
  }

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

    Stream<Position> positionSequence() async* {
      try {
        final initial = await Geolocator.getCurrentPosition(
          desiredAccuracy: accuracy,
        ).timeout(const Duration(seconds: 5));
        print('[LocationService] initial position: $initial');
        yield initial;
      } catch (e) {
        print('[LocationService] could not get initial position quickly: $e');
      }

      await for (final pos in Geolocator.getPositionStream(locationSettings: settings)) {
        print('[LocationService] stream position: $pos');
        yield pos;
      }
    }

    _positionBroadcast = positionSequence().asBroadcastStream(onListen: (sub) {
      print('[LocationService] position stream listened');
    }, onCancel: (sub) {
      print('[LocationService] position stream cancelled (listener removed)');
    });

    return _positionBroadcast!;
  }

  Future<bool> openAppSettings() async {
    return await Geolocator.openAppSettings();
  }

  Future<bool> openLocationSettings() async {
    return await Geolocator.openLocationSettings();
  }
}
