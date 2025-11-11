import 'package:flutter/material.dart';
import '../models/achievement.dart';

class AchievementUnlockedDialog extends StatelessWidget {
  final Achievement achievement;

  const AchievementUnlockedDialog({Key? key, required this.achievement}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      contentPadding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (achievement.photoUrl != null && achievement.photoUrl!.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                achievement.photoUrl!,
                width: 96,
                height: 96,
                fit: BoxFit.cover,
              ),
            ),
          const SizedBox(height: 12),
          Text(
            'Zdobyto osiągnięcie!',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.black87),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            achievement.title,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.black),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            achievement.desc,
            style: TextStyle(fontSize: 13, color: Colors.black54),
            textAlign: TextAlign.center,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('OK'),
        ),
      ],
    );
  }
}
