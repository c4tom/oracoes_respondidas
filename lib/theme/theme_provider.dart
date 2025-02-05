import 'package:flutter/material.dart';
import 'app_theme.dart';

class ThemeProvider with ChangeNotifier {
  String _currentTheme = AppTheme.themes.keys.first;
  Color _answeredPrayerColor = const Color(0xFFE8F5E9); // Verde claro padrão

  String get currentTheme => _currentTheme;
  ThemeData get theme => AppTheme.themes[_currentTheme]!;
  Color get answeredPrayerColor => _answeredPrayerColor;

  void setTheme(String themeName) {
    if (AppTheme.themes.containsKey(themeName)) {
      _currentTheme = themeName;
      notifyListeners();
    }
  }

  void setAnsweredPrayerColor(Color color) {
    _answeredPrayerColor = color;
    notifyListeners();
  }
}
