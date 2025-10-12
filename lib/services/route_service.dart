import 'dart:convert';
import 'dart:math';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;

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

class RouteService {
  final String _baseUrl =
      'https://api.openrouteservice.org/v2/directions/foot-walking/geojson';
  final String? _apiKey = dotenv.env['OPENROUTE_API_KEY'];

  Future<RouteResult> getWalkingRoute(LatLng start, LatLng end) async {
    return getWalkingRouteFromWaypoints([start, end]);
  }

  Future<RouteResult> getWalkingRouteFromWaypoints(
    List<LatLng> waypoints,
  ) async {
    if (_apiKey == null || _apiKey.isEmpty) {
      throw Exception('OpenRouteService API key is not set in .env');
    }

    if (waypoints.length < 2) {
      throw Exception('At least two waypoints are required to build a route');
    }

    final url = Uri.parse(_baseUrl);
    final coords = waypoints.map((p) => [p.longitude, p.latitude]).toList();

    final body = jsonEncode({'coordinates': coords});

    final response = await http.post(
      url,
      headers: {'Authorization': _apiKey, 'Content-Type': 'application/json'},
      body: body,
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to fetch route: ${response.statusCode} ${response.reasonPhrase}',
      );
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
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
