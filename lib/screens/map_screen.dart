import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_animations/flutter_map_animations.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:toastification/toastification.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/map_style.dart';
import '../services/map_style_notifier.dart';
import '../widgets/user_location_widget.dart';
import '../widgets/center_on_user_button_widget.dart';
import '../widgets/places_markers_widget.dart';
import '../models/place.dart';
import '../widgets/place_details_sheet_widget.dart';
import '../services/location_service.dart';
import '../services/firestore_service.dart';
import '../services/tts_service.dart';
import '../services/proximity_service.dart';
import '../services/auth_service.dart';
import '../widgets/achievement_unlocked_dialog.dart';

import '../services/route_service.dart';
import '../widgets/route_polyline_widget.dart';
import '../widgets/route_info_widget.dart';
import '../widgets/menu_button_widget.dart';
import 'loading_screen.dart';

class MapScreen extends StatefulWidget {
  final GlobalKey<ScaffoldState> scaffoldKey;
  final String? initialPlaceId;
  final ValueNotifier<Map<String, dynamic>?>? routeResultNotifier;

  const MapScreen({
    Key? key,
    required this.scaffoldKey,
    this.routeResultNotifier,
    this.initialPlaceId,
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
  StreamSubscription<Object?>? _mapStyleSub;
  List<Place> _places = [];

  RouteResult? _currentRoute;
  String? _destinationName;
  List<String>? _visitOrderIds;

  MapStyle _currentMapStyle = MapStyle.lightAll;
  final ValueNotifier<MapStyle> _mapStyleNotifier =
      ValueNotifier(MapStyle.lightAll);

  final GlobalKey _routeInfoKey = GlobalKey();

  final MapStyleNotifier _mapStyleService = MapStyleNotifier();

  @override
  void initState() {
    super.initState();
    _animatedMapController = AnimatedMapController(vsync: this);
    _initializationFuture = _initializeServicesAndLocationStream().then((_) {
      debugPrint('[MapScreen] initialization future completed');
    });
    widget.routeResultNotifier?.addListener(_handleExternalRouteResult);
    _mapStyleNotifier.addListener(_onMapStyleChanged);
    _mapStyleService.notifier.addListener(_onGlobalMapStyleChanged);
  }

  void _onMapStyleChanged() {
    setState(() {
      _currentMapStyle = _mapStyleNotifier.value;
    });
  }

  void _onGlobalMapStyleChanged() {
    setState(() {
      _currentMapStyle = _mapStyleService.notifier.value;
    });
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
        _fitRouteWithPadding();
      }

      _reportRouteCreationInBackground();
    }
    if (result['placeId'] is String) {
      final pid = result['placeId'] as String;
      Place? found;
      try {
        found = _places.firstWhere((p) => p.id == pid);
      } catch (_) {
        found = null;
      }

      if (found != null && mounted) {
        try {
          _animatedMapController.mapController.move(
            LatLng(found.lat, found.lng),
            15.0,
          );
        } catch (_) {}

        try {
          PlaceDetailsSheet.show(
            context,
            found,
            mapController: _animatedMapController.mapController,
            onNavigate: (selectedPlace) async {
              try {
                await _locationService.ensureLocationEnabledAndPermitted();
                Position? last = await Geolocator.getLastKnownPosition();
                final userPos =
                    last ??
                    await Geolocator.getCurrentPosition(
                      desiredAccuracy: LocationAccuracy.high,
                    );
                final userLatLng = LatLng(userPos.latitude, userPos.longitude);

                final routeResult = await RouteService().getWalkingRoute(
                  userLatLng,
                  LatLng(selectedPlace.lat, selectedPlace.lng),
                );

                if (!mounted) return;

                setState(() {
                  _currentRoute = routeResult;
                  _destinationName = selectedPlace.name;
                  _visitOrderIds = [selectedPlace.id];
                });

                if (_currentRoute != null && _currentRoute!.points.isNotEmpty) {
                  _fitRouteWithPadding();
                }

                _reportRouteCreationInBackground();

                Navigator.of(context).pop();
              } catch (e) {
                if (mounted) {
                  toastification.show(
                    context: context,
                    title: Text('Błąd trasy: ${e.toString()}'),
                    style: ToastificationStyle.flat,
                    type: ToastificationType.error,
                    autoCloseDuration: const Duration(seconds: 4),
                    alignment: Alignment.bottomCenter,
                    margin: const EdgeInsets.fromLTRB(12, 0, 12, 24),
                  );
                }
              }
            },
          );
        } catch (_) {}
      }
    }
    widget.routeResultNotifier?.value = null;
  }

  Future<void> _reportRouteCreationInBackground() async {
    try {
      final user = AuthService().currentUser;
      if (user == null || !mounted) return;

      final unlockedAchievements = await _firestoreService.reportRouteCreation(
        user.uid,
      );
      if (mounted && unlockedAchievements.isNotEmpty) {
        for (final ach in unlockedAchievements) {
          await AchievementUnlockedDialog.show(context, ach);
        }
      }
    } catch (e) {
      debugPrint('Error reporting route creation: $e');
    }
  }

  Future<void> _initializeServicesAndLocationStream() async {
    try {
      await _location_service_ensureAndPrepare();
      if (widget.initialPlaceId != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          try {
            final id = widget.initialPlaceId!;
            Place? found;
            try {
              found = _places.firstWhere((p) => p.id == id);
            } catch (_) {
              found = null;
            }

            if (found != null && mounted) {
              final lat = found.lat ?? 0.0;
              final lng = found.lng ?? 0.0;
              try {
                _animatedMapController.mapController.move(
                  LatLng(lat, lng),
                  15.0,
                );
              } catch (_) {}

              try {
                await PlaceDetailsSheet.show(
                  context,
                  found,
                  mapController: _animatedMapController.mapController,
                );
              } catch (_) {}
            }
          } catch (_) {}
        });
      }
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

    // Load map style from SharedPreferences
    await _loadMapStyle();

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

  Future<void> _loadMapStyle() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final styleValue = prefs.getString('map_style');
      final style = MapStyleExtension.fromStringValue(styleValue);
      setState(() {
        _currentMapStyle = style;
        _mapStyleNotifier.value = style;
      });
      // Update global notifier
      _mapStyleService.setMapStyle(style);
    } catch (e) {
      debugPrint('[MapScreen] error loading map style: $e');
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
            if (res.unlockedAchievements.isNotEmpty) {
              for (final ach in res.unlockedAchievements) {
                await showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (_) => AchievementUnlockedDialog(achievement: ach),
                );
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

  List<Place> _getVisitedPlaces() {
    if (_visitOrderIds == null || _visitOrderIds!.isEmpty) {
      return [];
    }
    
    final visited = <Place>[];
    for (final id in _visitOrderIds!) {
      try {
        final place = _places.firstWhere((p) => p.id == id);
        visited.add(place);
      } catch (_) {
        // Place not found, skip
      }
    }
    return visited;
  }

  void _fitRouteWithPadding() {
    if (_currentRoute == null || _currentRoute!.points.isEmpty) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final RenderBox? routeInfoRender =
          _routeInfoKey.currentContext?.findRenderObject() as RenderBox?;

      double bottomPadding = 40;

      if (routeInfoRender != null) {
        bottomPadding = routeInfoRender.size.height + 20;
      }

      _animatedMapController.mapController.fitCamera(
        CameraFit.bounds(
          bounds: LatLngBounds.fromPoints(_currentRoute!.points),
          padding: EdgeInsets.only(
            top: 60,
            left: 60,
            right: 60,
            bottom: bottomPadding,
          ),
        ),
      );
    });
  }

  @override
  void dispose() {
    widget.routeResultNotifier?.removeListener(_handleExternalRouteResult);
    _mapStyleNotifier.removeListener(_onMapStyleChanged);
    _mapStyleService.notifier.removeListener(_onGlobalMapStyleChanged);

    _locSub?.cancel();
    _mapStyleSub?.cancel();
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
                    urlTemplate: _currentMapStyle.urlTemplate,
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
                      _fitRouteWithPadding();
                    },
                  ),
                  UserLocationWidget(positionStream: _positionStream),
                ],
              ),
              CenterOnUserButton(mapController: _animatedMapController),
              MenuButton(scaffoldKey: widget.scaffoldKey),
              RouteInfoWidget(
                key: _routeInfoKey,
                route: _currentRoute,
                destinationName: _destinationName,
                locationService: _locationService,
                visitedPlaces: _getVisitedPlaces(),
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
