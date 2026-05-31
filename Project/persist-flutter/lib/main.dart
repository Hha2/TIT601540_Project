import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'constants/persist_brand.dart';
import 'firebase_options.dart';
import 'providers/auth_provider.dart';
import 'providers/goals_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/landing_screen.dart';
import 'screens/main_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const PersistApp());
}

class PersistApp extends StatelessWidget {
  const PersistApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => GoalsProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp(
            title: PersistBrand.appName,
            debugShowCheckedModeBanner: false,
            theme: themeProvider.theme.toThemeData(),
            home: const AppRoot(),
          );
        },
      ),
    );
  }
}

class AppRoot extends StatefulWidget {
  const AppRoot({super.key});

  @override
  State<AppRoot> createState() => _AppRootState();
}

class _AppRootState extends State<AppRoot> {
  String? _lastUid;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    if (auth.loading) return const PersistNativeSplash();

    if (!auth.isAuthenticated) {
      _lastUid = null;
      return const LandingScreen();
    }

    final uid = auth.user!.uid;
    if (_lastUid != uid) {
      _lastUid = uid;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.read<GoalsProvider>().init(uid);
      });
    }

    return const MainScreen();
  }
}

class PersistNativeSplash extends StatelessWidget {
  const PersistNativeSplash({super.key});

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Color(0xFF081822),
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFF081822),
        body: SizedBox.expand(
          child: Image.asset(
            PersistAssets.loadingDark,
            fit: BoxFit.cover,
            alignment: Alignment.center,
          ),
        ),
      ),
    );
  }
}
