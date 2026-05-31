import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/persist_brand.dart';
import 'auth/login_screen.dart';
import 'onboarding_screen.dart';

class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key});

  static const _navColor = PersistBrand.coreDarkBackground;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).padding.bottom;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: _navColor,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        extendBodyBehindAppBar: true,
        backgroundColor: _navColor,
        body: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              PersistAssets.loadingDark,
              fit: BoxFit.cover,
              alignment: Alignment.center,
            ),
            Positioned(
              left: 24,
              right: 24,
              bottom: bottom + 22,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _LandingButton(
                    label: 'Get Started',
                    filled: true,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const OnboardingScreen()),
                      );
                    },
                  ),
                  const SizedBox(height: 14),
                  _LandingButton(
                    label: 'Log In',
                    filled: false,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LandingButton extends StatelessWidget {
  final String label;
  final bool filled;
  final VoidCallback onTap;

  const _LandingButton({required this.label, required this.filled, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 58,
      child: filled
          ? ElevatedButton(
              onPressed: onTap,
              style: ElevatedButton.styleFrom(
                backgroundColor: PersistBrand.coreDarkPrimary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
              child: Text(label, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            )
          : OutlinedButton(
              onPressed: onTap,
              style: OutlinedButton.styleFrom(
                backgroundColor: Colors.white.withOpacity(.08),
                foregroundColor: Colors.white,
                side: BorderSide(color: Colors.white.withOpacity(.30), width: 1.3),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
              child: Text(label, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            ),
    );
  }
}
