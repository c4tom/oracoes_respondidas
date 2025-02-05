import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  static const _defaultShareMessageKey = 'default_share_message';

  Future<String> getDefaultShareMessage() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_defaultShareMessageKey) ??
        'Eu registrei essa oração, e estou orando por você. Deus te abençoe';
  }

  Future<void> setDefaultShareMessage(String message) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_defaultShareMessageKey, message);
  }
}
