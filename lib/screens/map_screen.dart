import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../widgets/user_location_widget.dart';
import '../widgets/center_on_user_button_widget.dart';
import '../widgets/navbar_widget.dart';
import '../widgets/places_markers_widget.dart'; // Add this import

class MapScreen extends StatefulWidget {
  const MapScreen({Key? key}) : super(key: key);

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  late final MapController _mapController;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: LatLng(52.0, 19.0), // Środek Polski
              initialZoom: 6.0,
              minZoom: 4.0,
              maxZoom: 18.0,
              
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
              ),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png',
                subdomains: const ['a', 'b', 'c', 'd'],
                retinaMode: RetinaMode.isHighDensity(context),
              ),

              // User location marker + accuracy circle
              UserLocationWidget(mapController: _mapController),

              // Places markers - Add this line
              PlacesMarkersWidget(mapController: _mapController),

              // TODO: add polyline layer for routes here
            ],
          ),

          // Center-on-user button
          CenterOnUserButton(mapController: _mapController),

          // Bottom navigation bar
          const NavbarWidget(selectedIndex: 0),
        ],
      ),
    );
  }
}