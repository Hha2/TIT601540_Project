import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../constants/persist_brand.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../landing_screen.dart';
import 'login_screen.dart';

class SignupScreen extends StatefulWidget {
  final bool fromOnboarding;

  const SignupScreen({super.key, this.fromOnboarding = false});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _obscure = true;
  bool _obscureConfirm = true;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _signUp() async {
    final name = _nameCtrl.text.trim();
    final email = _emailCtrl.text.trim();
    final pass = _passCtrl.text;
    final confirm = _confirmCtrl.text;

    if (name.isEmpty || email.isEmpty || pass.isEmpty || confirm.isEmpty) {
      setState(() => _error = 'Fill all fields to create your account.');
      return;
    }
    if (!email.contains('@') || !email.contains('.')) {
      setState(() => _error = 'Enter a valid email address.');
      return;
    }
    if (pass.length < 6) {
      setState(() => _error = 'Password must be at least 6 characters.');
      return;
    }
    if (pass != confirm) {
      setState(() => _error = 'Passwords do not match.');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await context.read<AuthProvider>().signUp(email, pass, name);
      if (!mounted) return;
      Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (e) {
      if (mounted) setState(() => _error = _friendlyError(e.toString()));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _friendlyError(String raw) {
    if (raw.contains('email-already-in-use')) return 'An account already exists with this email. Log in instead.';
    if (raw.contains('invalid-email')) return 'Please enter a valid email.';
    if (raw.contains('weak-password')) return 'Password is too weak.';
    if (raw.contains('network-request-failed')) return 'Network problem. Check internet and try again.';
    return 'Account creation failed. Please try again.';
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>().theme;
    final logo = theme.isDark ? PersistAssets.logoDark : PersistAssets.logoLight;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: theme.isDark ? Brightness.light : Brightness.dark,
        systemNavigationBarColor: theme.background,
        systemNavigationBarIconBrightness: theme.isDark ? Brightness.light : Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: theme.background,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 18, 24, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    onPressed: () {
                      if (widget.fromOnboarding) {
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(builder: (_) => const LandingScreen()),
                          (_) => false,
                        );
                      } else {
                        Navigator.maybePop(context);
                      }
                    },
                    icon: Icon(Icons.arrow_back_ios_new_rounded, color: theme.text),
                  ),
                ),
                const SizedBox(height: 8),
                Center(child: Image.asset(logo, height: 74, fit: BoxFit.contain)),
                const SizedBox(height: 24),
                Text('Create your account', textAlign: TextAlign.center, style: TextStyle(fontSize: 27, fontWeight: FontWeight.w900, color: theme.text)),
                const SizedBox(height: 8),
                Text('Your plan starts private and personal.', textAlign: TextAlign.center, style: TextStyle(color: theme.textMuted, fontSize: 15, fontWeight: FontWeight.w600)),
                const SizedBox(height: 30),
                _AuthField(controller: _nameCtrl, label: 'Full Name', icon: Icons.person_outline_rounded, theme: theme),
                const SizedBox(height: 14),
                _AuthField(controller: _emailCtrl, label: 'Email', icon: Icons.email_outlined, theme: theme, keyboardType: TextInputType.emailAddress),
                const SizedBox(height: 14),
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
                const SizedBox(height: 14),
                _AuthField(
                  controller: _confirmCtrl,
                  label: 'Confirm Password',
                  icon: Icons.lock_outline_rounded,
                  theme: theme,
                  obscure: _obscureConfirm,
                  suffix: IconButton(
                    onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                    icon: Icon(_obscureConfirm ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: theme.textMuted),
                  ),
                ),
                const SizedBox(height: 16),
                if (_error != null) ...[
                  _ErrorBox(theme: theme, text: _error!),
                  const SizedBox(height: 16),
                ],
                SizedBox(
                  height: 58,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _signUp,
                    style: ElevatedButton.styleFrom(backgroundColor: theme.accent, foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
                    child: _loading
                        ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text('Create Account', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900)),
                  ),
                ),
                const SizedBox(height: 20),
                OutlinedButton(
                  onPressed: () => Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const LoginScreen())),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    foregroundColor: theme.text,
                    side: BorderSide(color: theme.border, width: 1.2),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  ),
                  child: const Text('Already have an account? Log In', style: TextStyle(fontWeight: FontWeight.w900)),
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
      style: TextStyle(color: theme.text, fontWeight: FontWeight.w700),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: theme.textMuted, fontWeight: FontWeight.w600),
        prefixIcon: Icon(icon, color: theme.textMuted),
        suffixIcon: suffix,
        filled: true,
        fillColor: theme.card,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide(color: theme.border)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide(color: theme.border)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide(color: theme.accent, width: 1.8)),
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
