import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:latlong2/latlong.dart';
import '../models/place.dart';
import '../services/firestore_service.dart';
import 'place_details_sheet_widget.dart';

class PlacesMarkersWidget extends StatefulWidget {
  final MapController mapController;
  final String? cityId; // Optional: filter by city
  final Function(Place)? onMarkerTap; // Optional: callback when marker is tapped
  final bool enableClustering; // Enable/disable clustering

  const PlacesMarkersWidget({
    Key? key,
    required this.mapController,
    this.cityId,
    this.onMarkerTap,
    this.enableClustering = true, // Default to enabled
  }) : super(key: key);

  @override
  State<PlacesMarkersWidget> createState() => _PlacesMarkersWidgetState();
}

class _PlacesMarkersWidgetState extends State<PlacesMarkersWidget> {
  final FirestoreService _firestoreService = FirestoreService();
  List<Place> _places = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPlaces();
  }

  @override
  void didUpdateWidget(PlacesMarkersWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reload if cityId changed
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
      List<Place> places;
      if (widget.cityId != null) {
        places = await _firestoreService.getPlacesForCity(widget.cityId!);
      } else {
        places = await _firestoreService.getAllPlaces();
      }

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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox.shrink(); // Don't show anything while loading
    }

    if (_error != null) {
      // You could show an error indicator here if needed
      return const SizedBox.shrink();
    }

    if (widget.enableClustering) {
      return MarkerClusterLayerWidget(
        options: MarkerClusterLayerOptions(
          maxClusterRadius: 45,
          size: const Size(40, 40),
          markers: _places.map((place) => _buildMarker(place)).toList(),
          showPolygon: false,
          onClusterTap: (cluster) {
            // Handle cluster tap - zoom to fit all markers in cluster
            final group = cluster.markers;
            final bounds = _calculateBounds(group);
            widget.mapController.fitCamera(
              CameraFit.bounds(
                bounds: bounds,
                padding: const EdgeInsets.all(50),
                maxZoom: 15,
              ),
            );
          },
          builder: (context, markers) {
            return _buildClusterMarker(markers);
          },
        ),
      );
    } else {
      // Fallback to regular MarkerLayer if clustering is disabled
      return MarkerLayer(
        markers: _places.map((place) => _buildMarker(place)).toList(),
      );
    }
  }

  Marker _buildMarker(Place place) {
    return Marker(
      point: LatLng(place.lat, place.lng),
      width: 40,
      height: 40,
      child: GestureDetector(
        onTap: () {
          if (widget.onMarkerTap != null) {
            widget.onMarkerTap!(place);
          } else {
            _showDefaultPlaceDetails(place);
          }
        },
        child: Container(
          decoration: BoxDecoration(
            color: Colors.red,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: const Icon(
            Icons.place,
            color: Colors.white,
            size: 24,
          ),
        ),
      ),
    );
  }

  Widget _buildClusterMarker(List<Marker> markers) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.blue,
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Text(
          markers.length.toString(),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  LatLngBounds _calculateBounds(List<Marker> markers) {
    double minLat = double.infinity;
    double maxLat = double.negativeInfinity;
    double minLng = double.infinity;
    double maxLng = double.negativeInfinity;

    for (final marker in markers) {
      final lat = marker.point.latitude;
      final lng = marker.point.longitude;

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

  void _showDefaultPlaceDetails(Place place) {
    PlaceDetailsSheet.show(
      context,
      place,
      mapController: widget.mapController,
    );
  }
}