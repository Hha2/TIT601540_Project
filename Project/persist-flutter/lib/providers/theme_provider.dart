import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/themes.dart';

class ThemeProvider extends ChangeNotifier {
  AppTheme _theme = coreCalmLightTheme;
  static const _key = 'persist_theme_id';

  AppTheme get theme => _theme;
  String get themeId => _theme.id;
  Map<String, AppTheme> get allThemes => allAppThemes;

  ThemeProvider() {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_key) ?? 'core_light';
    _theme = allAppThemes[saved] ?? coreCalmLightTheme;
    notifyListeners();
  }

  Future<void> setTheme(String id) async {
    _theme = allAppThemes[id] ?? coreCalmLightTheme;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, _theme.id);
  }
}
