// lib/widgets/proximity_alert_dialog.dart
import 'package:flutter/material.dart';
import '../models/place.dart';
import '../services/tts_service.dart';

class ProximityAlertDialog extends StatefulWidget {
  final Place place;
  final VoidCallback onClose;
  final TtsService tts;

  const ProximityAlertDialog({
    Key? key,
    required this.place,
    required this.onClose,
    required this.tts,
  }) : super(key: key);

  @override
  State<ProximityAlertDialog> createState() => _ProximityAlertDialogState();
}

class _ProximityAlertDialogState extends State<ProximityAlertDialog> {
  String _composeSpeechText() {
    final b = StringBuffer();
    b.write(widget.place.name);
    if (widget.place.desc.isNotEmpty) {
      b.write('. ');
      b.write(widget.place.desc);
    }
    return b.toString();
  }

  Future<void> _closeDialog() async {
    // jeśli coś jest w trakcie odtwarzania -> zatrzymaj i poczekaj
    if (widget.tts.isSpeaking.value) {
      await widget.tts.stop();
    }
    widget.onClose();
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // jeśli back -> zatrzymaj i powiadom proximity service
        if (widget.tts.isSpeaking.value) {
          await widget.tts.stop();
        }
        widget.onClose();
        return true;
      },
      child: Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 32, vertical: 160),
        backgroundColor: Colors.transparent,
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 12),
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
                      color: Colors.red,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.place.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              const Text(
                'O miejscu',
                style: TextStyle(
                  fontSize: 15,
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

              const SizedBox(height: 18),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _closeDialog,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        side: BorderSide(color: Colors.black.withOpacity(0.08)),
                        foregroundColor: Colors.black87,
                        textStyle: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      child: const Text('Zamknij'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ValueListenableBuilder<bool>(
                      valueListenable: widget.tts.isSpeaking,
                      builder: (context, speaking, _) {
                        return ElevatedButton.icon(
                          onPressed: () async {
                            final text = _composeSpeechText();
                            // używamy toggle, bo poprawnie zarządza stanem
                            await widget.tts.toggle(text);
                            // ValueListenableBuilder odświeży przycisk
                          },
                          icon: speaking ? const Icon(Icons.stop) : const Icon(Icons.volume_up),
                          label: Text(speaking ? 'Zatrzymaj' : 'Odczytaj'),
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
                        );
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
