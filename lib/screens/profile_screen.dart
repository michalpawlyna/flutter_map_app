import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/achievement.dart';
import '../models/user.dart';
import '../widgets/achievement_showcase_widget.dart';
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

  late Future<List<Achievement>> _achievementsFuture;

  late FocusNode _displayNameFocusNode;
  late FocusNode _usernameFocusNode;

  @override
  void initState() {
    super.initState();
    _achievementsFuture = _loadAchievements();

    _displayNameFocusNode = FocusNode()..addListener(_onFocusChanged);
    _usernameFocusNode = FocusNode()..addListener(_onFocusChanged);
  }

  Future<List<Achievement>> _loadAchievements() async {
    final achievementsSnapshot =
        await FirebaseFirestore.instance.collection('achievements').get();
    return achievementsSnapshot.docs
        .map((doc) => Achievement.fromSnapshot(doc))
        .toList();
  }

  void _attachListeners() {
    _displayNameController?.removeListener(_onControllerChanged);
    _usernameController?.removeListener(_onControllerChanged);
    _displayNameController?.addListener(_onControllerChanged);
    _usernameController?.addListener(_onControllerChanged);
  }

  void _onControllerChanged() {
    if (mounted) setState(() {});
  }

  void _onFocusChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _displayNameController?.removeListener(_onControllerChanged);
    _usernameController?.removeListener(_onControllerChanged);
    _displayNameController?.dispose();
    _usernameController?.dispose();

    _displayNameFocusNode.removeListener(_onFocusChanged);
    _displayNameFocusNode.dispose();
    _usernameFocusNode.removeListener(_onFocusChanged);
    _usernameFocusNode.dispose();

    super.dispose();
  }

  InputDecoration _fieldDecoration(String hint, {bool focused = false}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.black54),
      filled: true,
      fillColor: const Color.fromARGB(255, 239, 240, 241),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.black, width: 1),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 14,
      ),
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

  Future<void> _confirmAndDeleteAccount(User user) async {
    final TextEditingController ctrl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            final isConfirmed = ctrl.text.trim().toLowerCase() == 'delete';
            return AlertDialog(
              backgroundColor: const Color(0xFFF8F9FA),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: const Text(
                'Potwierdź usunięcie konta',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'To działanie jest nieodwracalne. Utracisz wszystkie swoje postępy, odznaki i zapisane miejsca.\n\nAby potwierdzić, wpisz "delete" w polu poniżej.',
                    style: TextStyle(color: Colors.black87, height: 1.5),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: ctrl,
                    onChanged: (value) => setState(() {}),
                    decoration: _fieldDecoration('Wpisz "delete"'),
                    autofocus: true,
                  ),
                ],
              ),
              actionsPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(false),
                  child: const Text(
                    'Anuluj',
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: isConfirmed
                      ? () => Navigator.of(ctx).pop(true)
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    textStyle: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                  child: const Text('Usuń'),
                ),
              ],
            );
          },
        );
      },
    );

    if (confirmed == true) {
      await _deleteAccount(user);
    }
  }

  Future<void> _deleteAccount(User user) async {
    setState(() => _loading = true);
    final uid = user.uid;

    try {
      // First, try to delete the Firebase Auth user.
      // This is the most likely operation to fail if the user's session is old.
      await user.delete();

      // If user.delete() is successful, then delete the firestore data.
      try {
        await FirebaseFirestore.instance.collection('users').doc(uid).delete();
      } catch (e) {
        // This error is less critical, as the auth user is already deleted.
        // We can just log it.
        debugPrint('[ProfileScreen] firestore user delete failed: $e');
      }

      // Sign out completely.
      try {
        await _authService.signOut();
      } catch (_) {}

      if (mounted) {
        toastification.show(
          context: context,
          title: const Text('Konto usunięte pomyślnie'),
          style: ToastificationStyle.flat,
          type: ToastificationType.success,
          autoCloseDuration: const Duration(seconds: 3),
          alignment: Alignment.bottomCenter,
          margin: const EdgeInsets.fromLTRB(12, 0, 12, 24),
        );

        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } on FirebaseAuthException catch (e) {
      debugPrint('[ProfileScreen] auth delete failed: $e');

      if (e.code == 'requires-recent-login') {
        if (mounted) {
          toastification.show(
            context: context,
            title: const Text('Wymagane ponowne zalogowanie'),
            description: const Text(
                'Ze względów bezpieczeństwa, zaloguj się ponownie, aby usunąć konto.'),
            style: ToastificationStyle.flat,
            type: ToastificationType.error,
            autoCloseDuration: const Duration(seconds: 6),
            alignment: Alignment.bottomCenter,
            margin: const EdgeInsets.fromLTRB(12, 0, 12, 24),
          );
        }
        // Sign the user out so they can log in again.
        try {
          await _authService.signOut();
        } catch (_) {}
      } else {
        // Handle other FirebaseAuthExceptions
        if (mounted) {
          toastification.show(
            context: context,
            title: Text('Błąd podczas usuwania konta: ${e.message}'),
            style: ToastificationStyle.flat,
            type: ToastificationType.error,
            autoCloseDuration: const Duration(seconds: 4),
            alignment: Alignment.bottomCenter,
            margin: const EdgeInsets.fromLTRB(12, 0, 12, 24),
          );
        }
      }
    } catch (e) {
      // Handle any other generic errors
      debugPrint('[ProfileScreen] delete account error: $e');
      if (mounted) {
        toastification.show(
          context: context,
          title: Text('Wystąpił nieoczekiwany błąd: ${e.toString()}'),
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

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return StreamBuilder<User?>(
      stream: _authService.authStateChanges,
      builder: (context, authSnapshot) {
        final user = authSnapshot.data ?? _authService.currentUser;

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
                      icon: const Icon(Icons.check, color: Colors.green),
                      onPressed: () => _saveChanges(uid),
                      tooltip: 'Zapisz zmiany',
                    );
                  },
                ),
              ),
            ],
          ),
          backgroundColor: Colors.grey[50],
          body: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () => FocusScope.of(context).unfocus(),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child:
                    user == null
                        ? _buildNotLoggedIn(context)
                        : _buildProfileForUser(user),
              ),
            ),
          ),
        );
      },
    );
  }

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
        if (snapshot.hasError) {
          return Column(
            children: [
              const Icon(Icons.error, color: Colors.red, size: 48),
              const SizedBox(height: 8),
              Text('Błąd podczas pobierania profilu: ${snapshot.error}'),
            ],
          );
        }

        AppUser? appUser;
        if (snapshot.hasData && snapshot.data!.exists) {
          appUser = AppUser.fromSnapshot(snapshot.data!);
        }

        final displayName = appUser?.displayName ?? '';
        final username = appUser?.username ?? '';

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
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircleAvatar(
                      radius: 42,
                      backgroundColor: Colors.grey[200],
                      backgroundImage: user.photoURL != null
                          ? NetworkImage(user.photoURL!)
                          : null,
                      child: user.photoURL == null
                          ? const Icon(
                              Icons.person,
                              size: 44,
                              color: Colors.black54,
                            )
                          : null,
                    ),
                    // Show equipped achievement badge (bottom-right)
                    if (appUser != null && appUser.equippedAchievements.isNotEmpty)
                      FutureBuilder<List<Achievement>>(
                        future: _achievementsFuture,
                        builder: (ctx, achSnap) {
                          if (!achSnap.hasData) return const SizedBox.shrink();
                          final all = achSnap.data!;
                          final eid = appUser!.equippedAchievements.first;
                          final match = all.firstWhere(
                              (a) => a.id == eid,
                              orElse: () => Achievement(
                                  id: '',
                                  criteria: {},
                                  desc: '',
                                  key: '',
                                  title: '',
                                  photoUrl: null,
                                  type: AchievementType.unknown));
                          if (match.id.isEmpty) return const SizedBox.shrink();

                          return Positioned(
                            bottom: 0,
                            right: MediaQuery.of(context).size.width > 600 ? 0 : -2,
                            child: Container(
                              width: 34,
                              height: 34,
                              // No background or border so badge appears with transparent background
                              child: ClipOval(
                                child: match.photoUrl != null
                                    ? Image.network(
                                        match.photoUrl!,
                                        fit: BoxFit.cover,
                                        width: 34,
                                        height: 34,
                                        errorBuilder: (_, __, ___) => Icon(
                                          Icons.shield,
                                          size: 18,
                                          color: Colors.grey[700],
                                        ),
                                      )
                                    : Icon(
                                        Icons.shield,
                                        size: 18,
                                        color: Colors.grey[700],
                                      ),
                              ),
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              if (displayName.isNotEmpty || email.isNotEmpty)
                Center(
                  child: Column(
                    children: [
                      if (displayName.isNotEmpty)
                        Text(
                          displayName,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      if (email.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 6.0),
                          child: Text(
                            email,
                            style: TextStyle(
                              fontSize: 15,
                              color: Colors.grey[600],
                            ),
                          ),
                        ),
                      const SizedBox(height: 18),
                    ],
                  ),
                ),
              if (appUser != null)
                FutureBuilder<List<Achievement>>(
                  future: _achievementsFuture,
                  builder: (context, achievementSnapshot) {
                    if (achievementSnapshot.hasData) {
                      return AchievementShowcaseWidget(
                        equippedAchievementIds: appUser!.equippedAchievements,
                        allAchievements: achievementSnapshot.data!,
                        user: appUser,
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),

              const SizedBox(height: 18),
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
                focusNode: _displayNameFocusNode,
                decoration: _fieldDecoration('Wprowadź imię i nazwisko',
                    focused: _displayNameFocusNode.hasFocus),
                buildCounter: (_,
                        {required int currentLength,
                        required bool isFocused,
                        int? maxLength}) =>
                    null,
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
                focusNode: _usernameFocusNode,
                decoration: _fieldDecoration('Wprowadź nazwę użytkownika',
                    focused: _usernameFocusNode.hasFocus),
                validator: (val) {
                  final v = (val ?? '').trim().toLowerCase();
                  final regex = RegExp(r'^[a-z0-9._-]{3,30}$');
                  if (v.isEmpty) return 'Wprowadź nazwę użytkownika';
                  if (!regex.hasMatch(v))
                    return 'Nieprawidłowa nazwa (3-30: a-z,0-9 . _ -)';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              const Text(
                'E-mail',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Stack(
                alignment: Alignment.centerRight,
                children: [
                  TextFormField(
                    initialValue: email.isNotEmpty ? email : '',
                    enabled: false,
                    readOnly: true,
                    decoration:
                        _fieldDecoration(email.isNotEmpty ? '' : 'Brak email')
                            .copyWith(
                      fillColor: Colors.grey[200],
                    ),
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 12.0),
                    child: IconButton(
                      iconSize: 20,
                      icon: Icon(
                        Icons.info_outline,
                        color: Colors.grey[600],
                      ),
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            backgroundColor: const Color(0xFFF8F9FA),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            title: const Text(
                              'Informacja',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            content: const Text(
                              'Nie można zmienić e-maila przypisanego do konta.',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(),
                                child: const Text(
                                  'OK',
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 18),

              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed:
                      _loading ? null : () => _confirmAndDeleteAccount(user),
                  style: TextButton.styleFrom(
                    backgroundColor:
                        Theme.of(context).brightness == Brightness.dark
                            ? Colors.red.shade900.withOpacity(0.2)
                            : Colors.red.shade50,
                    foregroundColor:
                        Theme.of(context).brightness == Brightness.dark
                            ? Colors.red.shade400
                            : Colors.red.shade600,
                    padding: const EdgeInsets.symmetric(
                      vertical: 14,
                      horizontal: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child:
                      _loading
                          ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                          : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.delete_forever),
                              SizedBox(width: 8),
                              Text(
                                'Usuń konto',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                ),
              ),
              const SizedBox(height: 18),
            ],
          ),
        );
      },
    );
  }
}
