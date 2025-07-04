import 'package:flutter/material.dart';
import 'package:random_avatar/random_avatar.dart';
import '../services/auth_service.dart';
import '../widgets/navbar_widget.dart';

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
  String? _currentAvatarSeed;
  String? _tempAvatarSeed;
  bool _hasUnsavedChanges = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentAvatarSeed();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadCurrentAvatarSeed(); // ensure avatar is always reloaded when screen is revisited
  }

  Future<void> _loadCurrentAvatarSeed() async {
    if (_authService.currentUser != null) {
      final seed = await _authService.getCurrentUserAvatarSeed();
      setState(() {
        _currentAvatarSeed = seed;
        _tempAvatarSeed = seed;
      });
    }
  }

  void _generateNewAvatar() {
    setState(() {
      _tempAvatarSeed = _authService.generateRandomAvatarSeed();
      _hasUnsavedChanges = true;
    });
  }

  Future<void> _saveAvatarChanges() async {
    if (_tempAvatarSeed != null) {
      await _authService.saveCurrentUserAvatarSeed(_tempAvatarSeed!);
      setState(() {
        _currentAvatarSeed = _tempAvatarSeed;
        _hasUnsavedChanges = false;
      });

      // reload avatar seed in case other widgets use it
      await _loadCurrentAvatarSeed();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Avatar zapisany!')),
      );
    }
  }

  void _cancelAvatarChanges() {
    setState(() {
      _tempAvatarSeed = _currentAvatarSeed;
      _hasUnsavedChanges = false;
    });
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
      await _loadCurrentAvatarSeed(); // Load avatar after login/register
      setState(() {}); // Refresh UI
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

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
                        Stack(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(50),
                                border: Border.all(color: Colors.grey.shade300, width: 2),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(48),
                                child: _tempAvatarSeed != null
                                    ? RandomAvatar(
                                        _tempAvatarSeed!,
                                        height: 96,
                                        width: 96,
                                      )
                                    : const Icon(Icons.person, size: 96),
                              ),
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: GestureDetector(
                                onTap: _generateNewAvatar,
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.blue,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white, width: 2),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.2),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.casino,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        if (_hasUnsavedChanges) ...[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              ElevatedButton.icon(
                                onPressed: _saveAvatarChanges,
                                icon: const Icon(Icons.save, size: 16),
                                label: const Text('Zapisz'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                ),
                              ),
                              const SizedBox(width: 12),
                              OutlinedButton.icon(
                                onPressed: _cancelAvatarChanges,
                                icon: const Icon(Icons.cancel, size: 16),
                                label: const Text('Anuluj'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.grey.shade600,
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                        ],
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
                            setState(() {
                              _currentAvatarSeed = null;
                              _tempAvatarSeed = null;
                              _hasUnsavedChanges = false;
                            });
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
}
