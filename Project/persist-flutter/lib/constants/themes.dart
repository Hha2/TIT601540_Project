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

const emeraldTheme = AppTheme(
  id: 'emerald',
  name: 'Emerald',
  isDark: false,
  background: Color(0xFFF0FDF4),
  card: Color(0xFFFFFFFF),
  cardAlt: Color(0xFFDCFCE7),
  text: Color(0xFF14532D),
  textMuted: Color(0xFF166534),
  textFaint: Color(0xFF86EFAC),
  border: Color(0xFFBBF7D0),
  accent: Color(0xFF10B981),
  accentSoft: Color(0xFFD1FAE5),
  gradient: [Color(0xFF10B981), Color(0xFF059669)],
  gradientHeader: [Color(0xFF059669), Color(0xFF047857)],
  success: Color(0xFF22C55E),
  warning: Color(0xFFF59E0B),
  danger: Color(0xFFEF4444),
);

const roseTheme = AppTheme(
  id: 'rose',
  name: 'Rose',
  isDark: false,
  background: Color(0xFFFFF1F2),
  card: Color(0xFFFFFFFF),
  cardAlt: Color(0xFFFFE4E6),
  text: Color(0xFF881337),
  textMuted: Color(0xFF9F1239),
  textFaint: Color(0xFFFDA4AF),
  border: Color(0xFFFECDD3),
  accent: Color(0xFFF43F5E),
  accentSoft: Color(0xFFFFE4E6),
  gradient: [Color(0xFFF43F5E), Color(0xFFE11D48)],
  gradientHeader: [Color(0xFFE11D48), Color(0xFFBE123C)],
  success: Color(0xFF22C55E),
  warning: Color(0xFFF59E0B),
  danger: Color(0xFFEF4444),
);

const violetTheme = AppTheme(
  id: 'violet',
  name: 'Violet',
  isDark: false,
  background: Color(0xFFF5F3FF),
  card: Color(0xFFFFFFFF),
  cardAlt: Color(0xFFEDE9FE),
  text: Color(0xFF4C1D95),
  textMuted: Color(0xFF5B21B6),
  textFaint: Color(0xFFC4B5FD),
  border: Color(0xFFDDD6FE),
  accent: Color(0xFF8B5CF6),
  accentSoft: Color(0xFFEDE9FE),
  gradient: [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
  gradientHeader: [Color(0xFF7C3AED), Color(0xFF6D28D9)],
  success: Color(0xFF22C55E),
  warning: Color(0xFFF59E0B),
  danger: Color(0xFFEF4444),
);

const obsidianTheme = AppTheme(
  id: 'obsidian',
  name: 'Obsidian',
  isDark: true,
  background: Color(0xFF0F172A),
  card: Color(0xFF1E293B),
  cardAlt: Color(0xFF0F172A),
  text: Color(0xFFF1F5F9),
  textMuted: Color(0xFF94A3B8),
  textFaint: Color(0xFF475569),
  border: Color(0xFF334155),
  accent: Color(0xFF38BDF8),
  accentSoft: Color(0xFF0C4A6E),
  gradient: [Color(0xFF38BDF8), Color(0xFF0EA5E9)],
  gradientHeader: [Color(0xFF0EA5E9), Color(0xFF0284C7)],
  success: Color(0xFF22C55E),
  warning: Color(0xFFF59E0B),
  danger: Color(0xFFEF4444),
);

const midnightTheme = AppTheme(
  id: 'midnight',
  name: 'Midnight',
  isDark: true,
  background: Color(0xFF09090B),
  card: Color(0xFF18181B),
  cardAlt: Color(0xFF27272A),
  text: Color(0xFFFAFAFA),
  textMuted: Color(0xFFA1A1AA),
  textFaint: Color(0xFF52525B),
  border: Color(0xFF3F3F46),
  accent: Color(0xFFA78BFA),
  accentSoft: Color(0xFF2E1065),
  gradient: [Color(0xFFA78BFA), Color(0xFF8B5CF6)],
  gradientHeader: [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
  success: Color(0xFF22C55E),
  warning: Color(0xFFF59E0B),
  danger: Color(0xFFEF4444),
);

const Map<String, AppTheme> allThemes = {
  'emerald': emeraldTheme,
  'rose': roseTheme,
  'violet': violetTheme,
  'obsidian': obsidianTheme,
  'midnight': midnightTheme,
};
