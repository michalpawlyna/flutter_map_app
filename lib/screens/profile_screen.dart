// profile_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';

class ProfileScreen extends StatefulWidget {
  final VoidCallback? onBack;

  const ProfileScreen({Key? key, this.onBack}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  final AuthService _authService = AuthService();
  final _formKey = GlobalKey<FormState>();
  String _email = '';
  String _password = '';
  bool _isRegisterMode = false;
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return StreamBuilder<User?>(
      stream: _authService.authStateChanges,
      builder: (context, snapshot) {
        final user = snapshot.data ?? _authService.currentUser;

        final String appBarTitle;
        if (user == null) {
          appBarTitle = _isRegisterMode ? 'Rejestracja' : 'Logowanie';
        } else {
          appBarTitle = 'Mój profil';
        }

        return Scaffold(
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_sharp),
              onPressed: widget.onBack ?? () => Navigator.of(context).maybePop(),
              tooltip: 'Powrót',
            ),
            title: Text(
              appBarTitle,
              style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
            ),
            centerTitle: true,
            backgroundColor: Colors.transparent,
            foregroundColor: Colors.black,
            elevation: 0,
          ),
          backgroundColor: Colors.grey[50],
          body: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 260),
                    switchInCurve: Curves.easeInOut,
                    switchOutCurve: Curves.easeInOut,
                    child: Container(
                      key: ValueKey(user?.uid ?? 'auth'),
                      child: user == null ? _buildAuthForm() : _buildProfileInfo(user),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAuthForm() {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Column(
              children: [
                Image.asset(
                  'assets/phone.png',
                  width: 160,
                  height: 160,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) =>
                      const Icon(Icons.image_not_supported, size: 96, color: Colors.grey),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Email',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.email],
            decoration: InputDecoration(
              hintText: 'Wprowadź adres email',
              hintStyle: const TextStyle(color: Colors.black54),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Colors.black),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
            validator: (val) {
              final v = val?.trim();
              if (v == null || v.isEmpty) return 'Wprowadź email';
              if (!v.contains('@')) return 'Nieprawidłowy email';
              return null;
            },
            onChanged: (val) => _email = val.trim(),
          ),
          const SizedBox(height: 16),
          const Text(
            'Hasło',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            decoration: InputDecoration(
              hintText: 'Wprowadź hasło',
              hintStyle: const TextStyle(color: Colors.black54),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Colors.black),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
            obscureText: true,
            enableSuggestions: false,
            autocorrect: false,
            validator: (val) {
              final v = val ?? '';
              if (v.length < 6) return 'Min. 6 znaków';
              return null;
            },
            onChanged: (val) => _password = val,
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _loading ? null : _submit,
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
              child: _loading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.5,
                      ),
                    )
                  : Text(_isRegisterMode ? 'Zarejestruj' : 'Zaloguj'),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: TextButton(
              onPressed: _toggleMode,
              style: TextButton.styleFrom(
                foregroundColor: Colors.black54,
              ),
              child: Text(
                _isRegisterMode ? 'Masz już konto? Zaloguj się' : 'Nie masz konta? Zarejestruj się',
                style: const TextStyle(fontSize: 14, height: 1.4),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Widok profilu z Firestore (nasłuchiwanie users/{uid})
  Widget _buildProfileInfo(User user) {
    final email = user.email ?? '';
    final uid = user.uid;

    final userDocStream = FirebaseFirestore.instance.collection('users').doc(uid).snapshots();

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: userDocStream,
      builder: (context, snapshot) {
        // wartości domyślne
        String username = '';
        String displayName = '';

        if (snapshot.hasError) {
          // wyświetlamy komunikat błędu w UI (możesz dopasować)
          return Column(
            children: [
              const Icon(Icons.error, color: Colors.red, size: 48),
              const SizedBox(height: 8),
              Text('Błąd podczas pobierania profilu: ${snapshot.error}'),
            ],
          );
        } else if (snapshot.hasData && snapshot.data!.exists) {
          final data = snapshot.data!.data()!;
          username = (data['username'] ?? '') as String;
          displayName = (data['displayName'] ?? '') as String;
        }

        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.green[100],
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.person,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Twój profil',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text(
              'Informacje o koncie',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Zalogowany jako: $email',
              style: const TextStyle(fontSize: 14, color: Colors.black54, height: 1.4),
            ),
            const SizedBox(height: 4),
            Text(
              'ID: $uid',
              style: const TextStyle(fontSize: 14, color: Colors.black54, height: 1.4),
            ),
            const SizedBox(height: 8),
            // username z opcją edycji
            Row(
              children: [
                Expanded(
                  child: Text(
                    username.isNotEmpty ? 'Nazwa użytkownika: $username' : 'Nazwa użytkownika: —',
                    style: const TextStyle(fontSize: 14, color: Colors.black54, height: 1.4),
                  ),
                ),
                IconButton(
                  onPressed: () => _showEditUsernameDialog(username),
                  icon: const Icon(Icons.edit, size: 20),
                  tooltip: 'Edytuj nazwę użytkownika',
                ),
              ],
            ),
            // displayName z opcją edycji/dodania
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    displayName.isNotEmpty ? 'Imię i nazwisko: $displayName' : 'Imię i nazwisko: —',
                    style: const TextStyle(fontSize: 14, color: Colors.black54, height: 1.4),
                  ),
                ),
                IconButton(
                  onPressed: () => _showEditDisplayNameDialog(displayName),
                  icon: Icon(
                    displayName.isNotEmpty ? Icons.edit : Icons.add,
                    size: 20,
                  ),
                  tooltip: displayName.isNotEmpty ? 'Edytuj imię i nazwisko' : 'Dodaj imię i nazwisko',
                ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  setState(() => _loading = true);
                  try {
                    await _authService.signOut();
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Błąd podczas wylogowywania: ${e.toString()}')),
                      );
                    }
                  } finally {
                    if (mounted) setState(() => _loading = false);
                  }
                },
                icon: const Icon(Icons.logout),
                label: const Text('Wyloguj'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red[400],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // Dialog do edycji username (istniał wcześniej)
  void _showEditUsernameDialog(String currentUsername) {
    final _controller = TextEditingController(text: currentUsername);
    final _dialogFormKey = GlobalKey<FormState>();
    bool _saving = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(builder: (context, setStateDialog) {
          return AlertDialog(
            title: const Text('Zmień nazwę użytkownika'),
            content: Form(
              key: _dialogFormKey,
              child: TextFormField(
                controller: _controller,
                decoration: const InputDecoration(
                  hintText: 'nowa_nazwa',
                  helperText: '3-30 znaków: a-z, 0-9, . _ -',
                ),
                validator: (val) {
                  final v = (val ?? '').trim().toLowerCase();
                  final regex = RegExp(r'^[a-z0-9._-]{3,30}$');
                  if (v.isEmpty) return 'Wprowadź nazwę';
                  if (!regex.hasMatch(v)) return 'Nieprawidłowa nazwa';
                  return null;
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed: _saving ? null : () => Navigator.of(context).pop(),
                child: const Text('Anuluj'),
              ),
              ElevatedButton(
                onPressed: _saving
                    ? null
                    : () async {
                        if (!(_dialogFormKey.currentState?.validate() ?? false)) return;
                        final newUsername = _controller.text.trim();
                        setStateDialog(() => _saving = true);
                        try {
                          await AuthService().updateUsername(newUsername: newUsername);
                          if (mounted) {
                            Navigator.of(context).pop();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Nazwa użytkownika zaktualizowana.')),
                            );
                          }
                        } catch (e) {
                          final msg = e.toString();
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
                          }
                        } finally {
                          setStateDialog(() => _saving = false);
                        }
                      },
                child: _saving
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Zapisz'),
              ),
            ],
          );
        });
      },
    );
  }

  // NOWY: Dialog do edycji / dodania displayName
  void _showEditDisplayNameDialog(String currentDisplayName) {
    final _controller = TextEditingController(text: currentDisplayName);
    final _dialogFormKey = GlobalKey<FormState>();
    bool _saving = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(builder: (context, setStateDialog) {
          return AlertDialog(
            title: Text(currentDisplayName.isNotEmpty ? 'Edytuj imię i nazwisko' : 'Dodaj imię i nazwisko'),
            content: Form(
              key: _dialogFormKey,
              child: TextFormField(
                controller: _controller,
                decoration: const InputDecoration(
                  hintText: 'Twoje imię i nazwisko',
                  helperText: 'Możesz użyć spacji i znaków diakrytycznych. Maks. 80 znaków.',
                ),
                maxLength: 80,
                validator: (val) {
                  final v = (val ?? '').trim();
                  if (v.isEmpty) return 'Wprowadź imię i nazwisko';
                  if (v.length > 80) return 'Za długie (maks. 80 znaków)';
                  return null;
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed: _saving ? null : () => Navigator.of(context).pop(),
                child: const Text('Anuluj'),
              ),
              ElevatedButton(
                onPressed: _saving
                    ? null
                    : () async {
                        if (!(_dialogFormKey.currentState?.validate() ?? false)) return;
                        final newDisplayName = _controller.text.trim();
                        setStateDialog(() => _saving = true);
                        try {
                          final user = _authService.currentUser;
                          if (user == null) throw Exception('Użytkownik nie jest zalogowany.');

                          // Zapis do Firestore
                          final usersRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
                          await usersRef.update({'displayName': newDisplayName});

                          // Opcjonalnie: synchronizuj z FirebaseAuth.displayName
                          try {
                            await user.updateDisplayName(newDisplayName);
                          } catch (_) {
                            // jeśli nie pójdzie, nie przerywamy całej operacji
                          }

                          if (mounted) {
                            Navigator.of(context).pop();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Imię i nazwisko zaktualizowane.')),
                            );
                          }
                        } catch (e) {
                          final msg = e.toString();
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Błąd podczas zapisu: $msg')),
                            );
                          }
                        } finally {
                          setStateDialog(() => _saving = false);
                        }
                      },
                child: _saving
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Zapisz'),
              ),
            ],
          );
        });
      },
    );
  }

  void _toggleMode() {
    setState(() {
      _isRegisterMode = !_isRegisterMode;
      _email = '';
      _password = '';
    });
  }

  Future<void> _submit() async {
    final formState = _formKey.currentState;
    if (formState == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Formularz niedostępny. Spróbuj ponownie.')),
      );
      return;
    }

    if (!formState.validate()) return;

    setState(() => _loading = true);
    try {
      if (_isRegisterMode) {
        await _authService.registerWithEmail(_email, _password);
      } else {
        await _authService.loginWithEmail(_email, _password);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}
