import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_options.dart';
import 'providers/auth_provider.dart';
import 'providers/goals_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/main_screen.dart';
import 'screens/onboarding_screen.dart';

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
            title: 'Persist',
            debugShowCheckedModeBanner: false,
            theme: themeProvider.theme.toThemeData(),
            home: const AppRoot(),
          );
        },
      ),
    );
  }
}

class AppRoot extends StatelessWidget {
  const AppRoot({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    if (auth.loading) return const _LoadingScreen();
    if (!auth.isAuthenticated) return const LoginScreen();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<GoalsProvider>().init(auth.user!.uid);
    });

    return const _OnboardingGate();
  }
}

class _OnboardingGate extends StatefulWidget {
  const _OnboardingGate();
  @override
  State<_OnboardingGate> createState() => _OnboardingGateState();
}

class _OnboardingGateState extends State<_OnboardingGate> {
  bool? _done;
  @override
  void initState() { super.initState(); _load(); }
  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) setState(() => _done = prefs.getBool('persist_onboarding_done') ?? false);
  }
  @override
  Widget build(BuildContext context) {
    if (_done == null) return const _LoadingScreen();
    if (_done == false) return OnboardingScreen(onFinished: () => setState(() => _done = true));
    return const MainScreen();
  }
}

class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen();
  @override
  Widget build(BuildContext context) {
    final theme = context.read<ThemeProvider>().theme;
    return Scaffold(
      backgroundColor: theme.background,
      body: Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 104, height: 104, padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: theme.card, borderRadius: BorderRadius.circular(30), border: Border.all(color: theme.border), boxShadow: [BoxShadow(color: theme.accent.withValues(alpha: .15), blurRadius: 30, offset: const Offset(0, 16))]),
            child: ClipRRect(borderRadius: BorderRadius.circular(24), child: Image.asset('assets/Logo.jpeg', fit: BoxFit.cover)),
          ),
          const SizedBox(height: 20),
          Text('Persist', style: TextStyle(color: theme.text, fontSize: 28, fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          Text('Small steps. Lasting change.', style: TextStyle(color: theme.accent, fontWeight: FontWeight.w700)),
        ]),
      ),
    );
  }
}
