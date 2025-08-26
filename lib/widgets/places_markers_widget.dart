import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:flutter_map_animations/flutter_map_animations.dart';
import 'package:latlong2/latlong.dart';
import '../models/place.dart';
import '../services/firestore_service.dart';
import '../services/location_service.dart';
import '../services/route_service.dart';
import 'place_details_sheet_widget.dart';
import 'package:toastification/toastification.dart';

class PlacesMarkersWidget extends StatefulWidget {
  final AnimatedMapController mapController;
  final String? cityId;
  final Function(Place)? onMarkerTap;
  final bool enableClustering;

  final void Function(RouteResult route, Place? place)? onRouteGenerated;

  const PlacesMarkersWidget({
    Key? key,
    required this.mapController,
    this.cityId,
    this.onMarkerTap,
    this.enableClustering = true,
    this.onRouteGenerated,
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

  @override
  void initState() {
    super.initState();
    _loadPlaces();
  }

  @override
  void didUpdateWidget(PlacesMarkersWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.cityId != widget.cityId) {
      _loadPlaces();
    }
  }

  Future<void> _loadPlaces() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final places = widget.cityId != null
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
      layers.add(MarkerClusterLayerWidget(
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
                color: Colors.red[700],
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
      ));
    } else {
      layers.add(MarkerLayer(markers: markers));
    }

    return Stack(children: layers);
  }

  Marker _buildMarker(Place place) {
    const double w = 40, h = 48;
    final bool isActive = place.id == _activePlaceId;

    return Marker(
      point: LatLng(place.lat, place.lng),
      width: w,
      height: h,
      alignment: Alignment.topCenter,
      child: GestureDetector(
        onTap: () async {
          setState(() => _activePlaceId = place.id);

          widget.mapController.animateTo(
            dest: LatLng(place.lat, place.lng),
            zoom: widget.mapController.mapController.camera.zoom,
          );

          await showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (context) => PlaceDetailsSheet(
              place: place,
              mapController: widget.mapController.mapController,
              onNavigate: (selectedPlace) async {
                try {
                  final userPos = await LocationService().getCurrentLocation();
                  final userLatLng = LatLng(userPos.latitude, userPos.longitude);
                  final routeResult = await _routeService.getWalkingRoute(
                    userLatLng,
                    LatLng(selectedPlace.lat, selectedPlace.lng),
                  );

                  widget.onRouteGenerated?.call(routeResult, selectedPlace);

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
          child: Image.asset(
            isActive ? 'assets/marker_active.png' : 'assets/marker.png',
            width: w,
            height: h,
            fit: BoxFit.contain,
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

    return LatLngBounds(
      LatLng(minLat, minLng),
      LatLng(maxLat, maxLng),
    );
  }
}
