import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:ui';
import 'package:flutter/material.dart';

import '../models/achievement.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';

class AchievementsScreen extends StatelessWidget {
  const AchievementsScreen({Key? key}) : super(key: key);

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
          return _buildLoginPrompt(context);
        }

        return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .snapshots(),
          builder: (context, userSnap) {
            final userData = userSnap.data?.data();
            return _AchievementsList(items: items, userData: userData);
          },
        );
      },
    ),
  );

  Widget _buildLoginPrompt(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
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
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
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
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      side: BorderSide(color: Colors.grey.shade300),
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
}

// ============================================
// LISTA OSIĄGNIĘĆ - StatelessWidget
// ============================================
class _AchievementsList extends StatelessWidget {
  final List<Achievement> items;
  final Map<String, dynamic>? userData;

  const _AchievementsList({
    required this.items,
    required this.userData,
  });

  @override
  Widget build(BuildContext context) {
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
      userData!.forEach((k, v) {
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
      final vp = userData!['visitedPlaces'];
      if (vp is List) {
        visitedCount = vp.cast<String>().length;
      } else {
        final tp = userData!['totalPlacesVisited'];
        if (tp is num) visitedCount = tp.toInt();
      }
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: items.length,
      itemBuilder: (context, i) {
        final a = items[i];
        final bool earned = earnedIds.contains(a.id) || unlockedAt.containsKey(a.id);

        final int? target = (a.criteria['target'] as num?)?.toInt();
        int current = 0;
        double progressPercent = 0.0;
        
        if (target != null && target > 0) {
          if (a.type == 'visit') {
            current = visitedCount;
          } else {
            final progMap = userData?['achievementsProgress'] as Map<String, dynamic>?;
            if (progMap != null && progMap[a.id] is num) {
              current = (progMap[a.id] as num).toInt();
            } else if (userData != null && userData!['achievementsProgress.${a.id}'] is num) {
              current = (userData!['achievementsProgress.${a.id}'] as num).toInt();
            }
          }
          progressPercent = (current / target).clamp(0.0, 1.0);
        }

        final unlockedValue = unlockedAt[a.id];

        // ⬇️ Każdy element to osobny StatefulWidget z własnym stanem
        return _AchievementTile(
          key: ValueKey(a.id),
          achievement: a,
          earned: earned,
          target: target,
          current: current,
          progressPercent: progressPercent,
          unlockedValue: unlockedValue,
        );
      },
    );
  }
}

// ============================================
// POJEDYNCZY ELEMENT OSIĄGNIĘCIA - z własną animacją
// ============================================
class _AchievementTile extends StatefulWidget {
  final Achievement achievement;
  final bool earned;
  final int? target;
  final int current;
  final double progressPercent;
  final dynamic unlockedValue;

  const _AchievementTile({
    Key? key,
    required this.achievement,
    required this.earned,
    required this.target,
    required this.current,
    required this.progressPercent,
    required this.unlockedValue,
  }) : super(key: key);

  @override
  State<_AchievementTile> createState() => _AchievementTileState();
}

class _AchievementTileState extends State<_AchievementTile>
    with SingleTickerProviderStateMixin {
  
  late AnimationController _controller;
  late Animation<double> _heightAnimation;
  late Animation<double> _opacityAnimation;
  late Animation<double> _rotationAnimation;
  
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 350),
      vsync: this,
    );

    _heightAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOutCubic,
    );

    _opacityAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.3, 1.0, curve: Curves.easeIn),
    );

    _rotationAnimation = Tween<double>(begin: 0, end: 0.5).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final a = widget.achievement;
    final earned = widget.earned;
    final target = widget.target;
    final current = widget.current;
    final progressPercent = widget.progressPercent;

    return GestureDetector(
      onTap: _toggleExpanded,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: earned ? Colors.green.shade50 : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: earned ? Colors.green.shade300 : Colors.black12,
            width: 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // NAGŁÓWEK
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 70,
                    height: 70,
                    child: a.photoUrl != null && a.photoUrl!.isNotEmpty && earned
                        ? Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              image: DecorationImage(
                                image: NetworkImage(a.photoUrl!),
                                fit: BoxFit.cover,
                              ),
                            ),
                          )
                        : (earned
                            ? // zdobyte, ale brak photoUrl -> pokaż ikonę trofeum
                            Container(
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Icon(
                                    Icons.emoji_events,
                                    color: Colors.orange.shade400,
                                    size: 36,
                                  ),
                                ),
                              )
                            : // NIEZDOBYTE -> pokaż obrazek z assets
                            Container(
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  // używamy Image.asset jako DecorationImage
                                ),
                                child: ClipOval(
                                  child: Image.asset(
                                    'assets/locked_achievement.png',
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              )),
                  ),
                  const SizedBox(width: 16),
                  
                  // Tytuł i opis
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
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  
                  // Progress / Status
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
                              backgroundColor: Colors.black12,
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
                          ),
                        ] else if (earned) ...[
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: LinearProgressIndicator(
                              value: 1.0,
                              backgroundColor: Colors.green.shade300,
                              color: Colors.green.shade400,
                              minHeight: 6,
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
                          ),
                        ],
                      ],
                    ),
                  ),
                  
                  // Strzałka
                  const SizedBox(width: 8),
                  RotationTransition(
                    turns: _rotationAnimation,
                    child: Icon(
                      Icons.keyboard_arrow_down,
                      color: Colors.grey.shade500,
                      size: 24,
                    ),
                  ),
                ],
              ),
            ),

            // ROZWIJANA TREŚĆ
            SizeTransition(
              sizeFactor: _heightAnimation,
              axisAlignment: -1.0,
              child: FadeTransition(
                opacity: _opacityAnimation,
                child: _buildExpandedContent(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpandedContent() {
    final dateText = _formatUnlockedDate(widget.unlockedValue);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.green.shade50, width: 1)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.description_outlined, color: Colors.grey.shade700, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: RichText(
                  text: TextSpan(
                    style: TextStyle(
                      fontSize: 13,
                      fontFamily: 'Roboto',
                      color: Colors.grey.shade700,
                      height: 1.5,
                    ),
                    children: [
                      const TextSpan(
                        text: 'Opis: ',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      TextSpan(
                        text: widget.achievement.desc,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (widget.earned && dateText != null) ...[
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Icon(Icons.calendar_today, color: Colors.grey.shade700, size: 16),
                const SizedBox(width: 8),
                RichText(
                  text: TextSpan(
                    style: TextStyle(
                      fontSize: 13,
                      fontFamily: 'Roboto',
                      color: Colors.grey.shade700,
                    ),
                    children: [
                      const TextSpan(
                        text: 'Zdobyto: ',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      TextSpan(
                        text: dateText,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
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

    const months = ['stycznia', 'lutego', 'marca', 'kwietnia', 'maja', 'czerwca', 'lipca', 'sierpnia', 'września', 'października', 'listopada', 'grudnia'];
    final day = dt.day.toString();
    final mon = months[(dt.month - 1).clamp(0, 11)];
    final year = dt.year.toString();
    return '$day $mon $year';
  }
}