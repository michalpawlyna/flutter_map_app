import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService _authService = AuthService();
  final _formKey = GlobalKey<FormState>();
  String _email = '';
  String _password = '';
  bool _isRegisterMode = false;
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    final user = _authService.currentUser;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil'),
        automaticallyImplyLeading: false, // Remove back arrow completely if using bottom nav
      ),
      body: Stack(
        children: [
          Center(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 76),
              child: user == null
                  ? Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _isRegisterMode ? 'Rejestracja' : 'Logowanie',
                            style: const TextStyle(fontSize: 20),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            decoration: const InputDecoration(labelText: 'Email'),
                            validator: (val) => val!.isEmpty ? 'Wprowadź email' : null,
                            onChanged: (val) => _email = val,
                          ),
                          TextFormField(
                            decoration: const InputDecoration(labelText: 'Hasło'),
                            obscureText: true,
                            validator: (val) => val!.length < 6 ? 'Min. 6 znaków' : null,
                            onChanged: (val) => _password = val,
                          ),
                          const SizedBox(height: 20),
                          _loading
                              ? const CircularProgressIndicator()
                              : ElevatedButton(
                                  onPressed: _submit,
                                  child: Text(_isRegisterMode ? 'Zarejestruj' : 'Zaloguj'),
                                ),
                          TextButton(
                            onPressed: _toggleMode,
                            child: Text(
                              _isRegisterMode
                                  ? 'Masz już konto? Zaloguj się'
                                  : 'Nie masz konta? Zarejestruj się',
                            ),
                          ),
                        ],
                      ),
                    )
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Avatar section removed
                        Text(
                          'Zalogowany jako:',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          user.email ?? '',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'ID: ${user.uid}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade500,
                          ),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: () async {
                            await _authService.signOut();
                            setState(() {});
                          },
                          icon: const Icon(Icons.logout),
                          label: const Text('Wyloguj'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red.shade400,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  void _toggleMode() {
    setState(() => _isRegisterMode = !_isRegisterMode);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      if (_isRegisterMode) {
        await _authService.registerWithEmail(_email, _password);
      } else {
        await _authService.loginWithEmail(_email, _password);
      }
      setState(() {}); // Refresh UI
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      setState(() => _loading = false);
    }
  }
}
