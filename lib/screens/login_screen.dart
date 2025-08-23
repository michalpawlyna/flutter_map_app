// login_screen.dart
import 'package:flutter/material.dart';
import 'package:toastification/toastification.dart'; // <-- dodane
import '../services/auth_service.dart';
import 'profile_screen.dart';

class LoginScreen extends StatefulWidget {
  final VoidCallback? onBack;
  const LoginScreen({Key? key, this.onBack}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthService _authService = AuthService();

  final _formKey = GlobalKey<FormState>();
  String _email = '';
  String _password = '';
  bool _isRegisterMode = false;
  bool _loading = false;
  bool _showPassword = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_sharp),
          onPressed: widget.onBack ?? () => Navigator.of(context).maybePop(),
          tooltip: 'Powrót',
        ),
        title: Text(
          _isRegisterMode ? 'Rejestracja' : 'Logowanie',
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
              child: _buildAuthForm(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAuthForm() {
    // wspólny InputDecoration żeby nie powtarzać kodu
    InputDecoration _fieldDecoration(String hint) {
      return InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.black54),
        filled: true,
        fillColor: Colors.grey[200], // tu możesz dopasować odcień
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
            decoration: _fieldDecoration('Wprowadź adres email'),
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
            decoration: _fieldDecoration('Wprowadź hasło').copyWith(
              suffixIcon: IconButton(
                icon: Icon(
                  _showPassword ? Icons.visibility : Icons.visibility_off,
                ),
                onPressed: () => setState(() => _showPassword = !_showPassword),
                tooltip: _showPassword ? 'Ukryj hasło' : 'Pokaż hasło',
              ),
            ),
            obscureText: !_showPassword,
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
                _isRegisterMode
                    ? 'Masz już konto? Zaloguj się'
                    : 'Nie masz konta? Zarejestruj się',
                style: const TextStyle(fontSize: 14, height: 1.4),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _toggleMode() {
    setState(() {
      _isRegisterMode = !_isRegisterMode;
      _email = '';
      _password = '';
      _showPassword = false;
    });
  }

  Future<void> _submit() async {
    final formState = _formKey.currentState;
    if (formState == null) {
      toastification.show(
        context: context,
        title: const Text('Formularz niedostępny. Spróbuj ponownie.'),
        style: ToastificationStyle.flat,
        type: ToastificationType.error,
        autoCloseDuration: const Duration(seconds: 3),
        alignment: Alignment.bottomCenter,
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 24),
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

      if (!mounted) return;

      // Po udanym logowaniu/rejestracji — przejście do profilu
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const ProfileScreen()),
      );
    } catch (e) {
      if (mounted) {
        toastification.show(
          context: context,
          title: Text(e.toString()),
          style: ToastificationStyle.flat,
          type: ToastificationType.error,
          autoCloseDuration: const Duration(seconds: 4),
          alignment: Alignment.bottomCenter,
          margin: const EdgeInsets.fromLTRB(12, 0, 12, 24),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}
