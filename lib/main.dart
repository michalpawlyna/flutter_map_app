import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/services.dart';
import 'firebase_options.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'package:toastification/toastification.dart';
import 'screens/map_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/select_city_screen.dart';
import 'services/auth_service.dart';
import 'widgets/app_drawer.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  PaintingBinding.instance.imageCache.maximumSize = 100; // max 100 obrazów
  PaintingBinding.instance.imageCache.maximumSizeBytes = 50 * 1024 * 1024; // ~50 MB

  await Future.wait([
    dotenv.load(fileName: ".env"),
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]),
  ]);

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ToastificationWrapper(
      child: const MaterialApp(
        title: 'FlutterMapApp',
        debugShowCheckedModeBanner: false,
        home: MainScaffold(),
      ),
    );
  }
}

class MainScaffold extends StatefulWidget {
  const MainScaffold({Key? key}) : super(key: key);

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _selectedIndex = 0;

  final AuthService _authService = AuthService();

  final ValueNotifier<Map<String, dynamic>?> _routeResultNotifier =
      ValueNotifier(null);

  late final List<Widget> _screens = [
    MapScreen(
      scaffoldKey: _scaffoldKey,
      routeResultNotifier: _routeResultNotifier,
    ),
    ProfileScreen(onBack: () => setState(() => _selectedIndex = 0)),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: AppDrawer(
        scaffoldKey: _scaffoldKey,
        authService: _authService,
        onSelect: (index) async {
          if (index == -1) {
            final result = await Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const SelectCityScreen()));

            if (result is Map<String, dynamic> && result['route'] != null) {
              _routeResultNotifier.value = result;
              setState(() => _selectedIndex = 0);
            }
            return;
          }

          setState(() => _selectedIndex = index);
        },
      ),
      body: IndexedStack(index: _selectedIndex, children: _screens),
    );
  }
}
