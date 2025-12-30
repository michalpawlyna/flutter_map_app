import 'package:cloud_firestore/cloud_firestore.dart';

enum AchievementType {
  visit,
  likePlace,
  createRoute,
  unknown;

  static AchievementType fromString(String type) {
    switch (type) {
      case 'visit':
        return AchievementType.visit;
      case 'like_place':
      case 'likePlace':
        return AchievementType.likePlace;
      case 'create_route':
      case 'createRoute':
        return AchievementType.createRoute;
      default:
        return AchievementType.unknown;
    }
  }

  String get asString {
    switch (this) {
      case AchievementType.visit:
        return 'visit';
      case AchievementType.likePlace:
        return 'likePlace';
      case AchievementType.createRoute:
        return 'createRoute';
      default:
        return 'unknown';
    }
  }
}

class Achievement {
  final String id;
  final Map<String, dynamic> criteria;
  final String desc;
  final String key;
  final String title;
  final String? photoUrl;
  final AchievementType type;
  final Timestamp? createdAt;

  Achievement({
    required this.id,
    required this.criteria,
    required this.desc,
    required this.key,
    required this.title,
    this.photoUrl,
    required this.type,
    this.createdAt,
  });

  factory Achievement.fromMap(String id, Map<String, dynamic> data) {
    return Achievement(
      id: id,
      criteria:
          (data['criteria'] as Map<String, dynamic>?) ?? <String, dynamic>{},
      desc: data['desc'] as String? ?? '',
      key: data['key'] as String? ?? id,
      title: data['title'] as String? ?? '',
      photoUrl: data['photoUrl'] as String?,
      type: AchievementType.fromString(data['type'] as String? ?? ''),
      createdAt: data['createdAt'] as Timestamp?,
    );
  }

  factory Achievement.fromSnapshot(
    DocumentSnapshot<Map<String, dynamic>> snap,
  ) {
    final data = snap.data() ?? <String, dynamic>{};
    return Achievement.fromMap(snap.id, data);
  }

  Map<String, dynamic> toMap() {
    return {
      'criteria': criteria,
      'desc': desc,
      'key': key,
      if (photoUrl != null) 'photoUrl': photoUrl,
      'title': title,
      'type': type.asString,
      if (createdAt != null) 'createdAt': createdAt,
    };
  }
}
