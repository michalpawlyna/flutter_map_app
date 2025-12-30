import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:ui';
import 'package:flutter/material.dart';

import '../models/achievement.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';

enum AchievementFilter { all, unlocked, locked }

class AchievementsScreen extends StatefulWidget {
  const AchievementsScreen({Key? key}) : super(key: key);

  @override
  State<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends State<AchievementsScreen> {
  AchievementFilter _filter = AchievementFilter.all;

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
    body: Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: SizedBox(
            height: 40,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: [
                  const SizedBox(width: 4),
                  _buildFilterChip('Wszystkie', AchievementFilter.all),
                  const SizedBox(width: 8),
                  _buildFilterChip('Odblokowane', AchievementFilter.unlocked),
                  const SizedBox(width: 8),
                  _buildFilterChip('Nieodblokowane', AchievementFilter.locked),
                  const SizedBox(width: 8),
                ],
              ),
            ),
          ),
        ),

        Expanded(
          child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream:
                FirebaseFirestore.instance
                    .collection('achievements')
                    .snapshots(),
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

              final items =
                  docs.map((d) => Achievement.fromSnapshot(d)).toList();

              final user = AuthService().currentUser;
              if (user == null) {
                return _buildLoginPrompt(context);
              }

              return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                stream:
                    FirebaseFirestore.instance
                        .collection('users')
                        .doc(user.uid)
                        .snapshots(),
                builder: (context, userSnap) {
                  final userData = userSnap.data?.data();
                  return _AchievementsList(
                    items: items,
                    userData: userData,
                    filter: _filter,
                  );
                },
              );
            },
          ),
        ),
      ],
    ),
  );

  Widget _buildFilterChip(String label, AchievementFilter value) {
    final bool selected = _filter == value;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => setState(() => _filter = value),
      selectedColor: Colors.lightBlue[50],
      backgroundColor: Colors.white,
      labelStyle: TextStyle(
        color: selected ? Colors.blue.shade800 : Colors.black87,
        fontWeight: FontWeight.w600,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: selected ? Colors.blue.shade800 : Colors.black12,
        ),
      ),
    );
  }

  Widget _buildLoginPrompt(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.person_off, size: 72, color: Colors.grey),
            const SizedBox(height: 12),
            const Text(
              'Nie jesteś zalogowany',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            const Text(
              'Aby zobaczyć zdobyte osiągnięcia, zaloguj się.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.black54),
            ),
            const SizedBox(height: 18),
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
                ),
                child: const Text('Zaloguj się'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AchievementsList extends StatelessWidget {
  final List<Achievement> items;
  final Map<String, dynamic>? userData;
  final AchievementFilter filter;

  const _AchievementsList({
    required this.items,
    required this.userData,
    required this.filter,
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

    final filteredItems =
        items.where((a) {
          final bool earned =
              earnedIds.contains(a.id) || unlockedAt.containsKey(a.id);
          if (filter == AchievementFilter.unlocked) return earned;
          if (filter == AchievementFilter.locked) return !earned;
          return true;
        }).toList();

    if (filteredItems.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Text('Brak osiągnięć spełniających filtr'),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: filteredItems.length,
      itemBuilder: (context, i) {
        final a = filteredItems[i];
        final bool earned =
            earnedIds.contains(a.id) || unlockedAt.containsKey(a.id);

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
                userData!['achievementsProgress.${a.id}'] is num) {
              current =
                  (userData!['achievementsProgress.${a.id}'] as num).toInt();
            }
          }
          progressPercent = (current / target).clamp(0.0, 1.0);
        }

        final unlockedValue = unlockedAt[a.id];

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

    _rotationAnimation = Tween<double>(
      begin: 0,
      end: 0.5,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
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
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 70,
                    height: 70,
                    child:
                        a.photoUrl != null && a.photoUrl!.isNotEmpty && earned
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
                                ? Container(
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
                                : Container(
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
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
              Icon(
                Icons.description_outlined,
                color: Colors.grey.shade700,
                size: 16,
              ),
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
                      TextSpan(text: widget.achievement.desc),
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
                Icon(
                  Icons.calendar_today,
                  color: Colors.grey.shade700,
                  size: 16,
                ),
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
                      TextSpan(text: dateText),
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

    const months = [
      'stycznia',
      'lutego',
      'marca',
      'kwietnia',
      'maja',
      'czerwca',
      'lipca',
      'sierpnia',
      'września',
      'października',
      'listopada',
      'grudnia',
    ];
    final day = dt.day.toString();
    final mon = months[(dt.month - 1).clamp(0, 11)];
    final year = dt.year.toString();
    return '$day $mon $year';
  }
}
