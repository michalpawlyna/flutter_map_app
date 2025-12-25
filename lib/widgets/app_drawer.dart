import 'package:flutter/material.dart';
import 'package:toastification/toastification.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';
import '../models/user.dart';
import '../screens/profile_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/achievements_screen.dart';
import '../screens/login_screen.dart';
import '../screens/favourite_places_screen.dart';

class AppDrawer extends StatelessWidget {
  final AuthService authService;
  final ValueChanged<int> onSelect;
  final GlobalKey<ScaffoldState> scaffoldKey;

  const AppDrawer(
      {Key? key,
      required this.authService,
      required this.onSelect,
      required this.scaffoldKey})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final user = authService.currentUser;

    return Drawer(
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 28),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: user == null
                  ? SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const LoginScreen(),
                            ),
                          );
                        },
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
                        child: const Text('Logowanie / Rejestracja'),
                      ),
                    )
                  : StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                      stream: FirebaseFirestore.instance
                          .collection('users')
                          .doc(user.uid)
                          .snapshots(),
                      builder: (context, snap) {
                        String displayName = user.displayName ?? 'Użytkownik';
                        String email = user.email ?? '';
                        String? photoUrl = user.photoURL;
                        String role = '';

                        if (snap.hasData && snap.data!.exists) {
                          final appUser = AppUser.fromSnapshot(snap.data!);
                          displayName = appUser.displayName.isNotEmpty
                              ? appUser.displayName
                              : displayName;
                          email = appUser.email.isNotEmpty ? appUser.email : email;
                          photoUrl = (appUser.photoURL?.isNotEmpty ?? false)
                              ? appUser.photoURL
                              : photoUrl;
                          role = appUser.role ?? '';
                        }

                        return InkWell(
                          borderRadius: BorderRadius.circular(8),
                          onTap: () {
                            Navigator.of(context).pop();
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const ProfileScreen(),
                              ),
                            );
                          },
                          child: Row(
                            children: [
                              // Avatar with optional equipped achievement badge
                              Stack(
                                alignment: Alignment.center,
                                children: [
                                  CircleAvatar(
                                    radius: 32,
                                    backgroundColor: Colors.grey[200],
                                    backgroundImage:
                                        photoUrl != null ? NetworkImage(photoUrl) : null,
                                    child: photoUrl == null
                                        ? const Icon(
                                            Icons.person,
                                            size: 32,
                                            color: Colors.black54,
                                          )
                                        : null,
                                  ),
                                  if (snap.hasData && snap.data!.exists)
                                    Builder(builder: (ctx) {
                                      final appUser = AppUser.fromSnapshot(snap.data!);
                                      if (appUser.equippedAchievements.isEmpty) return const SizedBox.shrink();
                                      final eid = appUser.equippedAchievements.first;
                                      return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                                        future: FirebaseFirestore.instance
                                            .collection('achievements')
                                            .doc(eid)
                                            .get(),
                                        builder: (c, aSnap) {
                                          if (!aSnap.hasData || !aSnap.data!.exists) return const SizedBox.shrink();
                                          final data = aSnap.data!.data() ?? <String, dynamic>{};
                                          final photo = data['photoUrl'] as String?;
                                          return Positioned(
                                            bottom: 0,
                                            right: -2,
                                            child: Container(
                                              width: 30,
                                              height: 30,
                                              // Transparent background so only the badge image is visible
                                              child: ClipOval(
                                                child: photo != null
                                                    ? Image.network(
                                                        photo,
                                                        fit: BoxFit.cover,
                                                        width: 30,
                                                        height: 30,
                                                        errorBuilder: (_, __, ___) => Icon(
                                                          Icons.shield,
                                                          size: 16,
                                                          color: Colors.grey[700],
                                                        ),
                                                      )
                                                    : Icon(
                                                        Icons.shield,
                                                        size: 16,
                                                        color: Colors.grey[700],
                                                      ),
                                              ),
                                            ),
                                          );
                                        },
                                      );
                                    }),
                                ],
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      displayName,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            email,
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w400,
                                              color: Colors.grey[600],
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        if (role.isNotEmpty) ...[
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: Colors.black.withOpacity(0.06),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              role,
                                              style: const TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),

            const SizedBox(height: 18),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Divider(color: Colors.grey[200], thickness: 1, height: 1),
            ),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 12),
                children: [
                  _DrawerItem(
                    icon: Icons.home_outlined,
                    title: 'Home',
                    onTap: () {
                      Navigator.of(context).pop();
                      onSelect(0);
                    },
                  ),
                  _DrawerItem(
                    icon: Icons.route,
                    title: 'Stwórz własną trasę',
                    onTap: () {
                      Navigator.of(context).pop();
                      onSelect(-1);
                    },
                  ),
                  _DrawerItem(
                    icon: Icons.favorite_border,
                    title: 'Ulubione miejsca',
                    onTap: () {
                      Navigator.of(context).pop();
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const FavouritePlacesScreen(),
                        ),
                      );
                    },
                  ),
                  _DrawerItem(
                    icon: Icons.emoji_events_outlined,
                    title: 'Osiągnięcia',
                    onTap: () {
                      Navigator.of(context).pop();
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const AchievementsScreen(),
                        ),
                      );
                    },
                  ),
                  _DrawerItem(
                    icon: Icons.settings_outlined,
                    title: 'Ustawienia',
                    onTap: () {
                      Navigator.of(context).pop();
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const SettingsScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
              child: SizedBox(
                width: double.infinity,
                child: user != null
                    ? TextButton.icon(
                        onPressed: () async {
                          // Capture the drawer context before showing dialog
                          final drawerContext = context;
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => Dialog(
                              backgroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    // Icon circle on top
                                    Container(
                                      width: 56,
                                      height: 56,
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade200,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.logout,
                                        color: Colors.grey.shade700,
                                        size: 28,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    const Text(
                                      'Potwierdź wylogowanie',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    const Text(
                                      'Czy na pewno chcesz się wylogować?',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.black54,
                                      ),
                                    ),
                                    const SizedBox(height: 18),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: ElevatedButton(
                                            onPressed: () =>
                                                Navigator.of(ctx).pop(false),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor:
                                                  Colors.black,
                                              foregroundColor: Colors.white,
                                              elevation: 0,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      vertical: 16),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              textStyle: const TextStyle(
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            child: const Text('Anuluj'),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: TextButton(
                                            onPressed: () =>
                                                Navigator.of(ctx).pop(true),
                                            style: TextButton.styleFrom(
                                              backgroundColor:
                                                  Colors.white,
                                              foregroundColor: Colors.red,
                                              elevation: 0,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      vertical: 16),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              textStyle: const TextStyle(
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                            child: const Text('Wyloguj'),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );

                          final scaffoldContext = scaffoldKey.currentContext;

                          if (confirm != true) return;

                          Navigator.of(drawerContext).pop();
                          
                          // Pokaż toast natychmiast
                          if (scaffoldContext != null && scaffoldContext.mounted) {
                            toastification.show(
                              context: scaffoldContext,
                              title: const Text('Wylogowano pomyślnie'),
                              style: ToastificationStyle.flat,
                              type: ToastificationType.success,
                              autoCloseDuration: const Duration(seconds: 3),
                              alignment: Alignment.bottomCenter,
                              margin:
                                  const EdgeInsets.fromLTRB(12, 0, 12, 24),
                            );
                          }
                          
                          // Wyloguj w tle
                          try {
                            await authService.signOut();
                            onSelect(0);
                          } catch (e) {
                            if (scaffoldContext != null && scaffoldContext.mounted) {
                              toastification.show(
                                context: scaffoldContext,
                                title:
                                    Text('Błąd wylogowania: ${e.toString()}'),
                                style: ToastificationStyle.flat,
                                type: ToastificationType.error,
                                autoCloseDuration: const Duration(seconds: 4),
                                alignment: Alignment.bottomCenter,
                                margin:
                                    const EdgeInsets.fromLTRB(12, 0, 12, 24),
                              );
                            }
                          }
                        },
                        icon: Icon(Icons.logout, color: Colors.grey[700]),
                        label: Text(
                          'Wyloguj',
                          style: TextStyle(
                            color: Colors.grey[700],
                          ),
                        ),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          textStyle: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      )
                    : const SizedBox(height: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _DrawerItem({
    Key? key,
    required this.icon,
    required this.title,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  alignment: Alignment.center,
                  child: Icon(icon, size: 20, color: Colors.black54),
                ),
                const SizedBox(width: 14),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
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
