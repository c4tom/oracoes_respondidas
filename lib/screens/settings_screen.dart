import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/theme_provider.dart';
import '../theme/app_theme.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'share_message_settings_screen.dart';
import 'about_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Configurações'),
      ),
      body: ListView(
        padding: EdgeInsets.all(16),
        children: [
          _buildThemeSection(context, themeProvider),
          const Divider(height: 32),
          _buildAnsweredPrayerColorSection(context, themeProvider),
          ListTile(
            leading: Icon(Icons.share),
            title: Text('Mensagem de Compartilhamento'),
            subtitle: Text('Configurar mensagem padrão para orações'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ShareMessageSettingsScreen(),
                ),
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('Sobre o Aplicativo'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AboutScreen(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildThemeSection(BuildContext context, ThemeProvider themeProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tema',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        SizedBox(height: 8),
        Card(
          child: Column(
            children: [
              for (final themeName in AppTheme.themes.keys)
                RadioListTile<String>(
                  title: Text(themeName),
                  value: themeName,
                  groupValue: themeProvider.currentTheme,
                  onChanged: (value) {
                    if (value != null) {
                      themeProvider.setTheme(value);
                    }
                  },
                  secondary: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: AppTheme.themes[themeName]!.colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAnsweredPrayerColorSection(BuildContext context, ThemeProvider themeProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Cor de Orações Respondidas',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        SizedBox(height: 8),
        Card(
          child: ListTile(
            title: Text('Selecionar Cor'),
            trailing: _ColorPreview(color: themeProvider.answeredPrayerColor),
            onTap: () => _showColorPicker(context, themeProvider),
          ),
        ),
      ],
    );
  }

  void _showColorPicker(BuildContext context, ThemeProvider themeProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Escolha a Cor'),
        content: SingleChildScrollView(
          child: ColorPicker(
            pickerColor: themeProvider.answeredPrayerColor,
            onColorChanged: (color) {
              themeProvider.setAnsweredPrayerColor(color);
            },
            labelTypes: const [],
            pickerAreaHeightPercent: 0.8,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }
}

class _ColorPreview extends StatelessWidget {
  final Color color;

  const _ColorPreview({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.grey.shade300,
          width: 1,
        ),
      ),
    );
  }
}
