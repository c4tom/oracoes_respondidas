import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  static const String _themePreferenceKey = 'app_theme_mode';

  ThemeMode _currentThemeMode = ThemeMode.light;
  bool _isDarkModeEnabled = false;

  ThemeProvider() {
    _loadThemeFromPreferences();
  }

  // Getter for current theme mode
  ThemeMode get themeMode => _currentThemeMode;

  // Getter to check if dark mode is enabled
  bool get isDarkModeEnabled => _isDarkModeEnabled;

  // Light theme configuration
  ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.light(
        primary: Colors.blue.shade600,
        secondary: Colors.blueAccent,
        background: Colors.white,
        surface: Colors.white,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.blue.shade600,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue.shade600,
          foregroundColor: Colors.white,
        ),
      ),
      textTheme: Typography.material2021().black,
      scaffoldBackgroundColor: Colors.white,
    );
  }

  // Dark theme configuration
  ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.dark(
        primary: Colors.blue.shade300,
        secondary: Colors.blueAccent.shade100,
        background: Colors.grey.shade900,
        surface: Colors.grey.shade850,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.grey.shade900,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue.shade300,
          foregroundColor: Colors.white,
        ),
      ),
      textTheme: Typography.material2021().white,
      scaffoldBackgroundColor: Colors.grey.shade900,
    );
  }

  // Toggle theme mode
  void toggleTheme() {
    _isDarkModeEnabled = !_isDarkModeEnabled;
    _currentThemeMode = _isDarkModeEnabled 
      ? ThemeMode.dark 
      : ThemeMode.light;
    _saveThemeToPreferences();
    notifyListeners();
  }

  // Load theme from SharedPreferences
  Future<void> _loadThemeFromPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final isDarkMode = prefs.getBool(_themePreferenceKey) ?? false;
    
    _isDarkModeEnabled = isDarkMode;
    _currentThemeMode = isDarkMode 
      ? ThemeMode.dark 
      : ThemeMode.light;
    
    notifyListeners();
  }

  // Save theme preference to SharedPreferences
  Future<void> _saveThemeToPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_themePreferenceKey, _isDarkModeEnabled);
  }

  // Set theme mode directly
  void setThemeMode(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        _isDarkModeEnabled = false;
        _currentThemeMode = ThemeMode.light;
        break;
      case ThemeMode.dark:
        _isDarkModeEnabled = true;
        _currentThemeMode = ThemeMode.dark;
        break;
      case ThemeMode.system:
        _currentThemeMode = ThemeMode.system;
        break;
    }
    _saveThemeToPreferences();
    notifyListeners();
  }
}
