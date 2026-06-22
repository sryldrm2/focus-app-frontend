import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeModeNotifier extends ChangeNotifier {
  static const _prefsKey = 'dark_mode_enabled';

  ThemeMode _themeMode = ThemeMode.light;
  bool _isLoaded = false;

  ThemeMode get themeMode => _themeMode;
  bool get isDarkMode => _themeMode == ThemeMode.dark;
  bool get isLoaded => _isLoaded;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final darkEnabled = prefs.getBool(_prefsKey) ?? false;
    _themeMode = darkEnabled ? ThemeMode.dark : ThemeMode.light;
    _isLoaded = true;
    notifyListeners();
  }

  Future<void> setDarkMode(bool enabled) async {
    final mode = enabled ? ThemeMode.dark : ThemeMode.light;
    if (_themeMode == mode && _isLoaded) return;

    _themeMode = mode;
    _isLoaded = true;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefsKey, enabled);
  }
}
