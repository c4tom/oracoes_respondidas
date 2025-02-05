import 'package:flutter/material.dart';
import '../screens/about_screen.dart';
import '../services/privacy_service.dart';

class PrivacyConsentDialog extends StatelessWidget {
  const PrivacyConsentDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Política de Privacidade'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Para usar este aplicativo, precisamos que você concorde com nossa política de privacidade. Resumidamente:',
            ),
            SizedBox(height: 16),
            _buildBulletPoint(
              '• Seus dados são armazenados apenas localmente no seu dispositivo',
            ),
            _buildBulletPoint(
              '• Não coletamos nem compartilhamos dados com servidores externos',
            ),
            _buildBulletPoint(
              '• Você tem controle total sobre seus dados',
            ),
            _buildBulletPoint(
              '• Backups são salvos apenas localmente',
            ),
            SizedBox(height: 16),
            TextButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => AboutScreen(),
                  ),
                );
              },
              child: Text('Ler Política de Privacidade Completa'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop(false);
          },
          child: Text('Não Aceito'),
        ),
        ElevatedButton(
          onPressed: () async {
            await PrivacyService.setUserConsent(true);
            Navigator.of(context).pop(true);
          },
          child: Text('Aceito'),
        ),
      ],
    );
  }

  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Text(text),
    );
  }
}

Future<bool> showPrivacyConsentDialog(BuildContext context) async {
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (context) => PrivacyConsentDialog(),
  );
  return result ?? false;
}
