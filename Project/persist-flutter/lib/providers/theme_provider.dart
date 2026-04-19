import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/themes.dart';

class ThemeProvider extends ChangeNotifier {
  AppTheme _theme = emeraldTheme;
  static const _key = 'persist_theme_id';

  AppTheme get theme => _theme;
  String get themeId => _theme.id;
  Map<String, AppTheme> get allThemes => const {
        'emerald': emeraldTheme,
        'rose': roseTheme,
        'violet': violetTheme,
        'obsidian': obsidianTheme,
        'midnight': midnightTheme,
      };

  ThemeProvider() {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getString(_key) ?? 'emerald';
    _theme = allThemes[id] ?? emeraldTheme;
    notifyListeners();
  }

  Future<void> setTheme(String id) async {
    _theme = allThemes[id] ?? emeraldTheme;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, id);
  }
}
