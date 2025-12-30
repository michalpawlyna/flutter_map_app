import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/achievement.dart';
import '../models/user.dart';
import 'package:toastification/toastification.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';
import 'manage_achievements_screen.dart';

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

  late final TextEditingController _displayNameController;
  late final TextEditingController _usernameController;

  String _serverDisplayName = '';
  String _serverUsername = '';

  bool _loading = false;
  bool _saving = false;

  late Future<List<Achievement>> _achievementsFuture;

  late final FocusNode _displayNameFocusNode;
  late final FocusNode _usernameFocusNode;

  @override
  void initState() {
    super.initState();
    _achievementsFuture = _loadAchievements();

    _displayNameController = TextEditingController();
    _usernameController = TextEditingController();

    _displayNameController.addListener(_onControllerChanged);
    _usernameController.addListener(_onControllerChanged);

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
    try {
      _displayNameController.removeListener(_onControllerChanged);
    } catch (_) {}
    try {
      _usernameController.removeListener(_onControllerChanged);
    } catch (_) {}

    _displayNameController.addListener(_onControllerChanged);
    _usernameController.addListener(_onControllerChanged);
  }

  void _onControllerChanged() {
    if (mounted) setState(() {});
  }

  void _onFocusChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    try {
      _displayNameController.removeListener(_onControllerChanged);
    } catch (_) {}
    try {
      _usernameController.removeListener(_onControllerChanged);
    } catch (_) {}

    try {
      _displayNameController.dispose();
    } catch (_) {}
    try {
      _usernameController.dispose();
    } catch (_) {}

    try {
      _displayNameFocusNode.removeListener(_onFocusChanged);
    } catch (_) {}
    try {
      _displayNameFocusNode.dispose();
    } catch (_) {}
    try {
      _usernameFocusNode.removeListener(_onFocusChanged);
    } catch (_) {}
    try {
      _usernameFocusNode.dispose();
    } catch (_) {}

    super.dispose();
  }

  bool get _hasChanges {
    final d = _displayNameController.text.trim();
    final u = _usernameController.text.trim();
    return (d != _serverDisplayName) || (u != _serverUsername);
  }

  Future<void> _saveChanges(String uid) async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final newDisplayName = _displayNameController.text.trim();
    final newUsername = _usernameController.text.trim();

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

  void _setControllerTextSafely(TextEditingController controller, String text) {
    if (controller.text == text) return;

    controller.removeListener(_onControllerChanged);
    try {
      controller.text = text;

      controller.selection = TextSelection.collapsed(
        offset: controller.text.length,
      );
    } finally {
      controller.addListener(_onControllerChanged);
    }
  }

  Future<void> _confirmAndDeleteAccount(User user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder:
          (ctx) => Dialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.delete, color: Colors.black, size: 28),
                    ),
                  ),
                  const SizedBox(height: 12),

                  const Text(
                    'Usuń konto',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),

                  const Text(
                    'Ta operacja jest nieodwracalna. Po usunięciu konta utracisz wszystkie swoje postępy, odznaki i zapisane dane.\n\nCzy na pewno chcesz usunąć konto?',
                    textAlign: TextAlign.left,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.black54,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => Navigator.of(ctx).pop(false),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            textStyle: const TextStyle(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          child: const Text('Anuluj'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.of(ctx).pop(true),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.red,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            textStyle: const TextStyle(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          child: const Text('Usuń konto'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
    );

    if (confirmed == true) {
      await _deleteAccount(user);
    }
  }

  Future<void> _deleteAccount(User user) async {
    setState(() => _loading = true);
    final uid = user.uid;

    try {
      await user.delete();

      try {
        await FirebaseFirestore.instance.collection('users').doc(uid).delete();
      } catch (e) {
        debugPrint('[ProfileScreen] firestore user delete failed: $e');
      }

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
              'Ze względów bezpieczeństwa, zaloguj się ponownie, aby usunąć konto.',
            ),
            style: ToastificationStyle.flat,
            type: ToastificationType.error,
            autoCloseDuration: const Duration(seconds: 6),
            alignment: Alignment.bottomCenter,
            margin: const EdgeInsets.fromLTRB(12, 0, 12, 24),
          );
        }

        try {
          await _authService.signOut();
        } catch (_) {}
      } else {
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
          backgroundColor: Colors.white,
          body: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () => FocusScope.of(context).unfocus(),
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 560),
                      child:
                          user == null
                              ? _buildNotLoggedIn(context)
                              : _buildProfileForUser(user),
                    ),
                  ),
                ),
                if (user != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                    child: SizedBox(
                      width: double.infinity,
                      child: TextButton(
                        onPressed:
                            _loading
                                ? null
                                : () => _confirmAndDeleteAccount(user),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            vertical: 16,
                            horizontal: 16,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child:
                            _loading
                                ? const SizedBox(
                                  height: 18,
                                  width: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                                : const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      'Usuń konto',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.red,
                                      ),
                                    ),
                                  ],
                                ),
                      ),
                    ),
                  ),
              ],
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
                borderRadius: BorderRadius.circular(12),
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

        if (_serverDisplayName != displayName) {
          _serverDisplayName = displayName;
          if (!_displayNameFocusNode.hasFocus) {
            _setControllerTextSafely(_displayNameController, displayName);
          }
        }
        if (_serverUsername != username) {
          _serverUsername = username;
          if (!_usernameFocusNode.hasFocus) {
            _setControllerTextSafely(_usernameController, username);
          }
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

                    if (appUser != null &&
                        appUser.equippedAchievements.isNotEmpty)
                      FutureBuilder<List<Achievement>>(
                        future: _achievementsFuture,
                        builder: (ctx, achSnap) {
                          if (!achSnap.hasData) return const SizedBox.shrink();
                          final all = achSnap.data!;
                          final eid = appUser!.equippedAchievements.first;
                          final match = all.firstWhere(
                            (a) => a.id == eid,
                            orElse:
                                () => Achievement(
                                  id: '',
                                  criteria: {},
                                  desc: '',
                                  key: '',
                                  title: '',
                                  photoUrl: null,
                                  type: AchievementType.unknown,
                                ),
                          );
                          if (match.id.isEmpty) return const SizedBox.shrink();

                          return Positioned(
                            bottom: 0,
                            right:
                                MediaQuery.of(context).size.width > 600
                                    ? 0
                                    : -2,
                            child: Container(
                              width: 34,
                              height: 34,
                              child: ClipOval(
                                child:
                                    match.photoUrl != null
                                        ? Image.network(
                                          match.photoUrl!,
                                          fit: BoxFit.cover,
                                          width: 34,
                                          height: 34,
                                          errorBuilder:
                                              (_, __, ___) => Icon(
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

                    if (appUser != null)
                      FutureBuilder<List<Achievement>>(
                        future: _achievementsFuture,
                        builder: (ctx, achSnap) {
                          if (!achSnap.hasData) return const SizedBox.shrink();
                          final all = achSnap.data!;

                          final hasEquipped =
                              appUser!.equippedAchievements.isNotEmpty;

                          Widget editIcon;
                          if (hasEquipped) {
                            editIcon = Positioned(
                              top: 0,
                              right: 0,
                              child: Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.black.withOpacity(0.08),
                                    width: 1,
                                  ),
                                ),
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(18),
                                    onTap: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder:
                                              (_) => ManageAchievementsScreen(
                                                user: appUser!,
                                                allAchievements: all,
                                              ),
                                        ),
                                      );
                                    },
                                    child: const Icon(
                                      Icons.edit_outlined,
                                      size: 18,
                                      color: Colors.black,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          } else {
                            editIcon = Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.black.withOpacity(0.08),
                                    width: 1,
                                  ),
                                ),
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(18),
                                    onTap: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder:
                                              (_) => ManageAchievementsScreen(
                                                user: appUser!,
                                                allAchievements: all,
                                              ),
                                        ),
                                      );
                                    },
                                    child: const Icon(
                                      Icons.push_pin,
                                      size: 18,
                                      color: Colors.black,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }

                          return editIcon;
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
              const SizedBox(height: 24),

              TextFormField(
                controller: _displayNameController,
                focusNode: _displayNameFocusNode,
                textInputAction: TextInputAction.next,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  labelText: 'Imię i nazwisko',
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 18,
                  ),
                  border: const OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.black12),
                  ),
                  enabledBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.black12),
                  ),
                  focusedBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.black, width: 2),
                  ),
                  floatingLabelStyle: const TextStyle(color: Colors.black),
                  suffixIcon:
                      _displayNameController.text.isNotEmpty
                          ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () => _displayNameController.clear(),
                            tooltip: 'Wyczyść',
                            splashRadius: 18,
                            constraints: const BoxConstraints(
                              minWidth: 40,
                              minHeight: 40,
                            ),
                          )
                          : null,
                ),
                validator: (val) {
                  final v = (val ?? '').trim();
                  if (v.isEmpty) return 'Wprowadź imię i nazwisko';
                  if (v.length > 80) return 'Za długie (maks. 80 znaków)';
                  return null;
                },
                onFieldSubmitted: (_) => FocusScope.of(context).nextFocus(),
              ),

              const SizedBox(height: 24),

              TextFormField(
                controller: _usernameController,
                focusNode: _usernameFocusNode,
                textInputAction: TextInputAction.done,
                textCapitalization: TextCapitalization.none,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  labelText: 'Nazwa użytkownika',
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 18,
                  ),
                  border: const OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.black12),
                  ),
                  enabledBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.black12),
                  ),
                  focusedBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.black, width: 2),
                  ),
                  floatingLabelStyle: const TextStyle(color: Colors.black),
                  suffixIcon:
                      _usernameController.text.isNotEmpty
                          ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () => _usernameController.clear(),
                            tooltip: 'Wyczyść',
                            splashRadius: 18,
                            constraints: const BoxConstraints(
                              minWidth: 40,
                              minHeight: 40,
                            ),
                          )
                          : null,
                ),
                validator: (val) {
                  final v = (val ?? '').trim().toLowerCase();
                  final regex = RegExp(r'^[a-z0-9._-]{3,30}$');
                  if (v.isEmpty) return 'Wprowadź nazwę użytkownika';
                  if (!regex.hasMatch(v))
                    return 'Nieprawidłowa nazwa (3-30: a-z,0-9 . _ -)';
                  return null;
                },
                onFieldSubmitted: (_) => FocusScope.of(context).unfocus(),
              ),
            ],
          ),
        );
      },
    );
  }
}
