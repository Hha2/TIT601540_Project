import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../constants/persist_brand.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../landing_screen.dart';
import '../onboarding_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscure = true;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    final email = _emailCtrl.text.trim();
    final pass = _passCtrl.text;
    if (email.isEmpty || pass.isEmpty) {
      setState(() => _error = 'Enter your email and password.');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await context.read<AuthProvider>().signIn(email, pass);
      if (!mounted) return;
      Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (e) {
      if (mounted) setState(() => _error = _friendlyError(e.toString()));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _resetPassword() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty) {
      setState(() => _error = 'Enter your email first.');
      return;
    }
    try {
      await context.read<AuthProvider>().resetPassword(email);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Reset email sent.')));
    } catch (e) {
      if (mounted) setState(() => _error = _friendlyError(e.toString()));
    }
  }

  String _friendlyError(String raw) {
    if (raw.contains('invalid-credential') || raw.contains('wrong-password')) return 'Invalid email or password.';
    if (raw.contains('user-not-found')) return 'No account found with this email.';
    if (raw.contains('invalid-email')) return 'Please enter a valid email.';
    if (raw.contains('too-many-requests')) return 'Too many attempts. Try again later.';
    if (raw.contains('network-request-failed')) return 'Network problem. Check internet and try again.';
    return 'Login failed. Please try again.';
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>().theme;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: PersistBrand.coreLightBackground,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: PersistBrand.coreLightBackground,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(22, 16, 22, 26),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    onPressed: () => Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const LandingScreen()),
                      (_) => false,
                    ),
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, color: PersistBrand.coreLightText),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.fromLTRB(22, 24, 22, 26),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [PersistBrand.coreDarkBackground, PersistBrand.coreDarkSurface],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [BoxShadow(color: PersistBrand.coreDarkBackground.withOpacity(.18), blurRadius: 24, offset: const Offset(0, 14))],
                  ),
                  child: Column(
                    children: [
                      Image.asset(PersistAssets.logoDark, height: 58, fit: BoxFit.contain),
                      const SizedBox(height: 22),
                      const Text('Welcome back', textAlign: TextAlign.center, style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.white)),
                      const SizedBox(height: 8),
                      const Text('Continue your steady routine.', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFFAACBD0), fontSize: 15, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(26),
                    border: Border.all(color: const Color(0xFFD4E8E6)),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(.04), blurRadius: 18, offset: const Offset(0, 10))],
                  ),
                  child: Column(
                    children: [
                      _AuthField(controller: _emailCtrl, label: 'Email', icon: Icons.email_outlined, theme: theme, keyboardType: TextInputType.emailAddress),
                      const SizedBox(height: 15),
                      _AuthField(
                        controller: _passCtrl,
                        label: 'Password',
                        icon: Icons.lock_outline_rounded,
                        theme: theme,
                        obscure: _obscure,
                        suffix: IconButton(
                          onPressed: () => setState(() => _obscure = !_obscure),
                          icon: Icon(_obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: theme.textMuted),
                        ),
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(onPressed: _resetPassword, child: const Text('Forgot password?', style: TextStyle(color: PersistBrand.coreLightPrimary, fontWeight: FontWeight.w800))),
                      ),
                      if (_error != null) ...[
                        _ErrorBox(theme: theme, text: _error!),
                        const SizedBox(height: 16),
                      ],
                      SizedBox(
                        height: 56,
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _loading ? null : _signIn,
                          style: ElevatedButton.styleFrom(backgroundColor: PersistBrand.coreLightPrimary, foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18))),
                          child: _loading
                              ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : const Text('Log In', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900)),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                OutlinedButton(
                  onPressed: () => Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const OnboardingScreen())),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    foregroundColor: PersistBrand.coreLightText,
                    side: const BorderSide(color: Color(0xFFD4E8E6), width: 1.2),
                    backgroundColor: Colors.white.withOpacity(.85),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  ),
                  child: const Text('New here? Get Started', style: TextStyle(fontWeight: FontWeight.w900)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AuthField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final dynamic theme;
  final TextInputType? keyboardType;
  final bool obscure;
  final Widget? suffix;

  const _AuthField({required this.controller, required this.label, required this.icon, required this.theme, this.keyboardType, this.obscure = false, this.suffix});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscure,
      style: const TextStyle(color: PersistBrand.coreLightText, fontWeight: FontWeight.w700),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: theme.textMuted, fontWeight: FontWeight.w600),
        prefixIcon: Icon(icon, color: theme.textMuted),
        suffixIcon: suffix,
        filled: true,
        fillColor: PersistBrand.coreLightBackground,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: const BorderSide(color: Color(0xFFD4E8E6))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: const BorderSide(color: Color(0xFFD4E8E6))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: const BorderSide(color: PersistBrand.coreLightPrimary, width: 1.8)),
      ),
    );
  }
}

class _ErrorBox extends StatelessWidget {
  final dynamic theme;
  final String text;

  const _ErrorBox({required this.theme, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(color: theme.danger.withOpacity(.10), borderRadius: BorderRadius.circular(16), border: Border.all(color: theme.danger.withOpacity(.28))),
      child: Text(text, style: TextStyle(color: theme.danger, fontWeight: FontWeight.w700)),
    );
  }
}
