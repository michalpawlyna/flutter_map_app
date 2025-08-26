import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import '../models/place.dart';
import '../services/tts_service.dart';

class PlaceDetailsSheet extends StatefulWidget {
  final Place place;
  final MapController? mapController;
  final Future<void> Function(Place)? onNavigate;

  const PlaceDetailsSheet({
    Key? key,
    required this.place,
    this.mapController,
    this.onNavigate,
  }) : super(key: key);

  @override
  State<PlaceDetailsSheet> createState() => _PlaceDetailsSheetState();
}

class _PlaceDetailsSheetState extends State<PlaceDetailsSheet> {
  bool _loading = false;
  late final TtsService _tts;

  @override
  void initState() {
    super.initState();
    _tts = TtsService();
  }

  @override
  void dispose() {
    _tts.dispose();
    super.dispose();
  }

  String _composeSpeechText() {
    final b = StringBuffer();
    b.write(widget.place.name);
    if (widget.place.desc.isNotEmpty) {
      b.write('. ');
      b.write(widget.place.desc);
    }
    return b.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.red[100],
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.location_on,
                  color: Color(0xFFF44336),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.place.name,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 3),
                    if (widget.place.address.isNotEmpty)
                      Text(
                        widget.place.address,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'O miejscu',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          if (widget.place.desc.isNotEmpty)
            Text(
              widget.place.desc,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black54,
                height: 1.4,
              ),
            ),
          const SizedBox(height: 20),

          Row(
            children: [
              SizedBox(
                width: 44,
                height: 44,
                child: ValueListenableBuilder<bool>(
                  valueListenable: _tts.isSpeaking,
                  builder: (context, speaking, _) {
                    return OutlinedButton(
                      onPressed: () async {
                        final text = _composeSpeechText();
                        await _tts.toggle(text);
                      },
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        side: BorderSide(color: Colors.black.withOpacity(0.08)),
                        backgroundColor: Colors.grey.shade100,
                        foregroundColor: Colors.black87,
                      ),
                      child: Icon(speaking ? Icons.stop : Icons.volume_up),
                    );
                  },
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _loading
                      ? null
                      : () async {
                          if (widget.onNavigate != null) {
                            setState(() => _loading = true);
                            await widget.onNavigate!(widget.place);
                            if (mounted) setState(() => _loading = false);
                          }
                        },
                  icon: _loading
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : const Icon(Icons.navigation),
                  label: Text(_loading ? 'Tworzenie trasy...' : 'Nawiguj'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  static void show(
    BuildContext context,
    Place place, {
    MapController? mapController,
    Future<void> Function(Place)? onNavigate,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => PlaceDetailsSheet(
        place: place,
        mapController: mapController,
        onNavigate: onNavigate,
      ),
    );
  }
}
