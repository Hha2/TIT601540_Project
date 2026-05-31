import 'package:flutter/material.dart';

class AppTheme {
  final String id;
  final String name;
  final bool isDark;
  final Color background;
  final Color card;
  final Color cardAlt;
  final Color text;
  final Color textMuted;
  final Color textFaint;
  final Color border;
  final Color accent;
  final Color accentSoft;
  final List<Color> gradient;
  final List<Color> gradientHeader;
  final Color success;
  final Color warning;
  final Color danger;

  const AppTheme({
    required this.id,
    required this.name,
    required this.isDark,
    required this.background,
    required this.card,
    required this.cardAlt,
    required this.text,
    required this.textMuted,
    required this.textFaint,
    required this.border,
    required this.accent,
    required this.accentSoft,
    required this.gradient,
    required this.gradientHeader,
    required this.success,
    required this.warning,
    required this.danger,
  });

  ThemeData toThemeData() {
    return ThemeData(
      brightness: isDark ? Brightness.dark : Brightness.light,
      scaffoldBackgroundColor: background,
      colorScheme: ColorScheme(
        brightness: isDark ? Brightness.dark : Brightness.light,
        primary: accent,
        onPrimary: Colors.white,
        secondary: accentSoft,
        onSecondary: text,
        error: danger,
        onError: Colors.white,
        surface: card,
        onSurface: text,
      ),
      cardColor: card,
      dividerColor: border,
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        foregroundColor: text,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? accent : Colors.grey,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? accentSoft : Colors.grey.withValues(alpha: 0.3),
        ),
      ),
    );
  }

  LinearGradient get linearGradient => LinearGradient(
        colors: gradient,
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  LinearGradient get headerGradient => LinearGradient(
        colors: gradientHeader,
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
}


const persistTheme = AppTheme(
  id: 'persist',
  name: 'Persist',
  isDark: false,
  background: Color(0xFFF8FBFF),
  card: Color(0xFFFFFFFF),
  cardAlt: Color(0xFFEAF7F6),
  text: Color(0xFF1E2836),
  textMuted: Color(0xFF647184),
  textFaint: Color(0xFFA9B3BF),
  border: Color(0xFFE1E4E8),
  accent: Color(0xFF3FA7A0),
  accentSoft: Color(0xFFE0F4F2),
  gradient: [Color(0xFF3FA7A0), Color(0xFF2F8F8A)],
  gradientHeader: [Color(0xFF1E2836), Color(0xFF2E777B)],
  success: Color(0xFF4CAF8F),
  warning: Color(0xFFE8A84B),
  danger: Color(0xFFFF8A80),
);

const calmNavyTheme = AppTheme(
  id: 'calm_navy',
  name: 'Calm Navy',
  isDark: true,
  background: Color(0xFF101927),
  card: Color(0xFF182537),
  cardAlt: Color(0xFF203248),
  text: Color(0xFFF8FBFF),
  textMuted: Color(0xFFB9C5D3),
  textFaint: Color(0xFF6F8091),
  border: Color(0xFF2B3A4D),
  accent: Color(0xFF3FA7A0),
  accentSoft: Color(0xFF163F42),
  gradient: [Color(0xFF3FA7A0), Color(0xFF2E777B)],
  gradientHeader: [Color(0xFF0E1724), Color(0xFF1E2836)],
  success: Color(0xFF6FCF97),
  warning: Color(0xFFE8A84B),
  danger: Color(0xFFFF8A80),
);

// Backward-compatible names used by older screens/settings.
const emeraldTheme = persistTheme;
const roseTheme = persistTheme;
const violetTheme = persistTheme;
const obsidianTheme = calmNavyTheme;
const midnightTheme = calmNavyTheme;

const Map<String, AppTheme> allAppThemes = {
  'persist': persistTheme,
  'calm_navy': calmNavyTheme,
  // Legacy IDs kept so old Settings/Profile UI cannot crash.
  'emerald': persistTheme,
  'rose': persistTheme,
  'violet': persistTheme,
  'obsidian': calmNavyTheme,
  'midnight': calmNavyTheme,
};

const Map<String, AppTheme> allThemes = allAppThemes;
