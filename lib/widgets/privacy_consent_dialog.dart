import 'package:flutter/material.dart';
import '../screens/about_screen.dart';
import '../services/privacy_service.dart';

class PrivacyConsentDialog extends StatelessWidget {
  const PrivacyConsentDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.privacy_tip, color: Theme.of(context).colorScheme.primary),
          SizedBox(width: 8),
          Text('Política de Privacidade'),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bem-vindo ao Orações Respondidas! Valorizamos sua privacidade e estamos comprometidos com a proteção dos seus dados pessoais.',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            SizedBox(height: 16),
            Text(
              'Conformidade com LGPD/GDPR',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Este aplicativo está em conformidade com a Lei Geral de Proteção de Dados (LGPD) e o Regulamento Geral de Proteção de Dados (GDPR).',
            ),
            SizedBox(height: 16),
            Text(
              'Como Tratamos Seus Dados:',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            _buildBulletPoint(
              '• Armazenamento Local: Seus dados são armazenados apenas no seu dispositivo',
            ),
            _buildBulletPoint(
              '• Sem Compartilhamento: Não enviamos dados para servidores externos',
            ),
            _buildBulletPoint(
              '• Controle Total: Você tem controle completo sobre seus dados',
            ),
            _buildBulletPoint(
              '• Backups Seguros: Backups são salvos apenas localmente',
            ),
            SizedBox(height: 16),
            Text(
              'Seus Direitos:',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            _buildBulletPoint(
              '• Acesso aos seus dados pessoais',
            ),
            _buildBulletPoint(
              '• Correção de dados incorretos',
            ),
            _buildBulletPoint(
              '• Exclusão dos seus dados',
            ),
            _buildBulletPoint(
              '• Portabilidade dos dados',
            ),
            _buildBulletPoint(
              '• Revogação do consentimento',
            ),
            SizedBox(height: 16),
            Text(
              'Permissões Necessárias:',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            _buildBulletPoint(
              '• Armazenamento: Para salvar seus dados e backups',
            ),
            _buildBulletPoint(
              '• Internet: Para compartilhamento (opcional)',
            ),
            SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => AboutScreen(),
                  ),
                );
              },
              icon: Icon(Icons.description),
              label: Text('Ler Política de Privacidade Completa'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton.icon(
          onPressed: () {
            Navigator.of(context).pop(false);
          },
          icon: Icon(Icons.close),
          label: Text('Não Aceito'),
          style: TextButton.styleFrom(
            foregroundColor: Theme.of(context).colorScheme.error,
          ),
        ),
        ElevatedButton.icon(
          onPressed: () async {
            await PrivacyService.setUserConsent(true);
            Navigator.of(context).pop(true);
          },
          icon: Icon(Icons.check_circle),
          label: Text('Aceito e Concordo'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Theme.of(context).colorScheme.onPrimary,
          ),
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
