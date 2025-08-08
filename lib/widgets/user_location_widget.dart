import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../services/location_service.dart';
import 'dart:async';

class UserLocationWidget extends StatefulWidget {
  final MapController mapController;
  final double accuracyRadius;
  final bool autoCenter; // Whether to auto-center map on location updates
  
  const UserLocationWidget({
    required this.mapController,
    this.accuracyRadius = 25.0,
    this.autoCenter = false,
    Key? key,
  }) : super(key: key);
  
  @override
  _UserLocationWidgetState createState() => _UserLocationWidgetState();
}

class _UserLocationWidgetState extends State<UserLocationWidget> {
  LatLng? _position;
  StreamSubscription<Position>? _locationSubscription;
  
  @override
  void initState() {
    super.initState();
    _initLocation();
  }
  
  Future<void> _initLocation() async {
    try {
      // Get initial location
      final pos = await LocationService().getCurrentLocation();
      setState(() {
        _position = LatLng(pos.latitude, pos.longitude);
      });
      
      if (widget.autoCenter && _position != null) {
        widget.mapController.move(_position!, widget.mapController.camera.zoom);
      }
      
      // Start continuous location updates
      _startLocationStream();
    } catch (e) {
      debugPrint('Failed to get initial location: $e');
    }
  }
  
  void _startLocationStream() {
    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10, // Update when user moves 10 meters
      timeLimit: Duration(seconds: 30), // Maximum time to wait for location
    );
    
    _locationSubscription = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen(
      (Position position) {
        final newPosition = LatLng(position.latitude, position.longitude);
        
        setState(() {
          _position = newPosition;
        });
        
        // Optional: Auto-center map on location updates
        if (widget.autoCenter) {
          widget.mapController.move(newPosition, widget.mapController.camera.zoom);
        }
      },
      onError: (error) {
        debugPrint('Location stream error: $error');
      },
    );
  }
  
  @override
  void dispose() {
    _locationSubscription?.cancel();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    if (_position == null) return const SizedBox.shrink();
    
    return Stack(
      children: [
        /// Accuracy circle
        CircleLayer(
          circles: [
            CircleMarker(
              point: _position!,
              useRadiusInMeter: true,
              radius: widget.accuracyRadius,
              color: Colors.blue.withOpacity(0.2),
            ),
          ],
        ),
        /// User position dot
        MarkerLayer(
          markers: [
            Marker(
              point: _position!,
              width: 20,
              height: 20,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.blue,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white,
                    width: 3,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}