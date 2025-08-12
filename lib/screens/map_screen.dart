import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_animations/flutter_map_animations.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';

import '../widgets/user_location_widget.dart';
import '../widgets/center_on_user_button_widget.dart';
import '../widgets/places_markers_widget.dart';
import '../widgets/proximity_alert_dialog.dart';
import '../models/place.dart';
import '../services/location_service.dart';
import '../services/firestore_service.dart';
import '../services/tts_service.dart';
import '../services/proximity_service.dart';

import '../services/route_service.dart';
import '../widgets/route_polyline_widget.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({Key? key}) : super(key: key);

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen>
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin<MapScreen> {
  @override
  bool get wantKeepAlive => true;

  late final AnimatedMapController _animatedMapController;
  late final Stream<Position> _positionStream;
  late final Future<void> _initializationFuture;

  LatLng? _initialCenter;
  Position? _initialPosition;

  final FirestoreService _firestoreService = FirestoreService();
  final LocationService _locationService = LocationService();
  final TtsService _tts = TtsService();

  ProximityService? _proximityService;
  StreamSubscription<Position>? _locSub;
  List<Place> _places = [];

  RouteResult? _currentRoute;
  bool _routeLoading = false;

  @override
  void initState() {
    super.initState();
    _animatedMapController = AnimatedMapController(vsync: this);
    _initializationFuture = _initializeServicesAndLocationStream().then((_) {
      debugPrint('[MapScreen] initialization future completed');
    });
  }

  Future<void> _initializeServicesAndLocationStream() async {
    try {
      await _location_service_ensureAndPrepare();
    } catch (e, st) {
      debugPrint("Błąd podczas inicjalizacji mapy: $e\n$st");
      rethrow;
    }
  }

  Future<void> _location_service_ensureAndPrepare() async {
    await _locationService.ensureLocationEnabledAndPermitted();

    _positionStream = _location_service_getStreamWithFallback();

    await _initProximity(_positionStream);

    try {
      final initialPos = await _locationService.getCurrentLocation();
      _initialCenter = LatLng(initialPos.latitude, initialPos.longitude);
      _initialPosition = initialPos;
      debugPrint('[MapScreen] initial center set to $_initialCenter');
    } catch (e) {
      debugPrint('[MapScreen] could not get explicit initial position: $e');
    }
  }

  Stream<Position> _location_service_getStreamWithFallback() {
    return _locationService.getLocationStream(
      accuracy: LocationAccuracy.bestForNavigation,
      distanceFilter: 10,
    );
  }

  Future<void> _initProximity(Stream<Position> positionStream) async {
    final places = await _firestoreService.getAllPlaces();
    if (!mounted) return;

    _places = places;

    _proximityService = ProximityService(
      places: _places,
      onDetected: (place) {
        if (!mounted) return;
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => ProximityAlertDialog(
            place: place,
            tts: _tts,
            onClose: () => _proximityService?.alertClosed(),
          ),
        );
      },
    );

    _locSub = positionStream.listen((pos) {
      _proximityService?.onPosition(pos);
    }, onError: (e) {
      if (mounted) {
        final snack = SnackBar(content: Text('Błąd strumienia lokalizacji: $e'));
        ScaffoldMessenger.of(context).showSnackBar(snack);
      }
    });
  }

  @override
  void dispose() {
    _locSub?.cancel();
    _proximityService = null;
    _tts.dispose();
    _animatedMapController.dispose();
    super.dispose();
  }

  // przykładowy fetch (możesz i tu wywoływać jeśli potrzebujesz)
  Future<void> _fetchRouteExample(LatLng start, LatLng end) async {
    setState(() => _routeLoading = true);
    try {
      final route = await RouteService().getWalkingRoute(start, end);
      if (!mounted) return;
      setState(() {
        _currentRoute = route;
      });
    } catch (e) {
      debugPrint('Błąd pobierania trasy: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Błąd pobierania trasy: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _routeLoading = false);
    }
  }

  String _formatDuration(double seconds) {
    final dur = Duration(seconds: seconds.round());
    final hours = dur.inHours;
    final minutes = dur.inMinutes.remainder(60);
    if (hours > 0) return '${hours}h ${minutes}m';
    return '${minutes} min';
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return FutureBuilder<void>(
      future: _initializationFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text("Inicjalizacja mapy i lokalizacji..."),
                ],
              ),
            ),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  "Wystąpił błąd podczas ładowania mapy.\n\n"
                  "Sprawdź uprawnienia do lokalizacji i połączenie z internetem.\n\n"
                  "Błąd: ${snapshot.error}",
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          );
        }

        return Scaffold(
          body: Stack(
            children: [
              FlutterMap(
                mapController: _animatedMapController.mapController,
                options: MapOptions(
                  initialCenter: _initialCenter ?? const LatLng(52.0, 19.0),
                  initialZoom: _initialCenter != null ? 15.0 : 6.0,
                  minZoom: 4.0,
                  maxZoom: 18.0,
                  interactionOptions: const InteractionOptions(
                    flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                  ),
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png',
                    subdomains: const ['a', 'b', 'c', 'd'],
                    retinaMode: RetinaMode.isHighDensity(context),
                  ),

                  // trasa globalnie (MapScreen) — najpierw, będzie pod markerami i lokalizacją
                  if (_currentRoute != null)
                    RoutePolylineWidget(
                      points: _currentRoute!.points,
                      strokeWidth: 5.0,
                      startColor: const Color(0xFF9B7BFF),
                      endColor: const Color(0xFFFD4A9A),
                    ),

                  // markery miejsc (nie rysują już trasy) — będą nad trasą
                  PlacesMarkersWidget(
                    mapController: _animatedMapController,
                    onRouteGenerated: (route) {
                      // ustawiamy trasę i (opcjonalnie) dopasowujemy kamerę
                      setState(() {
                        _currentRoute = route;
                      });

                      if (route.points.isNotEmpty) {
                        _animatedMapController.mapController.fitCamera(
                          CameraFit.bounds(
                            bounds: LatLngBounds.fromPoints(route.points),
                            padding: const EdgeInsets.all(40),
                          ),
                        );
                      }
                    },
                  ),

                  // user location — na samej górze, żeby zawsze było widoczne
                  UserLocationWidget(positionStream: _positionStream),
                ],
              ),

              CenterOnUserButton(mapController: _animatedMapController),

              if (_currentRoute != null)
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: 80,
                  child: Card(
                    color: Colors.black.withOpacity(0.6),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${(_currentRoute!.distanceMeters / 1000).toStringAsFixed(2)} km',
                            style: const TextStyle(color: Colors.white),
                          ),
                          Text(
                            _formatDuration(_currentRoute!.durationSeconds),
                            style: const TextStyle(color: Colors.white),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              setState(() {
                                _currentRoute = null;
                              });
                            },
                            child: const Text('Usuń'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              Positioned(
                right: 16,
                bottom: 16,
                child: FloatingActionButton(
                  onPressed: () {
                    if (_initialPosition != null && _places.isNotEmpty) {
                      final start = LatLng(
                          _initialPosition!.latitude, _initialPosition!.longitude);
                      final place = _places.first;
                      final end = LatLng(place.lat, place.lng);
                      _fetchRouteExample(start, end);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Brak pozycji lub miejsc do testu')),
                      );
                    }
                  },
                  child: _routeLoading ? const CircularProgressIndicator() : const Icon(Icons.directions),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
