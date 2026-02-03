import 'dart:async';

import 'package:geolocator/geolocator.dart';
import 'package:geolocator_android/geolocator_android.dart';

class LocationServiceException implements Exception {
  final String code;
  final String message;
  LocationServiceException(this.code, this.message);
  @override
  String toString() => 'LocationServiceException($code): $message';
}

enum LocationMode { idle, normal, tracking }

class LocationService {
  final StreamController<Position> _controller =
      StreamController<Position>.broadcast();
  Stream<Position> get positionStream => _controller.stream;

  StreamSubscription<Position>? _geoSub;
  StreamSubscription<ServiceStatus>? _serviceStatusSub;

  LocationMode _mode = LocationMode.idle;
  LocationMode get mode => _mode;

  int _minEmitIntervalMs = 0;
  DateTime? _lastEmitAt;
  Position? _lastEmittedPosition;

  LocationService() {
    _serviceStatusSub = Geolocator.getServiceStatusStream().listen((status) {
      if (status == ServiceStatus.disabled) {
        _controller.addError(
          LocationServiceException(
            'service_disabled',
            'Location services disabled.',
          ),
        );
      } else {
        if (_mode != LocationMode.idle) {
          _restartGeoSubWithMode(_mode);
        }
      }
    });
  }

  Future<LocationPermission> checkPermissionStatus() async =>
      await Geolocator.checkPermission();

  Future<LocationPermission> requestPermission() async =>
      await Geolocator.requestPermission();

  Future<bool> ensureLocationEnabledAndPermitted() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw LocationServiceException(
        'service_disabled',
        'Location services are disabled. Please enable them in system settings.',
      );
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw LocationServiceException(
          'permission_denied',
          'Location permission denied by user.',
        );
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw LocationServiceException(
        'permission_denied_forever',
        'Location permissions permanently denied; open app settings.',
      );
    }

    return true;
  }

  void setMode(LocationMode newMode) {
    if (newMode == _mode) return;
    _mode = newMode;
    if (newMode == LocationMode.idle) {
      stopUpdates();
    } else {
      _restartGeoSubWithMode(newMode);
    }
  }

  Future<void> startUpdates({
    LocationMode startMode = LocationMode.normal,
  }) async {
    await ensureLocationEnabledAndPermitted();
    setMode(startMode);
  }

  void stopUpdates() {
    _geoSub?.cancel();
    _geoSub = null;
  }

  void _restartGeoSubWithMode(LocationMode mode) {
    _geoSub?.cancel();
    _geoSub = null;

    LocationAccuracy accuracy = LocationAccuracy.high;
    int distanceFilter = 25;
    Duration? androidInterval;
    int minEmitMs = 0;

    switch (mode) {
      case LocationMode.normal:
        accuracy = LocationAccuracy.high;
        distanceFilter = 0;
        androidInterval = const Duration(seconds: 10);
        minEmitMs = 1000;
        break;
      case LocationMode.tracking:
        accuracy = LocationAccuracy.bestForNavigation;
        distanceFilter = 5;
        androidInterval = const Duration(seconds: 5);
        minEmitMs = 500;
        break;
      case LocationMode.idle:
        accuracy = LocationAccuracy.low;
        distanceFilter = 100;
        androidInterval = const Duration(seconds: 30);
        minEmitMs = 5000;
        break;
    }

    _minEmitIntervalMs = minEmitMs;

    final locationSettings = LocationSettings(
      accuracy: accuracy,
      distanceFilter: distanceFilter,
    );

    AndroidSettings? androidSettings;
    try {
      androidSettings = AndroidSettings(
        accuracy: accuracy,
        distanceFilter: distanceFilter,
        intervalDuration: androidInterval,
      );
    } catch (_) {
      androidSettings = null;
    }

    final effectiveSettings = androidSettings ?? locationSettings;

    Geolocator.getLastKnownPosition()
        .then((pos) {
          if (pos != null) _tryEmit(pos);
        })
        .catchError((_) {});

    _geoSub = Geolocator.getPositionStream(
      locationSettings: effectiveSettings,
    ).listen(
      (pos) {
        _tryEmit(pos);
      },
      onError: (e) {
        _controller.addError(e);
      },
    );
  }

  void _tryEmit(Position pos) {
    final now = DateTime.now();
    if (_lastEmittedPosition != null) {
      final dist = Geolocator.distanceBetween(
        _lastEmittedPosition!.latitude,
        _lastEmittedPosition!.longitude,
        pos.latitude,
        pos.longitude,
      );
      if (_minEmitIntervalMs > 0 &&
          _lastEmitAt != null &&
          now.difference(_lastEmitAt!).inMilliseconds < _minEmitIntervalMs &&
          dist < 1.0) {
        return;
      }
    }

    if (pos.accuracy > 2000) {
      return;
    }

    _lastEmittedPosition = pos;
    _lastEmitAt = now;
    _controller.add(pos);
  }

  Future<void> dispose() async {
    await _geoSub?.cancel();
    await _serviceStatusSub?.cancel();
    await _controller.close();
  }
}
