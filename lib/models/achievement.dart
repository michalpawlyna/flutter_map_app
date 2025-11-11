import 'package:cloud_firestore/cloud_firestore.dart';

class Achievement {
  final String id;
  final Map<String, dynamic> criteria;
  final String desc;
  final String key;
  final String title;
  final String? photoUrl;
  final String type;
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
      criteria: (data['criteria'] as Map<String, dynamic>?) ?? <String, dynamic>{},
      desc: data['desc'] as String? ?? '',
      key: data['key'] as String? ?? id,
      title: data['title'] as String? ?? '',
      photoUrl: data['photoUrl'] as String?,
      type: data['type'] as String? ?? '',
      createdAt: data['createdAt'] as Timestamp?,
    );
  }

  factory Achievement.fromSnapshot(DocumentSnapshot<Map<String, dynamic>> snap) {
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
      'type': type,
      if (createdAt != null) 'createdAt': createdAt,
    };
  }
}
