import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:ui';
import 'package:flutter/material.dart';

import '../models/achievement.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';

class AchievementsScreen extends StatefulWidget {
  const AchievementsScreen({Key? key}) : super(key: key);

  @override
  State<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends State<AchievementsScreen> {
  String? expandedId;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_sharp),
        onPressed: () => Navigator.of(context).maybePop(),
        tooltip: 'Powrót',
      ),
      title: const Text(
        'Osiągnięcia',
        style: TextStyle(
          color: Colors.black,
          fontWeight: FontWeight.w600,
          fontSize: 20,
        ),
      ),
      centerTitle: true,
      backgroundColor: Colors.white,
      foregroundColor: Colors.black,
      elevation: 0,
    ),
    backgroundColor: Colors.white,
    body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('achievements').snapshots(),
      builder: (context, snap) {
        if (snap.hasError) {
          return Center(child: Text('Błąd: ${snap.error}'));
        }
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snap.data?.docs ?? [];
        if (docs.isEmpty) {
          return const Center(child: Text('Brak osiągnięć'));
        }

        final items = docs.map((d) => Achievement.fromSnapshot(d)).toList();

        final user = AuthService().currentUser;
        if (user == null) {
          return Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 32,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.amber[100],
                        ),
                        child: const Icon(
                          Icons.lock_outline,
                          size: 64,
                          color: Colors.black54,
                        ),
                      ),
                      const SizedBox(height: 32),
                      const Text(
                        'Zaloguj się, aby zobaczyć osiągnięcia',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Colors.black,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Twoje postępy i zdobyte osiągnięcia będą dostępne tylko dla zalogowanych użytkowników.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                          height: 1.5,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      const SizedBox(height: 36),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const LoginScreen(),
                              ),
                            );
                          },
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
                          child: const Text('Zaloguj się'),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Nie masz konta?',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[500],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const LoginScreen(),
                              ),
                            );
                          },
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            side: BorderSide(
                              color: Colors.grey.shade300,
                            ),
                            backgroundColor: Colors.grey.shade50,
                            foregroundColor: Colors.black87,
                          ),
                          child: const Text(
                            'Zarejestruj się',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }

        return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream:
              FirebaseFirestore.instance
                  .collection('users')
                  .doc(user.uid)
                  .snapshots(),
          builder: (context, userSnap) {
            final userData = userSnap.data?.data();
            return _buildList(items, userData);
          },
        );
      },
    ),
  );

  Widget _buildList(List<Achievement> items, Map<String, dynamic>? userData) {
    final Set<String> earnedIds = {};
    final Map<String, dynamic> unlockedAt = {};

    final dynamic summaryField = userData?['achievementsSummary'];
    if (summaryField is Map<String, dynamic>) {
      summaryField.forEach((k, v) {
        if (v == true) earnedIds.add(k);
      });
    } else if (summaryField is List) {
      for (final e in summaryField) {
        if (e is String) earnedIds.add(e);
      }
    }

    final dynamic unlockedField = userData?['achievementsUnlockedAt'];
    if (unlockedField is Map<String, dynamic>) {
      unlockedAt.addAll(unlockedField);
    }

    if (userData != null) {
      userData.forEach((k, v) {
        if (k.startsWith('achievementsSummary.')) {
          final id = k.substring('achievementsSummary.'.length);
          if (v == true) earnedIds.add(id);
        }
        if (k.startsWith('achievementsUnlockedAt.')) {
          final id = k.substring('achievementsUnlockedAt.'.length);
          unlockedAt[id] = v;
        }
      });
    }

    int visitedCount = 0;
    if (userData != null) {
      final vp = userData['visitedPlaces'];
      if (vp is List) {
        visitedCount = vp.cast<String>().length;
      } else {
        final tp = userData['totalPlacesVisited'];
        if (tp is num) visitedCount = tp.toInt();
      }
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      itemBuilder: (context, i) {
        final a = items[i];
        final bool earned =
            earnedIds.contains(a.id) || unlockedAt.containsKey(a.id);
        final bool isExpanded = expandedId == a.id;

        final int? target = (a.criteria['target'] as num?)?.toInt();
        int current = 0;
        double progressPercent = 0.0;
        if (target != null && target > 0) {
          if (a.type == 'visit') {
            current = visitedCount;
          } else {
            final progMap =
                userData?['achievementsProgress'] as Map<String, dynamic>?;
            if (progMap != null && progMap[a.id] is num) {
              current = (progMap[a.id] as num).toInt();
            } else if (userData != null &&
                userData['achievementsProgress.${a.id}'] is num) {
              current =
                  (userData['achievementsProgress.${a.id}'] as num).toInt();
            }
          }
          progressPercent = (current / target).clamp(0.0, 1.0);
        }

        final unlockedValue = unlockedAt[a.id];

        return GestureDetector(
          onTap: () {
            setState(() {
              expandedId = isExpanded ? null : a.id;
            });
          },
          child: AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: Container(
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F9FA),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: earned ? Colors.green.shade300 : Colors.grey.shade200,
                  width: 1.5,
                ),
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          width: 70,
                          height: 70,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              if (a.photoUrl != null && a.photoUrl!.isNotEmpty)
                                Container(
                                  width: 70,
                                  height: 70,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    image: DecorationImage(
                                      image: NetworkImage(a.photoUrl!),
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                )
                              else
                                Icon(Icons.emoji_events, color: Colors.white, size: 36),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                a.title,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: earned ? Colors.black : Colors.black87,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                a.desc,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                  height: 1.3,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        SizedBox(
                          width: 90,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              if (!earned && target != null && target > 0) ...[
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: LinearProgressIndicator(
                                    value: progressPercent,
                                    backgroundColor: Colors.grey.shade200,
                                    color: Colors.green.shade400,
                                    minHeight: 6,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  '$current/$target',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey.shade500,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  textAlign: TextAlign.right,
                                ),
                              ] else if (earned) ...[
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.green.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.check_circle,
                                        color: Colors.green.shade600,
                                        size: 14,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Zdobyte',
                                        style: TextStyle(
                                          color: Colors.green.shade700,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  '100%',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.green.shade700,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  textAlign: TextAlign.right,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isExpanded)
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        border: Border(
                          top: BorderSide(color: Colors.grey.shade200, width: 1),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 140,
                              height: 140,
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  if (!earned && target != null && target > 0)
                                    CircularProgressIndicator(
                                      value: progressPercent,
                                      strokeWidth: 8,
                                      backgroundColor: Colors.grey.shade200,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.orange.shade400,
                                      ),
                                    ),
                                  Center(
                                    child: Container(
                                      width: 120,
                                      height: 120,
                                      decoration: const BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Colors.transparent,
                                      ),
                                      child: a.photoUrl != null && a.photoUrl!.isNotEmpty
                                          ? ClipOval(
                                              child: Image.network(
                                                a.photoUrl!,
                                                fit: BoxFit.cover,
                                              ),
                                            )
                                          : Icon(
                                              Icons.emoji_events,
                                              color: earned
                                                  ? Colors.orange.shade400
                                                  : Colors.grey.shade800,
                                              size: 64,
                                            ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            if (!earned && target != null && target > 0) ...[
                              Text(
                                '$current / $target',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                              const SizedBox(height: 16),
                            ],

                            _buildStatusBadge(earned, unlockedValue),
                            const SizedBox(height: 20),

                            _buildConditionsCard(a),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusBadge(bool earned, dynamic unlockedValue) {
    final dateText = _formatUnlockedDate(unlockedValue);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: earned ? Colors.green.shade50 : Colors.orange.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            earned ? Icons.check_circle : Icons.lock_clock,
            color: earned ? Colors.green.shade600 : Colors.orange.shade600,
            size: 14,
          ),
          const SizedBox(width: 6),
          Text(
            earned ? 'Zdobyte' : 'W trakcie',
            style: TextStyle(
              color: earned ? Colors.green.shade700 : Colors.orange.shade700,
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
          ),
          if (earned && dateText != null) ...[
            Text(
              ' - $dateText',
              style: TextStyle(
                color: Colors.green.shade600,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildConditionsCard(Achievement achievement) {
    final crit = achievement.criteria;
    String? conditionText;

    if (achievement.type == 'visit' && crit['target'] is num) {
      final t = (crit['target'] as num).toInt();
      final pluralForm = t == 1
          ? 'miejsce'
          : (t % 10 >= 2 && t % 10 <= 4 && (t < 10 || t > 20) ? 'miejsca' : 'miejsc');
      conditionText = 'Odwiedź $t $pluralForm';
    } else if (crit.isNotEmpty) {
      final key = crit.keys.first;
      final value = crit.values.first;
      conditionText = 'Osiągnij $value w $key';
    }

    if (conditionText == null) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'WARUNEK',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.flag_outlined, color: Colors.orange.shade600, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  conditionText,
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.grey.shade800,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String? _formatUnlockedDate(dynamic val) {
    if (val == null) return null;
    DateTime dt;
    try {
      if (val is Timestamp) {
        dt = val.toDate();
      } else if (val is DateTime) {
        dt = val;
      } else if (val is int) {
        dt = DateTime.fromMillisecondsSinceEpoch(val);
      } else if (val is String) {
        dt = DateTime.parse(val);
      } else {
        return val.toString();
      }
    } catch (e) {
      return val.toString();
    }

    const months = [
      'sty',
      'lut',
      'mar',
      'kwi',
      'maj',
      'cze',
      'lip',
      'sie',
      'wrz',
      'paź',
      'lis',
      'gru',
    ];
    final day = dt.day.toString().padLeft(2, '0');
    final mon = months[(dt.month - 1).clamp(0, 11)];
    final year = dt.year.toString();
    return '$day $mon $year';
  }
}