import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../screens/profile_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/map_screen.dart';
import '../screens/achievements_screen.dart';

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
    final displayName = user?.displayName ?? '';
    final email = user?.email ?? '';

    return Drawer(
      // Ustawiamy explicite białe tło dla całego drawera (w tym obszaru statusbara)
      backgroundColor: Colors.white,
      child: SafeArea(
        child: Container(
          color: Colors.white,
          child: Column(
            children: [
              // Górny wiersz: avatar + dane (tylko gdy zalogowany) oraz przycisk zamykania
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 12, 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (user != null)
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            Navigator.of(context).pop();
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const ProfileScreen()),
                            );
                          },
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 28,
                                backgroundColor: Colors.grey[200],
                                backgroundImage:
                                    user.photoURL != null ? NetworkImage(user.photoURL!) : null,
                                child: user.photoURL == null
                                    ? const Icon(Icons.person, size: 28, color: Colors.black54)
                                    : null,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      displayName.isNotEmpty ? displayName : 'Użytkownik',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      email,
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey[600],
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      const Spacer(),

                    // Close button
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                      tooltip: 'Zamknij',
                    ),
                  ],
                ),
              ),

              // Gdy wylogowany -> pokazujemy tylko czarny przycisk logowania
              if (user == null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const ProfileScreen()),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      child: const Text('Logowanie / Rejestracja'),
                    ),
                  ),
                ),

              const SizedBox(height: 6),

              // Lista opcji (bez szarych linii)
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  children: [
                    ListTile(
                      leading: const Icon(Icons.home_outlined),
                      title: const Text('Home'),
                      onTap: () {
                        Navigator.of(context).pop();
                        onSelect(0);
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.emoji_events_outlined),
                      title: const Text('Osiągnięcia'),
                      onTap: () {
                        Navigator.of(context).pop();
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const AchievementsScreen()),
                        );
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.settings_outlined),
                      title: const Text('Ustawienia'),
                      onTap: () {
                        Navigator.of(context).pop();
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const SettingsScreen()),
                        );
                      },
                    ),
                    // Możesz dodawać tu kolejne elementy listy
                  ],
                ),
              ),

              // Przyciski dolne (Wyloguj) - pokazywany tylko gdy zalogowany
              if (user != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
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
                        side: BorderSide(color: Colors.red[50]!),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                )
              else
                const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
