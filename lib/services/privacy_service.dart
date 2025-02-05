import 'package:shared_preferences/shared_preferences.dart';

class PrivacyService {
  static const String _consentKey = 'privacy_consent';
  static const String _consentVersionKey = 'privacy_consent_version';
  static const String currentVersion = '1.0.0';

  static Future<bool> hasUserConsent() async {
    final prefs = await SharedPreferences.getInstance();
    final consentVersion = prefs.getString(_consentVersionKey);
    return consentVersion == currentVersion;
  }

  static Future<void> setUserConsent(bool consent) async {
    final prefs = await SharedPreferences.getInstance();
    if (consent) {
      await prefs.setString(_consentVersionKey, currentVersion);
      await prefs.setBool(_consentKey, true);
    } else {
      await prefs.remove(_consentVersionKey);
      await prefs.remove(_consentKey);
    }
  }

  static Future<void> revokeConsent() async {
    await setUserConsent(false);
  }

  static Future<bool> needsConsentUpdate() async {
    final prefs = await SharedPreferences.getInstance();
    final consentVersion = prefs.getString(_consentVersionKey);
    return consentVersion != null && consentVersion != currentVersion;
  }
}
