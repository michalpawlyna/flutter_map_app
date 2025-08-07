import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_animations/flutter_map_animations.dart';
import 'package:latlong2/latlong.dart';
import '../widgets/user_location_widget.dart';
import '../widgets/center_on_user_button_widget.dart';
import '../widgets/navbar_widget.dart';
import '../widgets/places_markers_widget.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({Key? key}) : super(key: key);

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> with TickerProviderStateMixin {
  late final AnimatedMapController _animatedMapController;

  @override
  void initState() {
    super.initState();
    _animatedMapController = AnimatedMapController(vsync: this);
  }

  @override
  void dispose() {
    _animatedMapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: _animatedMapController.mapController,
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
              UserLocationWidget(mapController: _animatedMapController.mapController),

              // Places markers with smooth animations
              PlacesMarkersWidget(mapController: _animatedMapController),
            ],
          ),

          // Center-on-user button
          CenterOnUserButton(mapController: _animatedMapController), // Zmieniono tutaj!
        ],
      ),
    );
  }
}