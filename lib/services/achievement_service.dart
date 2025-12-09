import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_map_app/models/achievement.dart';
import 'package:flutter_map_app/models/user.dart';

class AchievementService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<Achievement>> checkAndGrantAchievements(
      AppUser user, AchievementType type) async {
    if (type == AchievementType.unknown) {
      return [];
    }

    try {
      final achQuery = await _firestore
          .collection('achievements')
          .where('type', isEqualTo: type.asString)
          .get();

      final newlyUnlocked = <Achievement>[];
      final userRef = _firestore.collection('users').doc(user.uid);

      for (final achDoc in achQuery.docs) {
        final achievement = Achievement.fromSnapshot(achDoc);
        final alreadyUnlocked = user.achievementsSummary[achievement.id] == true;

        if (alreadyUnlocked) {
          continue;
        }

        final criteria = achievement.criteria;
        final target = (criteria['target'] as num?)?.toInt() ?? 0;
        if (target <= 0) {
          continue;
        }

        int userProgress = 0;
        switch (type) {
          case AchievementType.visit:
            userProgress = user.totalPlacesVisited;
            break;
          case AchievementType.likePlace:
            userProgress = user.totalPlacesLiked;
            break;
          case AchievementType.createRoute:
            userProgress = user.totalRoutesCreated;
            break;
          case AchievementType.unknown:
            break;
        }

        if (userProgress >= target) {
          newlyUnlocked.add(achievement);
          await userRef.set({
            'achievementsSummary': {achievement.id: true},
            'achievementsUnlockedAt': {achievement.id: FieldValue.serverTimestamp()},
          }, SetOptions(merge: true));
        }
      }
      return newlyUnlocked;
    } catch (e, st) {
      debugPrint('Error in checkAndGrantAchievements: $e\n$st');
      return [];
    }
  }
}
