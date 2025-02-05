import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class PrivacyService {
  static const String _consentKey = 'privacy_consent';
  static const String _consentVersionKey = 'privacy_consent_version';
  static const String _userRightsKey = 'user_rights_exercise';
  static const String currentVersion = '1.0.0';

  // Tipos de direitos do usuário
  static const String rightAccess = 'access';
  static const String rightCorrection = 'correction';
  static const String rightDeletion = 'deletion';
  static const String rightPortability = 'portability';
  static const String rightRevocation = 'revocation';

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
      // Registra o consentimento com timestamp
      await _logPrivacyAction('consent_given', 'User provided consent for data processing');
    } else {
      await prefs.remove(_consentVersionKey);
      await prefs.remove(_consentKey);
      await _logPrivacyAction('consent_revoked', 'User revoked consent');
    }
  }

  static Future<void> revokeConsent() async {
    await setUserConsent(false);
    await _logPrivacyAction('consent_revoked', 'User explicitly revoked consent');
  }

  static Future<bool> needsConsentUpdate() async {
    final prefs = await SharedPreferences.getInstance();
    final consentVersion = prefs.getString(_consentVersionKey);
    return consentVersion != null && consentVersion != currentVersion;
  }

  // Exercício de direitos LGPD/GDPR
  static Future<void> exerciseRight(String rightType, String details) async {
    final prefs = await SharedPreferences.getInstance();
    final rights = prefs.getStringList(_userRightsKey) ?? [];
    final request = json.encode({
      'type': rightType,
      'details': details,
      'timestamp': DateTime.now().toIso8601String(),
      'status': 'pending'
    });
    rights.add(request);
    await prefs.setStringList(_userRightsKey, rights);
    await _logPrivacyAction('right_exercised', 'User exercised right: $rightType');
  }

  // Exportar dados do usuário (Portabilidade)
  static Future<File> exportUserData() async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/user_data_export.json');
    
    final data = {
      'timestamp': DateTime.now().toIso8601String(),
      'user_preferences': await _getUserPreferences(),
      'privacy_log': await _getPrivacyLog(),
      'rights_requests': await _getRightsRequests(),
    };

    await file.writeAsString(json.encode(data));
    await _logPrivacyAction('data_exported', 'User data exported');
    
    return file;
  }

  // Excluir dados do usuário (Direito ao esquecimento)
  static Future<void> deleteUserData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    
    // Limpar diretórios de dados
    final appDir = await getApplicationDocumentsDirectory();
    if (await appDir.exists()) {
      await appDir.delete(recursive: true);
    }
    
    await _logPrivacyAction('data_deleted', 'User data deleted');
  }

  // Registrar ações de privacidade
  static Future<void> _logPrivacyAction(String action, String description) async {
    final prefs = await SharedPreferences.getInstance();
    final log = prefs.getStringList('privacy_log') ?? [];
    final entry = json.encode({
      'action': action,
      'description': description,
      'timestamp': DateTime.now().toIso8601String()
    });
    log.add(entry);
    await prefs.setStringList('privacy_log', log);
  }

  // Obter preferências do usuário
  static Future<Map<String, dynamic>> _getUserPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'consent_version': prefs.getString(_consentVersionKey),
      'has_consent': prefs.getBool(_consentKey),
      'theme': prefs.getString('theme_mode'),
      'language': prefs.getString('language'),
    };
  }

  // Obter log de privacidade
  static Future<List<Map<String, dynamic>>> _getPrivacyLog() async {
    final prefs = await SharedPreferences.getInstance();
    final log = prefs.getStringList('privacy_log') ?? [];
    return log.map((entry) => json.decode(entry) as Map<String, dynamic>).toList();
  }

  // Obter solicitações de direitos
  static Future<List<Map<String, dynamic>>> _getRightsRequests() async {
    final prefs = await SharedPreferences.getInstance();
    final rights = prefs.getStringList(_userRightsKey) ?? [];
    return rights.map((request) => json.decode(request) as Map<String, dynamic>).toList();
  }
}
