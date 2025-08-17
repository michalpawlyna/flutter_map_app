import 'package:flutter/material.dart';
import '../services/route_service.dart';

/// Widget wyświetlający informacje o aktualnej trasie.
///
/// Przeznaczony do umieszczenia jako dziecko głównego `Stack` w `MapScreen`.
/// Wystarczy podać aktualny `RouteResult?` oraz callback do usuwania trasy.
class RouteInfoWidget extends StatelessWidget {
  final RouteResult? route;
  final VoidCallback onClear;

  const RouteInfoWidget({
    Key? key,
    required this.route,
    required this.onClear,
  }) : super(key: key);

  String _formatDuration(double seconds) {
    final dur = Duration(seconds: seconds.round());
    final hours = dur.inHours;
    final minutes = dur.inMinutes.remainder(60);
    if (hours > 0) return '${hours}h ${minutes}m';
    return '${minutes} min';
  }

  @override
  Widget build(BuildContext context) {
    if (route == null) return const SizedBox.shrink();

    return Positioned(
      bottom: 16,
      left: 16,
      right: 16,
      child: SafeArea(
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Nagłówek z ikoną
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.directions,
                      color: Colors.blue,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Informacje o trasie',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Informacje o trasie
              Row(
                children: [
                  Expanded(
                    child: _InfoTile(
                      icon: Icons.straighten,
                      label: 'Dystans',
                      value: '${(route!.distanceMeters / 1000).toStringAsFixed(2)} km',
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _InfoTile(
                      icon: Icons.schedule,
                      label: 'Czas',
                      value: _formatDuration(route!.durationSeconds),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Przycisk usuwania
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: onClear,
                  icon: const Icon(Icons.close, size: 18),
                  label: const Text('Usuń trasę'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade50,
                    foregroundColor: Colors.red.shade700,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: Colors.red.shade200),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 16,
                color: Colors.grey.shade600,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}