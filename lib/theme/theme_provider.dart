import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_theme.dart';

class ThemeProvider extends ChangeNotifier {
  static const String _themeKey = 'app_theme';
  static const String _answeredPrayerColorKey = 'answered_prayer_color';
  String _currentTheme = 'Roxo Espiritual';
  Color _answeredPrayerColor = Colors.lightBlue.shade50;

  ThemeProvider() {
    _loadTheme();
    _loadAnsweredPrayerColor();
  }

  String get currentTheme => _currentTheme;
  ThemeData get theme => AppTheme.themes[_currentTheme]!;
  Color get answeredPrayerColor => _answeredPrayerColor;

  Future<void> _loadTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedTheme = prefs.getString(_themeKey);
      if (savedTheme != null && AppTheme.themes.containsKey(savedTheme)) {
        _currentTheme = savedTheme;
        notifyListeners();
      }
    } catch (e) {
      // Ignora erros ao carregar o tema
    }
  }

  Future<void> _loadAnsweredPrayerColor() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final colorValue = prefs.getInt(_answeredPrayerColorKey);
      if (colorValue != null) {
        _answeredPrayerColor = Color(colorValue);
        notifyListeners();
      }
    } catch (e) {
      // Ignora erros ao carregar a cor
    }
  }

  Future<void> setTheme(String themeName) async {
    if (!AppTheme.themes.containsKey(themeName)) return;
    
    _currentTheme = themeName;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_themeKey, themeName);
    } catch (e) {
      // Ignora erros ao salvar o tema
    }
  }

  Future<void> setAnsweredPrayerColor(Color color) async {
    _answeredPrayerColor = color;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_answeredPrayerColorKey, color.value);
    } catch (e) {
      // Ignora erros ao salvar a cor
    }
  }
}
