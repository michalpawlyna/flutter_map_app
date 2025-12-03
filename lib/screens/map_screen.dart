import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_animations/flutter_map_animations.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:toastification/toastification.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../widgets/user_location_widget.dart';
import '../widgets/center_on_user_button_widget.dart';
import '../widgets/places_markers_widget.dart';
import '../widgets/proximity_alert_dialog.dart';
import '../models/place.dart';
import '../services/location_service.dart';
import '../services/firestore_service.dart';
import '../services/tts_service.dart';
import '../services/proximity_service.dart';
import '../services/auth_service.dart';
import '../models/achievement.dart';
import '../widgets/achievement_unlocked_dialog.dart';

import '../services/route_service.dart';
import '../widgets/route_polyline_widget.dart';
import '../widgets/route_info_widget.dart';
import '../widgets/menu_button_widget.dart';
import 'loading_screen.dart';

class MapScreen extends StatefulWidget {
  final GlobalKey<ScaffoldState> scaffoldKey;
  final ValueNotifier<Map<String, dynamic>?>? routeResultNotifier;

  const MapScreen({
    Key? key,
    required this.scaffoldKey,
    this.routeResultNotifier,
  }) : super(key: key);

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

  final FirestoreService _firestoreService = FirestoreService();
  final LocationService _locationService = LocationService();
  final TtsService _tts = TtsService();

  ProximityService? _proximityService;
  StreamSubscription<Position>? _locSub;
  List<Place> _places = [];

  RouteResult? _currentRoute;
  String? _destinationName;
  List<String>? _visitOrderIds;

  @override
  void initState() {
    super.initState();
    _animatedMapController = AnimatedMapController(vsync: this);
    _initializationFuture = _initializeServicesAndLocationStream().then((_) {
      debugPrint('[MapScreen] initialization future completed');
    });
    widget.routeResultNotifier?.addListener(_handleExternalRouteResult);
  }

  void _handleExternalRouteResult() {
    final result = widget.routeResultNotifier?.value;
    if (result == null) return;

    if (result['route'] is RouteResult) {
      setState(() {
        _currentRoute = result['route'] as RouteResult;
        final places = result['places'] as List<dynamic>?;
        _visitOrderIds =
            places
                ?.map((e) => e['id'] as String? ?? '')
                .where((s) => s.isNotEmpty)
                .toList();
      });

      if (_currentRoute != null && _currentRoute!.points.isNotEmpty) {
        _animatedMapController.mapController.fitCamera(
          CameraFit.bounds(
            bounds: LatLngBounds.fromPoints(_currentRoute!.points),
            padding: const EdgeInsets.all(40),
          ),
        );
      }
    }
    widget.routeResultNotifier?.value = null;
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

    await _locationService.startUpdates(startMode: LocationMode.normal);

    _positionStream = _locationService.positionStream;

    await _initProximity(_positionStream);

    try {
      Position? initialPos = await Geolocator.getLastKnownPosition();
      if (initialPos == null) {
        initialPos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );
      }
      _initialCenter = LatLng(initialPos.latitude, initialPos.longitude);
      debugPrint('[MapScreen] initial center set to $_initialCenter');
    } catch (e) {
      debugPrint('[MapScreen] could not get explicit initial position: $e');
    }
  }

  Future<void> _initProximity(Stream<Position> positionStream) async {
    final places = await _firestore_service_getAllPlaces();
    if (!mounted) return;

    _places = places;

    _proximityService = ProximityService(
      places: _places,
      minEnterTimeSeconds: 15.0,
      onDetected: (place) async {
        if (!mounted) return;

        final user = AuthService().currentUser;
        if (user != null) {
          try {
            final res = await _firestoreService.reportPlaceVisit(
              uid: user.uid,
              place: place,
            );
            // Do not show toasts about simple visits. If the visit unlocked achievements,
            // fetch achievement docs and show the unlocked dialog for each.
            if (res.unlockedAchievementIds.isNotEmpty) {
              for (final achId in res.unlockedAchievementIds) {
                final achSnap =
                    await FirebaseFirestore.instance
                        .collection('achievements')
                        .doc(achId)
                        .get();
                if (achSnap.exists) {
                  final ach = Achievement.fromSnapshot(achSnap);
                  // show a blocking dialog so user can acknowledge the achievement
                  await showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (_) => AchievementUnlockedDialog(achievement: ach),
                  );
                }
              }
            }
          } catch (e) {
            toastification.show(
              context: context,
              title: Text('Błąd zapisu wizyty: ${e.toString()}'),
              style: ToastificationStyle.flat,
              type: ToastificationType.error,
              autoCloseDuration: const Duration(seconds: 4),
              alignment: Alignment.bottomCenter,
              margin: const EdgeInsets.fromLTRB(12, 0, 12, 24),
            );
          }
        }

        showDialog(
          context: context,
          barrierDismissible: false,
          builder:
              (ctx) => ProximityAlertDialog(
                place: place,
                tts: _tts,
                onClose: () => _proximityService?.alertClosed(),
              ),
        );
      },
    );

    _locSub = positionStream.listen(
      (pos) {
        _proximityService?.onPosition(pos);
      },
      onError: (e) {
        if (mounted) {
          toastification.show(
            context: context,
            title: Text('Błąd strumienia lokalizacji: ${e.toString()}'),
            style: ToastificationStyle.flat,
            type: ToastificationType.error,
            autoCloseDuration: const Duration(seconds: 4),
            alignment: Alignment.bottomCenter,
            margin: const EdgeInsets.fromLTRB(12, 0, 12, 24),
          );
        }
      },
    );
  }

  Future<List<Place>> _firestore_service_getAllPlaces() =>
      _firestoreService.getAllPlaces();

  @override
  void dispose() {
    widget.routeResultNotifier?.removeListener(_handleExternalRouteResult);

    _locSub?.cancel();
    _proximityService = null;

    _locationService.dispose().catchError((e) {
      debugPrint('[MapScreen] error disposing location service: $e');
    });

    _tts.dispose();
    _animatedMapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return FutureBuilder<void>(
      future: _initializationFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LoadingScreen();
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
                        'https://{s}.basemaps.cartocdn.com/rastertiles/light_all/{z}/{x}/{y}{r}.png',
                    subdomains: const ['a', 'b', 'c', 'd'],
                    retinaMode: RetinaMode.isHighDensity(context),
                  ),
                  if (_currentRoute != null)
                    RoutePolylineWidget(points: _currentRoute!.points),
                  PlacesMarkersWidget(
                    mapController: _animatedMapController,
                    visitOrderIds: _visitOrderIds,
                    onRouteGenerated: (route, place) {
                      setState(() {
                        _currentRoute = route;
                        _destinationName = null;
                        if (place != null) {
                          _visitOrderIds = [place.id];
                        } else {
                          _visitOrderIds = null;
                        }
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
                  UserLocationWidget(positionStream: _positionStream),
                ],
              ),
              CenterOnUserButton(mapController: _animatedMapController),
              MenuButton(scaffoldKey: widget.scaffoldKey),
              RouteInfoWidget(
                route: _currentRoute,
                destinationName: _destinationName,
                locationService: _locationService,
                onClear: () {
                  setState(() {
                    _currentRoute = null;
                    _destinationName = null;
                    _visitOrderIds = null;
                  });
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
