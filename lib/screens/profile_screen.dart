import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:toastification/toastification.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  final VoidCallback? onBack;
  const ProfileScreen({Key? key, this.onBack}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  final AuthService _authService = AuthService();

  final _formKey = GlobalKey<FormState>();

  TextEditingController? _displayNameController;
  TextEditingController? _usernameController;

  String _serverDisplayName = '';
  String _serverUsername = '';

  bool _loading = false;
  bool _saving = false;

  void _attachListeners() {
    _displayNameController?.removeListener(_onControllerChanged);
    _usernameController?.removeListener(_onControllerChanged);
    _displayNameController?.addListener(_onControllerChanged);
    _usernameController?.addListener(_onControllerChanged);
  }

  void _onControllerChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _displayNameController?.removeListener(_onControllerChanged);
    _usernameController?.removeListener(_onControllerChanged);
    _displayNameController?.dispose();
    _usernameController?.dispose();
    super.dispose();
  }

  InputDecoration _fieldDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.black54),
      filled: true,
      fillColor: Colors.grey[200],
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.black, width: 1),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  bool get _hasChanges {
    final d = _displayNameController?.text.trim() ?? '';
    final u = _usernameController?.text.trim() ?? '';
    return (d != _serverDisplayName) || (u != _serverUsername);
  }

  Future<void> _saveChanges(String uid) async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final newDisplayName = _displayNameController!.text.trim();
    final newUsername = _usernameController!.text.trim();

    final changes = <String, dynamic>{};
    if (newDisplayName != _serverDisplayName)
      changes['displayName'] = newDisplayName;
    if (newUsername != _serverUsername) changes['username'] = newUsername;

    if (changes.isEmpty) return;

    setState(() => _saving = true);

    try {
      final usersRef = FirebaseFirestore.instance.collection('users').doc(uid);
      await usersRef.update(changes);

      try {
        final user = _authService.currentUser;
        if (user != null && changes.containsKey('displayName')) {
          await user.updateDisplayName(changes['displayName'] as String);
        }
      } catch (_) {}

      setState(() {
        if (changes.containsKey('displayName'))
          _serverDisplayName = newDisplayName;
        if (changes.containsKey('username')) _serverUsername = newUsername;
      });

      if (mounted) {
        toastification.show(
          context: context,
          title: const Text('Zapisano zmiany.'),
          style: ToastificationStyle.flat,
          type: ToastificationType.success,
          autoCloseDuration: const Duration(seconds: 3),
          alignment: Alignment.bottomCenter,
          margin: const EdgeInsets.fromLTRB(12, 0, 12, 24),
        );
      }
    } catch (e) {
      if (mounted) {
        toastification.show(
          context: context,
          title: Text('Błąd podczas zapisu: ${e.toString()}'),
          style: ToastificationStyle.flat,
          type: ToastificationType.error,
          autoCloseDuration: const Duration(seconds: 4),
          alignment: Alignment.bottomCenter,
          margin: const EdgeInsets.fromLTRB(12, 0, 12, 24),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return StreamBuilder<User?>(
      stream: _authService.authStateChanges,
      builder: (context, authSnapshot) {
        final user = authSnapshot.data ?? _auth_service_currentUserFallback();

        return Scaffold(
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_sharp),
              onPressed:
                  widget.onBack ?? () => Navigator.of(context).maybePop(),
              tooltip: 'Powrót',
            ),
            title: const Text(
              'Mój profil',
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
                padding: const EdgeInsets.only(right: 8),
                child: Builder(
                  builder: (ctx) {
                    if (user == null) return const SizedBox.shrink();
                    final uid = user.uid;
                    if (_saving) {
                      return const Center(
                        child: SizedBox(
                          width: 36,
                          height: 36,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      );
                    }
                    if (!_hasChanges) return const SizedBox.shrink();
                    return IconButton(
                      icon: const Icon(Icons.check, color: Colors.black),
                      onPressed: () => _saveChanges(uid),
                      tooltip: 'Zapisz zmiany',
                    );
                  },
                ),
              ),
            ],
          ),
          backgroundColor: Colors.grey[50],
          body: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 32,
                  ),
                  child:
                      user == null
                          ? _buildNotLoggedIn(context)
                          : _buildProfileForUser(user),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  User? _auth_service_currentUserFallback() => _authService.currentUser;

  Widget _buildNotLoggedIn(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(
          'assets/phone.png',
          width: 160,
          height: 160,
          fit: BoxFit.contain,
          errorBuilder:
              (_, __, ___) => const Icon(
                Icons.image_not_supported,
                size: 96,
                color: Colors.grey,
              ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Nie jesteś zalogowany.',
          style: TextStyle(fontSize: 16, color: Colors.black87),
        ),
        const SizedBox(height: 8),
        const Text(
          'Przejdź do ekranu logowania, aby uzyskać dostęp do profilu.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14, color: Colors.black54),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const LoginScreen()));
            },
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
            child: const Text('Przejdź do logowania'),
          ),
        ),
      ],
    );
  }

  Widget _buildProfileForUser(User user) {
    final uid = user.uid;
    final email = user.email ?? '';

    final userDocStream =
        FirebaseFirestore.instance.collection('users').doc(uid).snapshots();

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: userDocStream,
      builder: (context, snapshot) {
        String username = '';
        String displayName = '';

        if (snapshot.hasError) {
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

        if (_displayNameController == null ||
            _serverDisplayName != displayName) {
          _displayNameController?.removeListener(_onControllerChanged);
          _displayNameController?.dispose();
          _displayNameController = TextEditingController(text: displayName);
          _serverDisplayName = displayName;
        }
        if (_usernameController == null || _serverUsername != username) {
          _usernameController?.removeListener(_onControllerChanged);
          _usernameController?.dispose();
          _usernameController = TextEditingController(text: username);
          _serverUsername = username;
        }

        _attachListeners();

        return Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: CircleAvatar(
                  radius: 42,
                  backgroundColor: Colors.grey[200],
                  backgroundImage:
                      user.photoURL != null
                          ? NetworkImage(user.photoURL!)
                          : null,
                  child:
                      user.photoURL == null
                          ? const Icon(
                            Icons.person,
                            size: 44,
                            color: Colors.black54,
                          )
                          : null,
                ),
              ),
              const SizedBox(height: 18),

              const Text(
                'E-mail',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                initialValue: email,
                enabled: false,
                decoration: _fieldDecoration(
                  '',
                ).copyWith(hintText: email.isNotEmpty ? email : 'Brak email'),
                style: const TextStyle(color: Colors.black87),
              ),
              const SizedBox(height: 16),

              const Text(
                'Imię i nazwisko',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _displayNameController,
                decoration: _fieldDecoration('Twoje imię i nazwisko'),
                buildCounter:
                    (
                      _, {
                      required int currentLength,
                      required bool isFocused,
                      int? maxLength,
                    }) => null,
                validator: (val) {
                  final v = (val ?? '').trim();
                  if (v.isEmpty) return 'Wprowadź imię i nazwisko';
                  if (v.length > 80) return 'Za długie (maks. 80 znaków)';
                  return null;
                },
              ),
              const SizedBox(height: 12),

              const Text(
                'Nazwa użytkownika',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _usernameController,
                decoration: _fieldDecoration('Nazwa użytkownika'),
                validator: (val) {
                  final v = (val ?? '').trim().toLowerCase();
                  final regex = RegExp(r'^[a-z0-9._-]{3,30}$');
                  if (v.isEmpty) return 'Wprowadź nazwę użytkownika';
                  if (!regex.hasMatch(v))
                    return 'Nieprawidłowa nazwa (3-30: a-z,0-9 . _ -)';
                  return null;
                },
              ),

              const SizedBox(height: 18),
            ],
          ),
        );
      },
    );
  }
}
