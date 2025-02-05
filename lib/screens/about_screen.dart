import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:url_launcher/url_launcher.dart' as url_launcher;

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Sobre'),
      ),
      body: ListView(
        padding: EdgeInsets.all(16),
        children: [
          // Logo e Título
          Center(
            child: Column(
              children: [
                Image.asset(
                  'assets/images/app_icon.png',
                  width: 100,
                  height: 100,
                ),
                SizedBox(height: 16),
                Text(
                  'Orações Respondidas',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Versão 1.0.0',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 32),

          // Descrição do App
          Text(
            'Descrição',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'O Orações Respondidas é um aplicativo desenvolvido para ajudar você a registrar e acompanhar suas orações. Com ele, você pode:',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          SizedBox(height: 8),
          _buildFeatureList(context),
          SizedBox(height: 32),

          // Política de Privacidade
          Text(
            'Política de Privacidade',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          _buildPrivacyPolicy(context),
          SizedBox(height: 32),

          // Desenvolvedor
          _buildDeveloperInfo(context),
          SizedBox(height: 32),

          // Botões de Ação
          Center(
            child: _buildActionButtons(context),
          ),
          SizedBox(height: 32),

          // Copyright
          Center(
            child: Text(
              '© ${DateTime.now().year} Todos os direitos reservados',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureList(BuildContext context) {
    final features = [
      'Registrar orações com descrições detalhadas',
      'Organizar orações por tags personalizadas',
      'Marcar orações como respondidas',
      'Compartilhar orações e testemunhos',
      'Fazer backup dos seus dados',
      'Personalizar a aparência do app',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: features.map((feature) => Padding(
        padding: EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.check_circle, 
              color: Theme.of(context).colorScheme.primary,
              size: 20,
            ),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                feature,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ],
        ),
      )).toList(),
    );
  }

  Widget _buildPrivacyPolicy(BuildContext context) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Política de Privacidade e Proteção de Dados',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'O Orações Respondidas está em conformidade com a LGPD (Lei Geral de Proteção de Dados) '
              'e GDPR (General Data Protection Regulation), garantindo seus direitos fundamentais '
              'de liberdade, privacidade e proteção de dados pessoais.',
            ),
            SizedBox(height: 16),
            Text(
              'Dados Coletados',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              '• Orações e descrições\n'
              '• Tags e categorias\n'
              '• Datas de registro\n'
              '• Preferências do aplicativo',
            ),
            SizedBox(height: 16),
            Text(
              'Armazenamento e Segurança',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Seus dados são armazenados localmente no seu dispositivo e protegidos. '
              'Nenhuma informação é compartilhada com servidores externos sem seu consentimento explícito.',
            ),
            SizedBox(height: 16),
            Text(
              'Permissões Necessárias',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              '• Armazenamento: para backup e gestão dos seus dados\n'
              '• Internet: para compartilhamento (opcional)',
            ),
            SizedBox(height: 16),
            Text(
              'Seus Direitos (LGPD/GDPR)',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              '• Acesso aos seus dados pessoais\n'
              '• Correção de dados incompletos ou incorretos\n'
              '• Exportação dos seus dados (portabilidade)\n'
              '• Exclusão dos seus dados (direito ao esquecimento)\n'
              '• Revogação do consentimento\n'
              '• Informações sobre compartilhamento de dados',
            ),
            SizedBox(height: 16),
            Text(
              'Contato DPO',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Para exercer seus direitos ou esclarecer dúvidas sobre a proteção dos seus dados, entre em contato:',
            ),
            SizedBox(height: 8),
            Text('E-mail: privacy@oracoesrespondidas.com'),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _showFullPrivacyPolicy(context),
              child: Text('Ver Política de Privacidade Completa'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeveloperInfo(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          'Desenvolvedor',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 8),
        Text(
          'Candido H Tominaga',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'GitHub: ',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            GestureDetector(
              onTap: () async {
                final contactUri = Uri.parse('https://github.com/c4tom');

                try {
                  if (await url_launcher.canLaunchUrl(contactUri)) {
                    await url_launcher.launchUrl(
                      contactUri,
                      mode: url_launcher.LaunchMode.externalApplication,
                    );
                  } else {
                    _showErrorSnackBar(context, 'Não foi possível abrir o link do GitHub.');
                  }
                } catch (e) {
                  _showErrorSnackBar(context, 'Erro ao abrir o link do GitHub: $e');
                }
              },
              child: Text(
                'github.com/c4tom',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.blue,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return ElevatedButton.icon(
      icon: Icon(Icons.policy),
      label: Text('Política de Privacidade Completa'),
      onPressed: () {
        _showFullPrivacyPolicy(context);
      },
    );
  }

  void _showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }

  void _showFullPrivacyPolicy(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Política de Privacidade Completa'),
        content: SingleChildScrollView(
          child: MarkdownBody(
            data: '''
# Política de Privacidade - Orações Respondidas

## 1. Introdução

O aplicativo Orações Respondidas respeita e protege a privacidade dos seus usuários. Esta política descreve como coletamos, usamos e protegemos suas informações.

## 2. Dados Armazenados

### 2.1 Dados Locais
- Todas as orações e informações pessoais são armazenadas **exclusivamente no seu dispositivo**
- Nenhum dado é enviado para servidores externos sem seu consentimento explícito

### 2.2 Tipos de Dados
- Descrição das orações
- Tags e categorias
- Status das orações (respondidas/não respondidas)
- Configurações do aplicativo

## 3. Permissões

### 3.1 Permissões Necessárias
- **Armazenamento Interno**: Para salvar e fazer backup dos seus dados
- **Internet (Opcional)**: Para funcionalidades de compartilhamento

## 4. Seus Direitos

### 4.1 Controle de Dados
- Visualizar todos os seus dados
- Exportar dados em formato legível
- Excluir todos os dados do aplicativo
- Revogar permissões a qualquer momento

## 5. Segurança

### 5.1 Proteção de Dados
- Dados armazenados localmente com criptografia
- Nenhum acesso remoto sem autorização
- Backup opcional com proteção adicional

## 6. Atualizações da Política

Esta política pode ser atualizada. Recomendamos revisar periodicamente.

**Última Atualização**: ${DateTime.now().toIso8601String().split('T')[0]}
''',
            styleSheet: MarkdownStyleSheet(
              h1: Theme.of(context).textTheme.headlineSmall,
              h2: Theme.of(context).textTheme.titleLarge,
              p: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Fechar'),
          ),
        ],
      ),
    );
  }

  String? _encodeQueryParameters(Map<String, String> params) {
    return params.entries
        .map((MapEntry<String, String> e) =>
            '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
        .join('&');
  }
}
