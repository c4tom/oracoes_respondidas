import 'package:flutter/material.dart';
import '../services/settings_service.dart';

class ShareMessageSettingsScreen extends StatefulWidget {
  const ShareMessageSettingsScreen({super.key});

  @override
  State<ShareMessageSettingsScreen> createState() =>
      _ShareMessageSettingsScreenState();
}

class _ShareMessageSettingsScreenState
    extends State<ShareMessageSettingsScreen> {
  final _defaultMessageController = TextEditingController();
  final _answeredMessageController = TextEditingController();
  final _settingsService = SettingsService();
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  Future<void> _loadMessages() async {
    final defaultMessage = await _settingsService.getDefaultShareMessage();
    final answeredMessage = await _settingsService.getAnsweredPrayerMessage();
    setState(() {
      _defaultMessageController.text = defaultMessage;
      _answeredMessageController.text = answeredMessage;
      _hasChanges = false;
    });
  }

  Future<void> _saveChanges() async {
    await _settingsService
        .setDefaultShareMessage(_defaultMessageController.text);
    await _settingsService
        .setAnsweredPrayerMessage(_answeredMessageController.text);
    setState(() => _hasChanges = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Configurações salvas com sucesso!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Mensagens de Compartilhamento'),
      ),
      body: ListView(
        padding: EdgeInsets.all(16),
        children: [
          _buildDefaultMessageSection(),
          SizedBox(height: 24),
          _buildAnsweredMessageSection(),
          SizedBox(height: 24),
          ElevatedButton(
            onPressed: _hasChanges ? _saveChanges : null,
            style: ElevatedButton.styleFrom(
              minimumSize: Size(double.infinity, 48),
            ),
            child: Text('Salvar Alterações'),
          ),
          SizedBox(height: 26),
        ],
      ),
    );
  }

  Widget _buildDefaultMessageSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Mensagem para Orações em Andamento',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        SizedBox(height: 8),
        Text(
          'Esta mensagem será usada ao compartilhar orações que ainda não foram respondidas.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        SizedBox(height: 16),
        TextField(
          controller: _defaultMessageController,
          maxLines: 5,
          decoration: InputDecoration(
            border: OutlineInputBorder(),
            hintText: 'Digite a mensagem padrão...',
          ),
          onChanged: (_) => setState(() => _hasChanges = true),
        ),
      ],
    );
  }

  Widget _buildAnsweredMessageSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Mensagem para Orações Respondidas',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        SizedBox(height: 8),
        Text(
          'Esta mensagem será usada ao compartilhar orações que foram respondidas.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        SizedBox(height: 8),
        Card(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Campos Disponíveis:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text('{DATA_REGISTRO} - Data em que a oração foi registrada'),
                Text('{DESCRICAO_ORACAO} - O texto da oração'),
                Text('{RESPOSTA_ORACAO} - A resposta recebida'),
                Text('{DATA_RESPOSTA} - Data em que a resposta foi registrada'),
              ],
            ),
          ),
        ),
        SizedBox(height: 16),
        TextField(
          controller: _answeredMessageController,
          maxLines: 10,
          decoration: InputDecoration(
            border: OutlineInputBorder(),
            hintText: 'Digite o template da mensagem...',
          ),
          onChanged: (_) => setState(() => _hasChanges = true),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _defaultMessageController.dispose();
    _answeredMessageController.dispose();
    super.dispose();
  }
}
