import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../screens/profile_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/achievements_screen.dart';
import '../screens/login_screen.dart';

class AppDrawer extends StatelessWidget {
  final AuthService authService;
  final ValueChanged<int> onSelect;

  const AppDrawer({
    Key? key,
    required this.authService,
    required this.onSelect,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final user = authService.currentUser;
    final displayName = user?.displayName ?? 'Użytkownik';
    final email = user?.email ?? '';

    return Drawer(
      backgroundColor: Colors.white,
      // brak zaokrągleń po prawej
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      child: SafeArea(
        child: Column(
          children: [
            // większy odstęp od góry dla ładnego wyglądu
            const SizedBox(height: 28),

            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: user != null
                  ? InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () {
                        Navigator.of(context).pop();
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const ProfileScreen()),
                        );
                      },
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 32,
                            backgroundColor: Colors.grey[200],
                            backgroundImage: user.photoURL != null
                                ? NetworkImage(user.photoURL!)
                                : null,
                            child: user.photoURL == null
                                ? const Icon(Icons.person, size: 32, color: Colors.black54)
                                : null,
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // nazwa (placeholder 'Użytkownik' gdy brak displayName)
                                Text(
                                  displayName,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                // email
                                Text(
                                  email,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w400,
                                    color: Colors.grey[600],
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    )
                  : SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const LoginScreen()),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                          textStyle: const TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w600),
                        ),
                        child: const Text('Logowanie / Rejestracja'),
                      ),
                    ),
            ),

            const SizedBox(height: 18),

            // Divider nie dotyka krawędzi
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Divider(color: Colors.grey[200], thickness: 1, height: 1),
            ),

            // Lista opcji
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
                    icon: Icons.emoji_events_outlined,
                    title: 'Osiągnięcia',
                    onTap: () {
                      Navigator.of(context).pop();
                      Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (_) => const AchievementsScreen()),
                      );
                    },
                  ),
                  _DrawerItem(
                    icon: Icons.settings_outlined,
                    title: 'Ustawienia',
                    onTap: () {
                      Navigator.of(context).pop();
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const SettingsScreen()),
                      );
                    },
                  ),
                ],
              ),
            ),

            // Przyciski dolne (Wyloguj) - tylko gdy zalogowany
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
              child: SizedBox(
                width: double.infinity,
                child: user != null
                    ? OutlinedButton.icon(
                        onPressed: () async {
                          Navigator.of(context).pop();
                          try {
                            await authService.signOut();
                            onSelect(0);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Wylogowano')),
                            );
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Błąd wylogowania: $e')),
                            );
                          }
                        },
                        icon: const Icon(Icons.logout),
                        label: const Text('Wyloguj'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red[700],
                          side: BorderSide(color: Colors.red[700]!),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                          textStyle: const TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w600),
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

  const _DrawerItem(
      {Key? key, required this.icon, required this.title, required this.onTap})
      : super(key: key);

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
                  style:
                      const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}