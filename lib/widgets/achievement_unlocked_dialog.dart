import 'dart:math';
import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import '../models/achievement.dart';

class AchievementUnlockedDialog extends StatefulWidget {
  final Achievement achievement;

  const AchievementUnlockedDialog({Key? key, required this.achievement})
    : super(key: key);

  @override
  State<AchievementUnlockedDialog> createState() =>
      _AchievementUnlockedDialogState();

  static Future<void> show(BuildContext context, Achievement achievement) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AchievementUnlockedDialog(achievement: achievement),
    );
  }
}

class _AchievementUnlockedDialogState extends State<AchievementUnlockedDialog> {
  late final ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _confettiController.play();
    });
  }

  @override
  void dispose() {
    _confettiController.stop();
    _confettiController.dispose();
    super.dispose();
  }

  void _closeDialog() {
    _confettiController.stop();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      content: SizedBox(
        width: 340,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.achievement.photoUrl != null &&
                    widget.achievement.photoUrl!.isNotEmpty)
                  ClipOval(
                    child: Image.network(
                      widget.achievement.photoUrl!,
                      width: 160,
                      height: 160,
                      fit: BoxFit.cover,
                      errorBuilder:
                          (_, __, ___) => const Icon(
                            Icons.star,
                            size: 120,
                            color: Colors.amber,
                          ),
                    ),
                  )
                else
                  const CircleAvatar(
                    radius: 80,
                    backgroundColor: Colors.transparent,
                    child: Icon(Icons.star, size: 120, color: Colors.amber),
                  ),

                const SizedBox(height: 20),
                const Text(
                  'Gratulacje!',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                Text(
                  'Udało ci się odblokować osiągnięcie "${widget.achievement.title}". Odkrywaj dalej i zdobądź je wszystkie!',
                  style: const TextStyle(fontSize: 14, color: Colors.black54),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _closeDialog,
                    icon: const Icon(Icons.check),
                    label: const Text('Świetnie!'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
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

            Positioned(
              top: -40,
              left: 0,
              right: 0,
              child: Align(
                alignment: Alignment.topCenter,
                child: SizedBox(
                  width: 1,
                  height: 120,
                  child: ConfettiWidget(
                    confettiController: _confettiController,
                    blastDirectionality: BlastDirectionality.explosive,
                    emissionFrequency: 0.03,
                    numberOfParticles: 6,
                    maxBlastForce: 8,
                    minBlastForce: 4,
                    gravity: 0.4,
                    shouldLoop: true,
                    createParticlePath: _smallStar,
                  ),
                ),
              ),
            ),

            Positioned(
              bottom: -20,
              left: 0,
              right: 0,
              child: Align(
                alignment: Alignment.bottomCenter,
                child: SizedBox(
                  width: 1,
                  height: 80,
                  child: ConfettiWidget(
                    confettiController: _confettiController,
                    blastDirection: -pi / 2,
                    blastDirectionality: BlastDirectionality.directional,
                    emissionFrequency: 0.02,
                    numberOfParticles: 4,
                    maxBlastForce: 7,
                    minBlastForce: 3,
                    gravity: 0.35,
                    shouldLoop: true,
                    createParticlePath: _tinyDiamond,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Path _smallStar(Size size) {
    final Path path = Path();
    final double w = 8;
    final double h = 8;
    final double cx = w / 2;
    final double cy = h / 2;
    const int points = 5;
    final double step = pi / points;
    final double ext = w / 2;
    final double inner = ext / 2.5;
    for (int i = 0; i < 2 * points; i++) {
      final double r = (i % 2 == 0) ? ext : inner;
      final double x = cx + r * cos(i * step);
      final double y = cy + r * sin(i * step);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    return path;
  }

  Path _tinyDiamond(Size size) {
    final Path path = Path();
    final double w = 6;
    final double h = 6;
    path.moveTo(w / 2, 0);
    path.lineTo(w, h / 2);
    path.lineTo(w / 2, h);
    path.lineTo(0, h / 2);
    path.close();
    return path;
  }
}
