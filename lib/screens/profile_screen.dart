// profile_screen.dart
// Zaktualizowana wersja: tytuł AppBar (Logowanie / Rejestracja / Twój profil) jest umieszczony na środku w tej samej linii co strzałka cofania.

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
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

  Widget _buildProfileInfo(dynamic user) {
    final email = (user?.email ?? '') as String;
    final uid = (user?.uid ?? '') as String;

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
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () async {
              setState(() => _loading = true);
              try {
                await _authService.signOut();
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Błąd podczas wylogowywania: ${e.toString()}')),
                );
              } finally {
                setState(() => _loading = false);
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      setState(() => _loading = false);
    }
  }
}
