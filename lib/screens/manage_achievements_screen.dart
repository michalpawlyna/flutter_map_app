import 'package:flutter/material.dart';
import 'package:toastification/toastification.dart';

import '../models/achievement.dart';
import '../models/user.dart';
import '../services/firestore_service.dart';

class ManageAchievementsScreen extends StatefulWidget {
  final AppUser user;
  final List<Achievement> allAchievements;

  const ManageAchievementsScreen({
    Key? key,
    required this.user,
    required this.allAchievements,
  }) : super(key: key);

  @override
  State<ManageAchievementsScreen> createState() =>
      _ManageAchievementsScreenState();
}

class _ManageAchievementsScreenState extends State<ManageAchievementsScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  late List<String> _selectedAchievementIds;
  bool _isSaving = false;

  static const int _maxEquipped = 1;

  @override
  void initState() {
    super.initState();
    _selectedAchievementIds = List.from(widget.user.equippedAchievements);
  }

  void _onAchievementTapped(String achievementId) {
    setState(() {
      if (_selectedAchievementIds.contains(achievementId)) {
        _selectedAchievementIds.remove(achievementId);
      } else {
        if (_selectedAchievementIds.length < _maxEquipped) {
          _selectedAchievementIds.add(achievementId);
        } else {
          toastification.show(
            context: context,
            title: const Text('Możesz wybrać maksymalnie 1 odznake.'),
            style: ToastificationStyle.flat,
            type: ToastificationType.warning,
            autoCloseDuration: const Duration(seconds: 3),
          );
        }
      }
    });
  }

  Future<void> _saveChanges() async {
    if (_isSaving) return;

    setState(() => _isSaving = true);

    try {
      await _firestoreService.updateUserEquippedAchievements(
        widget.user.uid,
        _selectedAchievementIds,
      );
      if (mounted) {
        toastification.show(
          context: context,
          title: const Text('Zapisano zmiany.'),
          style: ToastificationStyle.flat,
          type: ToastificationType.success,
          autoCloseDuration: const Duration(seconds: 3),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        toastification.show(
          context: context,
          title: Text('Błąd podczas zapisu: ${e.toString()}'),
          style: ToastificationStyle.flat,
          type: ToastificationType.error,
          autoCloseDuration: const Duration(seconds: 4),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final unlockedAchievements =
        widget.allAchievements
            .where((ach) => widget.user.achievementsSummary[ach.id] == true)
            .toList();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_sharp),
          onPressed: () => Navigator.of(context).pop(),
          tooltip: 'Powrót',
        ),
        title: const Text(
          'Zarządzaj odznakami',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child:
                _isSaving
                    ? const Center(
                      child: SizedBox(
                        width: 36,
                        height: 36,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                    : IconButton(
                      icon: const Icon(Icons.check, color: Colors.green),
                      onPressed: _saveChanges,
                      tooltip: 'Zapisz',
                    ),
          ),
        ],
      ),
      body:
          unlockedAchievements.isEmpty
              ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.shield_outlined,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Nie masz jeszcze żadnych odblokowanych osiągnięć.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              )
              : GridView.builder(
                padding: const EdgeInsets.all(20),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 16,
                  childAspectRatio: 0.85,
                ),
                itemCount: unlockedAchievements.length,
                itemBuilder: (context, index) {
                  final achievement = unlockedAchievements[index];
                  final isSelected = _selectedAchievementIds.contains(
                    achievement.id,
                  );

                  return GestureDetector(
                    onTap: () => _onAchievementTapped(achievement.id),
                    child: Transform.scale(
                      scale: isSelected ? 1.05 : 1.0,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color:
                                isSelected
                                    ? Colors.blue.shade600
                                    : Colors.grey.shade200,
                            width: isSelected ? 2.5 : 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color:
                                  isSelected
                                      ? Colors.blue.withOpacity(0.15)
                                      : Colors.black.withOpacity(0.06),
                              blurRadius: isSelected ? 12 : 6,
                              offset:
                                  isSelected
                                      ? const Offset(0, 4)
                                      : const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(19),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade100,
                                      shape: BoxShape.circle,
                                    ),
                                    child:
                                        achievement.photoUrl != null
                                            ? Image.network(
                                              achievement.photoUrl!,
                                              height: 48,
                                              width: 48,
                                              errorBuilder:
                                                  (_, __, ___) => const Icon(
                                                    Icons.error,
                                                    size: 48,
                                                  ),
                                            )
                                            : Icon(
                                              Icons.shield,
                                              size: 48,
                                              color: Colors.grey[400],
                                            ),
                                  ),
                                  const SizedBox(height: 12),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8.0,
                                    ),
                                    child: Text(
                                      achievement.title,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color:
                                            isSelected
                                                ? Colors.blue.shade700
                                                : Colors.black87,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              if (isSelected)
                                Positioned(
                                  top: 8,
                                  right: 8,
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.shade600,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.blue.withOpacity(0.4),
                                          blurRadius: 6,
                                        ),
                                      ],
                                    ),
                                    child: const Icon(
                                      Icons.check,
                                      color: Colors.white,
                                      size: 18,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
    );
  }
}
