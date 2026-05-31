import 'package:flutter/material.dart';
import 'persist_brand.dart';

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
    final base = isDark ? ThemeData.dark() : ThemeData.light();
    return base.copyWith(
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
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: accent,
        selectionColor: accentSoft,
        selectionHandleColor: accent,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? accent : Colors.grey,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? accentSoft : Colors.grey.withOpacity(.28),
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

Color _muted(Color color, bool dark) => Color.alphaBlend(
      dark ? Colors.white.withOpacity(.62) : Colors.black.withOpacity(.56),
      color,
    );

Color _faint(Color color, bool dark) => Color.alphaBlend(
      dark ? Colors.white.withOpacity(.34) : Colors.black.withOpacity(.30),
      color,
    );

Color _border(Color surface, bool dark) => dark
    ? Color.alphaBlend(Colors.white.withOpacity(.16), surface)
    : Color.alphaBlend(Colors.black.withOpacity(.08), surface);

Color _soft(Color accent, Color background, bool dark) => Color.alphaBlend(
      accent.withOpacity(dark ? .18 : .14),
      background,
    );

const coreCalmLightTheme = AppTheme(
  id: 'core_light',
  name: 'Core Calm Light',
  isDark: false,
  background: PersistBrand.coreLightBackground,
  card: Colors.white,
  cardAlt: PersistBrand.coreLightSurface,
  text: PersistBrand.coreLightText,
  textMuted: Color(0xFF60737B),
  textFaint: Color(0xFF9BAAAD),
  border: Color(0xFFD4E8E6),
  accent: PersistBrand.coreLightPrimary,
  accentSoft: PersistBrand.coreLightSurface,
  gradient: [PersistBrand.coreLightPrimary, PersistBrand.coreLightSecondary],
  gradientHeader: [PersistBrand.coreLightSecondary, PersistBrand.coreLightPrimary],
  success: Color(0xFF36A878),
  warning: Color(0xFFE9A84D),
  danger: PersistBrand.coreLightAccent,
);

const coreCalmDarkTheme = AppTheme(
  id: 'core_dark',
  name: 'Core Calm Dark',
  isDark: true,
  background: PersistBrand.coreDarkBackground,
  card: PersistBrand.coreDarkSurface,
  cardAlt: Color(0xFF1D3B46),
  text: PersistBrand.coreDarkText,
  textMuted: Color(0xFFAACBD0),
  textFaint: Color(0xFF6D8D96),
  border: Color(0xFF294C57),
  accent: PersistBrand.coreDarkPrimary,
  accentSoft: Color(0xFF14353D),
  gradient: [PersistBrand.coreDarkPrimary, PersistBrand.coreDarkSecondary],
  gradientHeader: [PersistBrand.coreDarkBackground, PersistBrand.coreDarkSurface],
  success: Color(0xFF64D6A6),
  warning: Color(0xFFFFC56D),
  danger: PersistBrand.coreDarkAccent,
);

const lavenderFocusTheme = AppTheme(
  id: 'lavender_focus',
  name: 'Lavender Focus',
  isDark: false,
  background: PersistBrand.lavenderBackground,
  card: Colors.white,
  cardAlt: PersistBrand.lavenderSurface,
  text: PersistBrand.lavenderText,
  textMuted: Color(0xFF6E6E91),
  textFaint: Color(0xFFA7A5C3),
  border: Color(0xFFE0DDF3),
  accent: PersistBrand.lavenderPrimary,
  accentSoft: PersistBrand.lavenderSurface,
  gradient: [PersistBrand.lavenderPrimary, PersistBrand.lavenderSecondary],
  gradientHeader: [PersistBrand.lavenderSecondary, PersistBrand.lavenderPrimary],
  success: Color(0xFF62B990),
  warning: Color(0xFFE8A84B),
  danger: PersistBrand.lavenderAccent,
);

const mistySkyTheme = AppTheme(
  id: 'misty_sky',
  name: 'Misty Sky',
  isDark: false,
  background: PersistBrand.skyBackground,
  card: Colors.white,
  cardAlt: PersistBrand.skySurface,
  text: PersistBrand.skyText,
  textMuted: Color(0xFF607A91),
  textFaint: Color(0xFFA2B5C4),
  border: Color(0xFFD8E7F2),
  accent: PersistBrand.skyPrimary,
  accentSoft: PersistBrand.skySurface,
  gradient: [PersistBrand.skyPrimary, PersistBrand.skySecondary],
  gradientHeader: [PersistBrand.skySecondary, PersistBrand.skyPrimary],
  success: Color(0xFF4CA78F),
  warning: Color(0xFFE8A84B),
  danger: PersistBrand.skyAccent,
);

const royalVioletNightTheme = AppTheme(
  id: 'royal_violet',
  name: 'Royal Violet Night',
  isDark: true,
  background: PersistBrand.violetBackground,
  card: PersistBrand.violetSurface,
  cardAlt: Color(0xFF2C1B4C),
  text: PersistBrand.violetText,
  textMuted: Color(0xFFC8BDE5),
  textFaint: Color(0xFF82729E),
  border: Color(0xFF3D2867),
  accent: PersistBrand.violetPrimary,
  accentSoft: Color(0xFF281649),
  gradient: [PersistBrand.violetPrimary, PersistBrand.violetSecondary],
  gradientHeader: [PersistBrand.violetBackground, PersistBrand.violetSurface],
  success: Color(0xFF7FE0CE),
  warning: Color(0xFFFFC56D),
  danger: PersistBrand.violetAccent,
);

const berryEclipseTheme = AppTheme(
  id: 'berry_eclipse',
  name: 'Berry Eclipse',
  isDark: true,
  background: PersistBrand.berryBackground,
  card: PersistBrand.berrySurface,
  cardAlt: Color(0xFF351634),
  text: PersistBrand.berryText,
  textMuted: Color(0xFFD8B7C7),
  textFaint: Color(0xFF906073),
  border: Color(0xFF4A1F43),
  accent: PersistBrand.berryPrimary,
  accentSoft: Color(0xFF351426),
  gradient: [PersistBrand.berryPrimary, PersistBrand.berrySecondary],
  gradientHeader: [PersistBrand.berryBackground, PersistBrand.berrySurface],
  success: PersistBrand.berryAccent,
  warning: Color(0xFFFFC56D),
  danger: Color(0xFFFF8FA3),
);

// Default theme used by old code names.
const persistTheme = coreCalmLightTheme;
const calmNavyTheme = coreCalmDarkTheme;
const emeraldTheme = coreCalmLightTheme;
const roseTheme = mistySkyTheme;
const violetTheme = lavenderFocusTheme;
const obsidianTheme = coreCalmDarkTheme;
const midnightTheme = royalVioletNightTheme;

const Map<String, AppTheme> allAppThemes = {
  'core_light': coreCalmLightTheme,
  'core_dark': coreCalmDarkTheme,
  'lavender_focus': lavenderFocusTheme,
  'misty_sky': mistySkyTheme,
  'royal_violet': royalVioletNightTheme,
  'berry_eclipse': berryEclipseTheme,

  // Backward-compatible IDs so older screens/settings do not crash.
  'persist': coreCalmLightTheme,
  'calm_navy': coreCalmDarkTheme,
  'emerald': coreCalmLightTheme,
  'rose': mistySkyTheme,
  'violet': lavenderFocusTheme,
  'obsidian': coreCalmDarkTheme,
  'midnight': royalVioletNightTheme,
};

const Map<String, AppTheme> allThemes = allAppThemes;
