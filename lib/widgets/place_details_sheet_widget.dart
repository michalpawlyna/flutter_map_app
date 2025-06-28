import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../models/place.dart';

class PlaceDetailsSheet extends StatelessWidget {
  final Place place;
  final MapController? mapController;

  const PlaceDetailsSheet({
    Key? key,
    required this.place,
    this.mapController,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            place.name,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          if (place.address.isNotEmpty) ...[
            Text(
              place.address,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
          ],
          if (place.desc.isNotEmpty) ...[
            Text(
              place.desc,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
          ],
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
              if (mapController != null) ...[
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    mapController!.move(
                      LatLng(place.lat, place.lng),
                      15.0,
                    );
                  },
                  child: const Text('Go to Location'),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  static void show(
    BuildContext context,
    Place place, {
    MapController? mapController,
  }) {
    showModalBottomSheet(
      context: context,
      builder: (context) => PlaceDetailsSheet(
        place: place,
        mapController: mapController,
      ),
    );
  }
}