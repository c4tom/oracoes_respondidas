import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  static const _defaultShareMessageKey = 'default_share_message';

  Future<String> getDefaultShareMessage() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_defaultShareMessageKey) ??
        'Olá, eu registrei uma oração no meu aplicativo, e é por você que estou orando. Deus te abençoe, um grande abraço.';
  }

  Future<void> setDefaultShareMessage(String message) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_defaultShareMessageKey, message);
  }
}
