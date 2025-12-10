import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:flutter_map_animations/flutter_map_animations.dart';
import 'package:latlong2/latlong.dart';
import '../models/place.dart';
import '../services/firestore_service.dart';
import '../services/location_service.dart';
import '../services/auth_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:geolocator/geolocator.dart';
import '../services/route_service.dart';
import 'place_details_sheet_widget.dart';
import 'achievement_unlocked_dialog.dart';
import 'package:toastification/toastification.dart';

class PlacesMarkersWidget extends StatefulWidget {
  final AnimatedMapController mapController;
  final String? cityId;
  final Function(Place)? onMarkerTap;
  final bool enableClustering;
  final List<String>? visitOrderIds;

  final void Function(RouteResult route, Place? place)? onRouteGenerated;

  const PlacesMarkersWidget({
    Key? key,
    required this.mapController,
    this.cityId,
    this.onMarkerTap,
    this.enableClustering = true,
    this.onRouteGenerated,
    this.visitOrderIds,
  }) : super(key: key);

  @override
  State<PlacesMarkersWidget> createState() => _PlacesMarkersWidgetState();
}

class _PlacesMarkersWidgetState extends State<PlacesMarkersWidget> {
  final FirestoreService _firestoreService = FirestoreService();
  final RouteService _routeService = RouteService();

  List<Place> _places = [];
  bool _isLoading = true;
  String? _error;
  String? _activePlaceId;
  final Set<String> _visitedPlaceIds = {};
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _userSub;
  StreamSubscription<User?>? _authSub;

  @override
  void initState() {
    super.initState();
    _loadPlaces();
    _subscribeToUserVisited();
    _authSub = AuthService().authStateChanges.listen((_) {
      _subscribeToUserVisited();
    });
  }

  void _subscribeToUserVisited() {
    _userSub?.cancel();
    final user = AuthService().currentUser;
    if (user == null) {
      if (mounted) {
        setState(() {
          _visitedPlaceIds.clear();
          _error = null;
        });
      }
      return;
    }

    _userSub = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .snapshots()
        .listen((snap) {
      try {
        final data = snap.data() ?? <String, dynamic>{};
        final visited = (data['visitedPlaces'] as List<dynamic>?)?.cast<String>() ?? <String>[];
        if (mounted) {
          setState(() {
            _visitedPlaceIds
              ..clear()
              ..addAll(visited);
            _error = null;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _visitedPlaceIds.clear();
            _error = e.toString();
          });
        }
      }
    }, onError: (err) {
      if (mounted) {
        if (err is FirebaseException && err.code == 'permission-denied') {
          setState(() {
            _visitedPlaceIds.clear();
            _error = null;
          });
        } else {
          setState(() {
            _visitedPlaceIds.clear();
            _error = err?.toString() ?? 'Błąd subskrypcji użytkownika';
          });
        }
      }
    });
  }

  @override
  void didUpdateWidget(PlacesMarkersWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.cityId != widget.cityId) {
      _loadPlaces();
    }
  }

  @override
  void dispose() {
    _userSub?.cancel();
    _authSub?.cancel();
    super.dispose();
  }

  Future<void> _reportRouteCreationInBackground(String uid) async {
    try {
      final unlockedAchievements = await _firestoreService.reportRouteCreation(uid);
      if (mounted && unlockedAchievements.isNotEmpty) {
        for (final ach in unlockedAchievements) {
          await AchievementUnlockedDialog.show(context, ach);
        }
      }
    } catch (e) {
      debugPrint('Error reporting route creation: $e');
    }
  }

  Future<void> _loadPlaces() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final places =
          widget.cityId != null
              ? await _firestoreService.getPlacesForCity(widget.cityId!)
              : await _firestore_service_getAllPlacesFallback();

      setState(() {
        _places = places;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<List<Place>> _firestore_service_getAllPlacesFallback() {
    return _firestoreService.getAllPlaces();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _error != null) {
      return const SizedBox.shrink();
    }

    final markers = _places.map((place) => _buildMarker(place)).toList();
    final List<Widget> layers = [];

    if (widget.enableClustering) {
      layers.add(
        MarkerClusterLayerWidget(
          options: MarkerClusterLayerOptions(
            maxClusterRadius: 45,
            size: const Size(40, 40),
            markers: markers,
            showPolygon: false,
            onClusterTap: (cluster) {
              final bounds = _calculateBounds(cluster.markers);
              widget.mapController.mapController.fitCamera(
                CameraFit.bounds(
                  bounds: bounds,
                  padding: const EdgeInsets.all(50),
                  maxZoom: 15,
                ),
              );
            },
            builder: (context, clusterMarkers) {
              return Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.black,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  clusterMarkers.length.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              );
            },
          ),
        ),
      );
    } else {
      layers.add(MarkerLayer(markers: markers));
    }

    return Stack(children: layers);
  }

  Marker _buildMarker(Place place) {
    const double w = 40, h = 48;
    final bool isActive = place.id == _activePlaceId;

    // Determine visit order index (if any)
    final int orderIdx = (widget.visitOrderIds?.indexOf(place.id) ?? -1);
    final bool hasOrder = (widget.visitOrderIds != null && (widget.visitOrderIds!.length ?? 0) > 1 && orderIdx >= 0);

    return Marker(
      point: LatLng(place.lat, place.lng),
      width: w,
      height: h,
      alignment: Alignment.topCenter,
      child: RepaintBoundary(
        child: Semantics(
          label: 'Punkt ${place.name}${hasOrder ? ', numer ${orderIdx + 1}' : ''}${_visitedPlaceIds.contains(place.id) ? ', odwiedzony' : ''}',
          child: GestureDetector(
            onTap: () async {
              setState(() => _activePlaceId = place.id);

              // animate to marker
              try {
                widget.mapController.animateTo(
                  dest: LatLng(place.lat, place.lng),
                  zoom: widget.mapController.mapController.camera.zoom,
                );
              } catch (e) {
                // ignore animation errors
              }

              await showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (context) => PlaceDetailsSheet(
                  place: place,
                  mapController: widget.mapController.mapController,
                  onNavigate: (selectedPlace) async {
                    try {
                      await LocationService().ensureLocationEnabledAndPermitted();
                      Position? last = await Geolocator.getLastKnownPosition();
                      final userPos = last ??
                          await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
                      final userLatLng = LatLng(
                        userPos.latitude,
                        userPos.longitude,
                      );
                      final routeResult = await _routeService.getWalkingRoute(
                        userLatLng,
                        LatLng(selectedPlace.lat, selectedPlace.lng),
                      );

                      widget.onRouteGenerated?.call(routeResult, selectedPlace);

                      // Raportuj utworzenie trasy w tle
                      final user = AuthService().currentUser;
                      if (user != null) {
                        _reportRouteCreationInBackground(user.uid);
                      }

                      if (routeResult.points.isNotEmpty) {
                        widget.mapController.mapController.fitCamera(
                          CameraFit.bounds(
                            bounds: LatLngBounds.fromPoints(routeResult.points),
                            padding: const EdgeInsets.all(40),
                          ),
                        );
                      }

                      Navigator.of(context).pop();
                    } catch (e) {
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
                  },
                ),
              );

              setState(() => _activePlaceId = null);
            },
            child: AnimatedScale(
              scale: isActive ? 1.2 : 1.0,
              duration: const Duration(milliseconds: 200),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Image.asset(
                    isActive ? 'assets/marker_active.png' : 'assets/marker.png',
                    width: w,
                    height: h,
                    fit: BoxFit.contain,
                  ),

                  // visited badge (check)
                  if (_visitedPlaceIds.contains(place.id))
                    Positioned(
                      left: -2,
                      bottom: -2,
                      child: Container(
                        width: 18,
                        height: 18,
                        decoration: BoxDecoration(
                          color: Colors.lightBlue[50],
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.check,
                          color: Colors.blue.shade800,
                          size: 12,
                        ),
                      ),
                    ),

                  // numerical order badge (NumberBadge) — nicer wygląd
                  if (hasOrder)
                    Positioned(
                      right: -8,
                      top: -8,
                      child: NumberBadge(
                        number: orderIdx + 1,
                        isActive: isActive,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  LatLngBounds _calculateBounds(List<Marker> markers) {
    double minLat = double.infinity,
        maxLat = double.negativeInfinity,
        minLng = double.infinity,
        maxLng = double.negativeInfinity;

    for (final m in markers) {
      final lat = m.point.latitude, lng = m.point.longitude;
      if (lat < minLat) minLat = lat;
      if (lat > maxLat) maxLat = lat;
      if (lng < minLng) minLng = lng;
      if (lng > maxLng) maxLng = lng;
    }

    return LatLngBounds(LatLng(minLat, minLng), LatLng(maxLat, maxLng));
  }
}

/// A compact circular badge that displays a number.
/// - Automatically adjusts size for 1 vs 2+ digits.
/// - Has white border for contrast on varied marker images.
/// - Changes background color when `isActive == true`.
class NumberBadge extends StatelessWidget {
  final int number;
  final bool isActive;

  const NumberBadge({Key? key, required this.number, this.isActive = false}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bool twoDigits = number >= 10;
    final double size = twoDigits ? 22.0 : 18.0;
    final Color bg = isActive ? Colors.orange.shade700 : Colors.black;
    final Color textColor = Colors.white;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: bg,
        shape: BoxShape.circle,
      ),
      child: Text(
        '$number',
        style: TextStyle(
          color: textColor,
          fontSize: twoDigits ? 11 : 12,
          fontWeight: FontWeight.w700,
          height: 1,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
