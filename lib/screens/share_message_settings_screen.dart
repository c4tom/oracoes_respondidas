import 'package:flutter/material.dart';
import '../services/settings_service.dart';

class ShareMessageSettingsScreen extends StatefulWidget {
  const ShareMessageSettingsScreen({Key? key}) : super(key: key);

  @override
  _ShareMessageSettingsScreenState createState() => _ShareMessageSettingsScreenState();
}

class _ShareMessageSettingsScreenState extends State<ShareMessageSettingsScreen> {
  final _settingsService = SettingsService();
  late TextEditingController _messageController;

  @override
  void initState() {
    super.initState();
    _loadCurrentMessage();
  }

  void _loadCurrentMessage() async {
    final currentMessage = await _settingsService.getDefaultShareMessage();
    setState(() {
      _messageController = TextEditingController(text: currentMessage);
    });
  }

  void _saveMessage() async {
    final message = _messageController.text.trim();
    if (message.isNotEmpty) {
      await _settingsService.setDefaultShareMessage(message);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Mensagem de compartilhamento atualizada')),
      );
      Navigator.of(context).pop();
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Mensagem de Compartilhamento'),
        actions: [
          IconButton(
            icon: Icon(Icons.save),
            onPressed: _saveMessage,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Mensagem Padrão para Compartilhamento',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            SizedBox(height: 8),
            Text(
              'Esta mensagem será usada ao compartilhar orações sem resposta.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            SizedBox(height: 16),
            TextField(
              controller: _messageController,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Mensagem de Compartilhamento',
                hintText: 'Digite sua mensagem padrão',
              ),
              maxLines: 3,
              maxLength: 280,
            ),
          ],
        ),
      ),
    );
  }
}
