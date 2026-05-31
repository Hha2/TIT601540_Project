import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/themes.dart';

class ThemeProvider extends ChangeNotifier {
  AppTheme _theme = persistTheme;
  static const _key = 'persist_theme_id';

  AppTheme get theme => _theme;
  String get themeId => _theme.id;
  Map<String, AppTheme> get allThemes => allAppThemes;

  ThemeProvider() {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getString(_key) ?? 'persist';
    _theme = allThemes[id] ?? persistTheme;
    notifyListeners();
  }

  Future<void> setTheme(String id) async {
    _theme = allThemes[id] ?? persistTheme;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, id);
  }
}
