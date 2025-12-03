import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
  State<ManageAchievementsScreen> createState() => _ManageAchievementsScreenState();
}

class _ManageAchievementsScreenState extends State<ManageAchievementsScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  late List<String> _selectedAchievementIds;
  bool _isSaving = false;

  static const int _maxEquipped = 4;

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
            title: const Text('Możesz wybrać maksymalnie 4 odznaki.'),
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
      await _firestoreService.updateUserEquippedAchievements(widget.user.uid, _selectedAchievementIds);
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
    final unlockedAchievements = widget.allAchievements
        .where((ach) => widget.user.achievementsSummary[ach.id] == true)
        .toList();

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_sharp),
          onPressed: () => Navigator.of(context).pop(),
          tooltip: 'Powrót',
        ),
        title: const Text(
          'Zarządzaj odznakami',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: _isSaving
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
      body: unlockedAchievements.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Nie masz jeszcze żadnych odblokowanych osiągnięć.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            )
          : GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.8,
              ),
              itemCount: unlockedAchievements.length,
              itemBuilder: (context, index) {
                final achievement = unlockedAchievements[index];
                final isSelected = _selectedAchievementIds.contains(achievement.id);

                return GestureDetector(
                  onTap: () => _onAchievementTapped(achievement.id),
                  child: Opacity(
                    opacity: isSelected || _selectedAchievementIds.length < _maxEquipped
                        ? 1.0
                        : 0.5,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected ? Colors.black : Colors.grey.shade300,
                          width: isSelected ? 1.5 : 1,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                )
                              ]
                            : [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.04),
                                  blurRadius: 5,
                                  offset: const Offset(0, 1),
                                )
                              ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(15),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (achievement.photoUrl != null)
                                  Image.network(
                                    achievement.photoUrl!,
                                    height: 48,
                                    width: 48,
                                    errorBuilder: (_, __, ___) =>
                                        const Icon(Icons.error, size: 48),
                                  )
                                else
                                  const Icon(Icons.shield,
                                      size: 48, color: Colors.grey),
                                const SizedBox(height: 8),
                                Padding(
                                  padding:
                                      const EdgeInsets.symmetric(horizontal: 8.0),
                                  child: Text(
                                    achievement.title,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            if (isSelected)
                              Positioned(
                                top: 6,
                                right: 6,
                                child: Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.check_circle,
                                      color: Colors.green, size: 20),
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
