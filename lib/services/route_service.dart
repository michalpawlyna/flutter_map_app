import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;

class RouteService {
  final String _baseUrl = 'https://api.openrouteservice.org/v2/directions/foot-walking/geojson';
  final String? _apiKey = dotenv.env['OPENROUTE_API_KEY'];

  /// Fetches a walking route between [start] and [end] points.
  ///
  /// Returns a [Polyline] that can be added to a FlutterMap PolylineLayer.
  Future<Polyline> getWalkingRoute(LatLng start, LatLng end) async {
    if (_apiKey == null || _apiKey!.isEmpty) {
      throw Exception('OpenRouteService API key is not set in .env');
    }

    final url = Uri.parse(_baseUrl);
    final body = jsonEncode({
      'coordinates': [
        [start.longitude, start.latitude],
        [end.longitude, end.latitude],
      ]
    });

    final response = await http.post(
      url,
      headers: {
        'Authorization': _apiKey!,
        'Content-Type': 'application/json',
      },
      body: body,
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to fetch route: ${response.statusCode} ${response.reasonPhrase}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final features = data['features'] as List<dynamic>?;
    if (features == null || features.isEmpty) {
      throw Exception('No route found in response');
    }

    final geometry = features[0]['geometry'] as Map<String, dynamic>;
    final coords = geometry['coordinates'] as List<dynamic>;

    final List<LatLng> points = coords.map<LatLng>((point) {
      final lng = (point[0] as num).toDouble();
      final lat = (point[1] as num).toDouble();
      return LatLng(lat, lng);
    }).toList();

    return Polyline(
      points: points,
      strokeWidth: 4.0,
    );
  }
}
