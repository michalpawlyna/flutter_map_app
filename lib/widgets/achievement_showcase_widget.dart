import 'package:flutter/material.dart';
import 'package:dotted_border/dotted_border.dart';
import '../models/achievement.dart';
import '../models/user.dart';
import '../screens/manage_achievements_screen.dart';

class AchievementShowcaseWidget extends StatelessWidget {
  final List<String> equippedAchievementIds;
  final List<Achievement> allAchievements;
  final AppUser? user;

  const AchievementShowcaseWidget({
    Key? key,
    required this.equippedAchievementIds,
    required this.allAchievements,
    this.user,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final equippedAchievements = allAchievements
        .where((ach) => equippedAchievementIds.contains(ach.id))
        .toList();

    if (equippedAchievements.isEmpty && (user == null)) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardBg = isDark ? theme.cardColor : const Color(0xFFF8F9FA);
    final borderColor = isDark ? Colors.grey.shade800 : Colors.grey.shade200;

    // Only a single equipped achievement is allowed now.
    const int columns = 1;
    final int slots = columns;
    final int shown = equippedAchievements.isNotEmpty ? 1 : 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'Gablota osiągnięć',
                style: TextStyle(
                  fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
              ),
              if (user != null && allAchievements.isNotEmpty)
                GestureDetector(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ManageAchievementsScreen(
                          user: user!,
                          allAchievements: allAchievements,
                        ),
                      ),
                    );
                  },
                  child: Icon(
                    Icons.tune,
                    size: 20,
                    color: Colors.black87,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(slots, (index) {
              Widget slotChild;
              if (index < shown) {
                final achievement = equippedAchievements[index];
                slotChild = _AchievementTile(achievement: achievement);
              } else {
                slotChild = _AddSlotTile(
                  onTap: () {
                    if (user != null) {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => ManageAchievementsScreen(
                            user: user!,
                            allAchievements: allAchievements,
                          ),
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Zaloguj się, aby dodać odznakę')),
                      );
                    }
                  },
                );
              }

              return Expanded(
                child: Center(
                  child: SizedBox(
                    height: 90,
                    child: slotChild,
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _AchievementTile extends StatelessWidget {
  final Achievement achievement;

  const _AchievementTile({Key? key, required this.achievement}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: null,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          ClipOval(
            child: achievement.photoUrl != null
                ? Image.network(
                    achievement.photoUrl!,
                    width: 64,
                    height: 64,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 64,
                      height: 64,
                      alignment: Alignment.center,
                      color: Colors.grey.shade200,
                      child: const Icon(Icons.error),
                    ),
                  )
                : Container(
                    width: 64,
                    height: 64,
                    alignment: Alignment.center,
                    color: Colors.grey.shade200,
                    child: const Icon(Icons.shield),
                  ),
          ),
        ],
      ),
    );
  }
}

class _AddSlotTile extends StatelessWidget {
  final VoidCallback? onTap;

  const _AddSlotTile({Key? key, this.onTap}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? Colors.grey.shade700 : Colors.grey.shade300;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(999),
            onTap: onTap,
            child: DottedBorder(
              borderType: BorderType.Circle,
              dashPattern: const [6, 4],
              strokeWidth: 2,
              color: borderColor,
              radius: const Radius.circular(999),
              child: Container(
                width: 48,
                height: 48,
                alignment: Alignment.center,
                child: const Icon(Icons.add, size: 24),
              ),
            ),
          ),
        ),
      ],
    );
  }
}