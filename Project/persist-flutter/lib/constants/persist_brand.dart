import 'package:flutter/material.dart';

/// Single source of truth for Persist brand assets and palette constants.
/// Do not reference random logo paths anywhere else.
class PersistAssets {
  static const String logoInfo = 'assets/LOGO-&-LOADING/LOGO-INFO.png';
  static const String icon = 'assets/LOGO-&-LOADING/PERSIST-ICON.png';
  static const String logoLight = 'assets/LOGO-&-LOADING/PERSIST-LOGO-(LIGHT).png';
  static const String logoDark = 'assets/LOGO-&-LOADING/PERSIST-LOGO-(DARK).png';
  static const String loadingLight = 'assets/LOGO-&-LOADING/PERSIST-LOADING-(LIGHT).png';
  static const String loadingDark = 'assets/LOGO-&-LOADING/PERSIST-LOADING-(DARK).png';
  static const String banner = 'assets/LOGO-&-LOADING/BANNER-PERSIST.png';

  static const String corePalettes = 'assets/COLOR-PALLATE/CORE-PALETTES.png';
  static const String lightPalettes = 'assets/COLOR-PALLATE/LIGHT-PALLETES.png';
  static const String darkPalettes = 'assets/COLOR-PALLATE/DARK-PALETTES.png';
  static const String onboardingReference = 'assets/UI-PAGES/ONBOARDING-SCREENS.png';
  static const String uiReference = 'assets/UI-PAGES/UI-SCREENS.png';
}

class PersistBrand {
  static const String appName = 'Persist';
  static const String tagline = 'Small steps. Lasting change.';
  static const String promise = 'Build steady routines without burnout.';

  // Exact finalized Core Calm Light palette.
  static const Color coreLightPrimary = Color(0xFF2FA8A0);
  static const Color coreLightSecondary = Color(0xFF1F4E63);
  static const Color coreLightAccent = Color(0xFFFF8A80);
  static const Color coreLightSurface = Color(0xFFE2F3F1);
  static const Color coreLightBackground = Color(0xFFF7FBFC);
  static const Color coreLightText = Color(0xFF16303D);

  // Exact finalized Core Calm Dark palette.
  static const Color coreDarkPrimary = Color(0xFF46C5BB);
  static const Color coreDarkSecondary = Color(0xFF7FD6E8);
  static const Color coreDarkAccent = Color(0xFFFF9D94);
  static const Color coreDarkSurface = Color(0xFF17303A);
  static const Color coreDarkBackground = Color(0xFF081822);
  static const Color coreDarkText = Color(0xFFEAF7FA);

  // Exact finalized Lavender Focus palette.
  static const Color lavenderPrimary = Color(0xFF8B88D8);
  static const Color lavenderSecondary = Color(0xFF5C5A8F);
  static const Color lavenderAccent = Color(0xFFFFB3C7);
  static const Color lavenderSurface = Color(0xFFEDEBFA);
  static const Color lavenderBackground = Color(0xFFF8F6FF);
  static const Color lavenderText = Color(0xFF2E2F52);

  // Exact finalized Misty Sky palette.
  static const Color skyPrimary = Color(0xFF6EA8D9);
  static const Color skySecondary = Color(0xFF365E87);
  static const Color skyAccent = Color(0xFFFFB29B);
  static const Color skySurface = Color(0xFFE7F1FA);
  static const Color skyBackground = Color(0xFFF7FBFF);
  static const Color skyText = Color(0xFF20384E);

  // Exact finalized Royal Violet Night palette.
  static const Color violetPrimary = Color(0xFF8F42F5);
  static const Color violetSecondary = Color(0xFF4F2A8C);
  static const Color violetAccent = Color(0xFFFF9AC8);
  static const Color violetSurface = Color(0xFF1F1438);
  static const Color violetBackground = Color(0xFF0B0717);
  static const Color violetText = Color(0xFFEEE7FF);

  // Exact finalized Berry Eclipse palette.
  static const Color berryPrimary = Color(0xFFC94B7A);
  static const Color berrySecondary = Color(0xFF5C2146);
  static const Color berryAccent = Color(0xFF7FE0CE);
  static const Color berrySurface = Color(0xFF271229);
  static const Color berryBackground = Color(0xFF120912);
  static const Color berryText = Color(0xFFF8E8F1);
}
