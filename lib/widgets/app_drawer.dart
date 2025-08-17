import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../screens/settings_screen.dart';

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
    final accountName = user?.displayName ?? 'Użytkownik';
    final accountEmail = user?.email ?? '';

    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            UserAccountsDrawerHeader(
              accountName: Text(user != null ? accountName : 'Witaj'),
              accountEmail: Text(user != null ? accountEmail : ''),
              currentAccountPicture: CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(
                  user != null ? Icons.person : Icons.person_outline,
                  size: 36,
                  color: Colors.grey[800],
                ),
              ),
              otherAccountsPictures: [],
            ),

            if (user == null)
              ListTile(
                leading: const Icon(Icons.login),
                title: const Text('Zaloguj / Zarejestruj'),
                onTap: () {
                  Navigator.of(context).pop();
                  onSelect(1); // profile screen index
                },
              )
            else
              ListTile(
                leading: const Icon(Icons.person),
                title: const Text('Profil'),
                onTap: () {
                  Navigator.of(context).pop();
                  onSelect(1);
                },
              ),

            const Divider(),

            ListTile(
              leading: const Icon(Icons.home),
              title: const Text('Home'),
              onTap: () {
                Navigator.of(context).pop();
                onSelect(0);
              },
            ),

            ListTile(
              leading: const Icon(Icons.map),
              title: const Text('Mapa'),
              onTap: () {
                Navigator.of(context).pop();
                onSelect(0);
              },
            ),

            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Ustawienia'),
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const SettingsScreen()),
                );
              },
            ),

            const Spacer(),

            if (user != null)
              ListTile(
                leading: const Icon(Icons.logout),
                title: const Text('Wyloguj'),
                onTap: () async {
                  Navigator.of(context).pop();
                  try {
                    await authService.signOut();
                    onSelect(0); // wróć do home po wylogowaniu
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Wylogowano')),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Błąd wylogowania: $e')),
                    );
                  }
                },
              ),
          ],
        ),
      ),
    );
  }
}
