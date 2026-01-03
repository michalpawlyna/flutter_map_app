import 'dart:convert';
import 'dart:math';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class RouteResult {
  final List<LatLng> points;
  final double distanceMeters;
  final double durationSeconds;

  RouteResult({
    required this.points,
    required this.distanceMeters,
    required this.durationSeconds,
  });
}

enum TransportMode { foot, bike, car }

class TransportModeValues {
  static const Map<TransportMode, String> _toString = {
    TransportMode.foot: 'foot-walking',
    TransportMode.bike: 'cycling-regular',
    TransportMode.car: 'driving-car',
  };

  static const Map<String, TransportMode> _fromString = {
    'foot-walking': TransportMode.foot,
    'cycling-regular': TransportMode.bike,
    'driving-car': TransportMode.car,
  };

  static String stringOf(TransportMode mode) => _toString[mode]!;

  static TransportMode fromStringValue(String? s) {
    if (s == null) return TransportMode.foot;
    return _fromString[s] ?? TransportMode.foot;
  }
}

class RouteService {
  final String _baseUrl = 'https://api.openrouteservice.org/v2/directions';
  final String? _apiKey = dotenv.env['OPENROUTE_API_KEY'];

  static const String _prefsKeyTransport = 'transport_mode';

  Future<TransportMode> _getSelectedTransportMode() async {
    final prefs = await SharedPreferences.getInstance();
    final val = prefs.getString(_prefsKeyTransport);
    return TransportModeValues.fromStringValue(val);
  }

  Future<RouteResult> getWalkingRoute(LatLng start, LatLng end) async {
    return getWalkingRouteFromWaypoints([start, end]);
  }

  Future<RouteResult> getWalkingRouteFromWaypoints(
    List<LatLng> waypoints, {
    TransportMode? mode,
  }) async {
    if (_apiKey == null || _apiKey.isEmpty) {
      throw Exception('OpenRouteService API key is not set in .env');
    }

    if (waypoints.length < 2) {
      throw Exception('At least two waypoints are required to build a route');
    }

    final usedMode = mode ?? await _getSelectedTransportMode();
    final profile = TransportModeValues.stringOf(usedMode);
    final url = Uri.parse('$_baseUrl/$profile/geojson');
    final coords = waypoints.map((p) => [p.longitude, p.latitude]).toList();

    final body = jsonEncode({'coordinates': coords});

    debugPrint(
      '[RouteService] Requesting route with ${waypoints.length} waypoints using $profile mode',
    );

    const maxRetries = 3;
    const retryDelay = Duration(seconds: 2);

    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        debugPrint(
          '[RouteService] Attempt $attempt/$maxRetries to fetch route...',
        );

        final response = await http
            .post(
              url,
              headers: {
                'Authorization': _apiKey,
                'Content-Type': 'application/json',
              },
              body: body,
            )
            .timeout(
              const Duration(seconds: 30),
              onTimeout:
                  () =>
                      throw TimeoutException(
                        'Route request timeout after 30 seconds',
                      ),
            );

        debugPrint('[RouteService] Response status: ${response.statusCode}');

        if (response.statusCode == 200) {
          debugPrint('[RouteService] Route fetched successfully');
          return _parseRouteResponse(response.body);
        } else if (response.statusCode == 502 ||
            response.statusCode == 503 ||
            response.statusCode == 504) {
          debugPrint(
            '[RouteService] Server error ${response.statusCode}. Response: ${response.body}',
          );
          if (attempt < maxRetries) {
            debugPrint(
              '[RouteService] Retrying after ${retryDelay.inSeconds * attempt}s...',
            );
            await Future.delayed(retryDelay * attempt);
            continue;
          } else {
            throw Exception(
              'OpenRouteService is temporarily unavailable (HTTP ${response.statusCode}). Please try again in a moment.',
            );
          }
        } else if (response.statusCode == 401 || response.statusCode == 403) {
          debugPrint('[RouteService] Authentication error: ${response.body}');
          throw Exception(
            'OpenRouteService API key is invalid or expired. Please check your configuration.',
          );
        } else if (response.statusCode == 429) {
          debugPrint('[RouteService] Rate limit exceeded: ${response.body}');
          throw Exception(
            'Too many requests to OpenRouteService. Please wait a moment and try again.',
          );
        } else if (response.statusCode == 400) {
          debugPrint('[RouteService] Bad request: ${response.body}');
          throw Exception(
            'Invalid route parameters. The selected waypoints might be too far apart or inaccessible.',
          );
        } else {
          debugPrint(
            '[RouteService] Unexpected error: ${response.statusCode} - ${response.body}',
          );
          throw Exception(
            'Failed to fetch route: ${response.statusCode} ${response.reasonPhrase}',
          );
        }
      } on TimeoutException catch (e) {
        debugPrint('[RouteService] Timeout error: $e');
        if (attempt < maxRetries) {
          debugPrint('[RouteService] Retrying after timeout...');
          await Future.delayed(retryDelay * attempt);
          continue;
        } else {
          throw Exception(
            'Route request timed out after 30 seconds. Please check your internet connection and try again.',
          );
        }
      } catch (e) {
        debugPrint('[RouteService] Error on attempt $attempt: $e');
        if (attempt < maxRetries && e.toString().contains('502|503|504')) {
          await Future.delayed(retryDelay * attempt);
          continue;
        }
        rethrow;
      }
    }

    throw Exception('Failed to fetch route after $maxRetries attempts.');
  }

  RouteResult _parseRouteResponse(String responseBody) {
    final data = jsonDecode(responseBody) as Map<String, dynamic>;
    final features = data['features'] as List<dynamic>?;
    if (features == null || features.isEmpty) {
      throw Exception('No route found in response');
    }

    final geometry = features[0]['geometry'] as Map<String, dynamic>;
    final coordsResp = geometry['coordinates'] as List<dynamic>;

    final List<LatLng> points =
        coordsResp.map<LatLng>((point) {
          final lng = (point[0] as num).toDouble();
          final lat = (point[1] as num).toDouble();
          return LatLng(lat, lng);
        }).toList();

    double? distanceMeters;
    double? durationSeconds;

    final props = features[0]['properties'] as Map<String, dynamic>?;
    if (props != null) {
      final summary = props['summary'] as Map<String, dynamic>?;
      if (summary != null) {
        distanceMeters = (summary['distance'] as num?)?.toDouble();
        durationSeconds = (summary['duration'] as num?)?.toDouble();
      }

      if ((distanceMeters == null || durationSeconds == null) &&
          props['segments'] is List) {
        final segments = props['segments'] as List<dynamic>;
        if (segments.isNotEmpty) {
          double dSum = 0;
          double tSum = 0;
          for (final seg in segments) {
            dSum += (seg['distance'] as num?)?.toDouble() ?? 0;
            tSum += (seg['duration'] as num?)?.toDouble() ?? 0;
          }
          distanceMeters ??= dSum;
          durationSeconds ??= tSum;
        }
      }
    }

    if (distanceMeters == null || durationSeconds == null) {
      double d = 0;
      for (int i = 0; i < points.length - 1; i++) {
        d += _haversineDistance(points[i], points[i + 1]);
      }
      distanceMeters ??= d;
      durationSeconds ??= (distanceMeters / 1000) / 5 * 3600;
    }

    return RouteResult(
      points: points,
      distanceMeters: distanceMeters,
      durationSeconds: durationSeconds,
    );
  }

  List<int> optimizeWaypointsOrderWith2Opt(
    LatLng start,
    List<LatLng> pointsToVisit,
  ) {
    if (pointsToVisit.isEmpty) return [];
    if (pointsToVisit.length == 1) return [0];

    List<int> tour = _greedyNearestNeighbor(start, pointsToVisit);
    
    double bestDistance = _calculateTourDistance(start, pointsToVisit, tour);
    bool improved = true;
    int iterations = 0;
    const maxIterations = 1000;

    debugPrint('[RouteService] Starting 2-opt optimization with ${pointsToVisit.length} points');
    debugPrint('[RouteService] Initial tour distance: ${bestDistance.toStringAsFixed(0)}m');

    while (improved && iterations < maxIterations) {
      improved = false;
      iterations++;

      for (int i = 0; i < tour.length - 1; i++) {
        for (int j = i + 2; j < tour.length; j++) {
          List<int> newTour = _swap2Opt(tour, i, j);
          double newDistance = _calculateTourDistance(start, pointsToVisit, newTour);

          if (newDistance < bestDistance) {
            tour = newTour;
            bestDistance = newDistance;
            improved = true;

            debugPrint(
              '[RouteService] 2-opt improvement found at iteration $iterations: ${newDistance.toStringAsFixed(0)}m',
            );
            break;
          }
        }
        if (improved) break;
      }
    }

    debugPrint(
      '[RouteService] 2-opt optimization completed after $iterations iterations. Final distance: ${bestDistance.toStringAsFixed(0)}m',
    );
    return tour;
  }


  List<int> _greedyNearestNeighbor(LatLng start, List<LatLng> points) {
    final List<int> tour = [];
    final Set<int> visited = {};
    LatLng current = start;

    while (visited.length < points.length) {
      int nearest = -1;
      double nearestDist = double.infinity;

      for (int i = 0; i < points.length; i++) {
        if (!visited.contains(i)) {
          final dist = _haversineDistance(current, points[i]);
          if (dist < nearestDist) {
            nearestDist = dist;
            nearest = i;
          }
        }
      }

      if (nearest >= 0) {
        tour.add(nearest);
        visited.add(nearest);
        current = points[nearest];
      }
    }

    return tour;
  }

  double _calculateTourDistance(
    LatLng start,
    List<LatLng> points,
    List<int> tour,
  ) {
    double distance = 0;
    LatLng current = start;

    for (final idx in tour) {
      distance += _haversineDistance(current, points[idx]);
      current = points[idx];
    }

    return distance;
  }

  List<int> _swap2Opt(List<int> tour, int i, int j) {
    final newTour = List<int>.from(tour);
    final segment = newTour.sublist(i + 1, j + 1).reversed.toList();
    for (int k = 0; k < segment.length; k++) {
      newTour[i + 1 + k] = segment[k];
    }
    return newTour;
  }

  double _haversineDistance(LatLng a, LatLng b) {
    const R = 6371000.0;
    final lat1 = _degToRad(a.latitude);
    final lat2 = _degToRad(b.latitude);
    final dLat = _degToRad(b.latitude - a.latitude);
    final dLon = _degToRad(b.longitude - a.longitude);

    final sinDlat = sin(dLat / 2);
    final sinDlon = sin(dLon / 2);
    final aa = sinDlat * sinDlat + cos(lat1) * cos(lat2) * sinDlon * sinDlon;
    final c = 2 * atan2(sqrt(aa), sqrt(1 - aa));
    return R * c;
  }

  double _degToRad(double deg) => deg * pi / 180.0;
}
