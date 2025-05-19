import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  // Theme mode keys for shared preferences
  static const String _themePreferenceKey = 'theme_preference';
  static const String _systemThemeKey = 'system';
  static const String _lightThemeKey = 'light';
  static const String _darkThemeKey = 'dark';

  // Default to system theme
  ThemeMode _themeMode = ThemeMode.system;
  
  // Getter for current theme mode
  ThemeMode get themeMode => _themeMode;
  
  // Constructor loads saved preference
  ThemeProvider() {
    _loadThemePreference();
  }

  // Load saved theme preference from shared preferences
  Future<void> _loadThemePreference() async {
    final prefs = await SharedPreferences.getInstance();
    final savedTheme = prefs.getString(_themePreferenceKey) ?? _systemThemeKey;
    
    switch (savedTheme) {
      case _lightThemeKey:
        _themeMode = ThemeMode.light;
        break;
      case _darkThemeKey:
        _themeMode = ThemeMode.dark;
        break;
      default:
        _themeMode = ThemeMode.system;
    }
    
    notifyListeners();
  }

  // Save theme preference
  Future<void> _saveThemePreference(String themeKey) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themePreferenceKey, themeKey);
  }

  // Set theme to system default
  Future<void> setSystemTheme() async {
    _themeMode = ThemeMode.system;
    await _saveThemePreference(_systemThemeKey);
    notifyListeners();
  }

  // Set theme to light mode
  Future<void> setLightTheme() async {
    _themeMode = ThemeMode.light;
    await _saveThemePreference(_lightThemeKey);
    notifyListeners();
  }

  // Set theme to dark mode
  Future<void> setDarkTheme() async {
    _themeMode = ThemeMode.dark;
    await _saveThemePreference(_darkThemeKey);
    notifyListeners();
  }

  // Toggle between light and dark (ignoring system)
  Future<void> toggleTheme() async {
    if (_themeMode == ThemeMode.light) {
      await setDarkTheme();
    } else {
      await setLightTheme();
    }
  }
}
