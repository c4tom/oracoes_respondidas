import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  static const String _defaultShareMessageKey = 'default_share_message';
  static const String _answeredPrayerMessageKey = 'answered_prayer_message';

  Future<String> getDefaultShareMessage() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_defaultShareMessageKey) ??
        'Olá, eu registrei uma oração no meu aplicativo, e é por você que estou orando. Deus te abençoe, um grande abraço.';
  }

  Future<void> setDefaultShareMessage(String message) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_defaultShareMessageKey, message);
  }

  Future<String> getAnsweredPrayerMessage() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_answeredPrayerMessageKey) ?? '''
Olá,

Quero compartilhar com você uma oração que registrei em {DATA_REGISTRO} e que foi atendida! Meu desejo é testemunhar da fé e encorajar você também.

Oração:
{DESCRICAO_ORACAO}
{DATA_REGISTRO}

Resposta:
{RESPOSTA_ORACAO}
{DATA_RESPOSTA}

Que Deus te abençoe!
Grande abraço,''';
  }

  Future<void> setAnsweredPrayerMessage(String message) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_answeredPrayerMessageKey, message);
  }
}
