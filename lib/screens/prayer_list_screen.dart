import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import '../models/prayer.dart';
import '../services/database_helper.dart';
import 'prayer_form_screen.dart';

class PrayerListScreen extends StatefulWidget {
  const PrayerListScreen({super.key});

  @override
  _PrayerListScreenState createState() => _PrayerListScreenState();
}

class _PrayerListScreenState extends State<PrayerListScreen> {
  final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Orações'),
        actions: [
          PopupMenuButton(
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'export',
                child: Text('Exportar Backup'),
              ),
              PopupMenuItem(
                value: 'import',
                child: Text('Importar Backup'),
              ),
              PopupMenuItem(
                value: 'about',
                child: Text('Sobre'),
              ),
            ],
            onSelected: (value) async {
              switch (value) {
                case 'export':
                  _exportBackup();
                  break;
                case 'import':
                  _importBackup();
                  break;
                case 'about':
                  _showAboutDialog();
                  break;
              }
            },
          ),
        ],
      ),
      body: FutureBuilder<List<Prayer>>(
        future: DatabaseHelper.instance.getAllPrayers(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return ListView.builder(
              itemCount: snapshot.data!.length,
              itemBuilder: (context, index) {
                final prayer = snapshot.data![index];
                return Card(
                  margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ExpansionTile(
                    title: Text(
                      prayer.description.length > 50
                          ? '${prayer.description.substring(0, 50)}...'
                          : prayer.description,
                    ),
                    subtitle: Text(
                      'Registrada em: ${dateFormat.format(prayer.createdAt)}',
                    ),
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              prayer.description,
                              style: TextStyle(fontSize: 16),
                            ),
                            if (prayer.answer != null) ...[
                              SizedBox(height: 16),
                              Text(
                                'Resposta:',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                prayer.answer!,
                                style: TextStyle(fontSize: 16),
                              ),
                              Text(
                                'Respondida em: ${dateFormat.format(prayer.answeredAt!)}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                            OverflowBar(
                              children: [
                                IconButton(
                                  icon: Icon(Icons.edit),
                                  onPressed: () => _editPrayer(prayer),
                                ),
                                IconButton(
                                  icon: Icon(Icons.share),
                                  onPressed: () => _sharePrayer(prayer),
                                ),
                                IconButton(
                                  icon: Icon(Icons.delete),
                                  onPressed: () => _deletePrayer(prayer),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          }
          return Center(child: CircularProgressIndicator());
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addPrayer(),
        child: Icon(Icons.add),
      ),
    );
  }

  Future<void> _addPrayer() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PrayerFormScreen(),
      ),
    );

    if (result == true) {
      setState(() {});
    }
  }

  Future<void> _editPrayer(Prayer prayer) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PrayerFormScreen(prayer: prayer),
      ),
    );

    if (result == true) {
      setState(() {});
    }
  }

  Future<void> _deletePrayer(Prayer prayer) async {
    final confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirmar exclusão'),
        content: Text('Deseja realmente excluir esta oração?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await DatabaseHelper.instance.delete(prayer.id!);
      setState(() {});
    }
  }

  void _sharePrayer(Prayer prayer) {
    String shareText = 'Oração: ${prayer.description}\n';
    shareText += 'Registrada em: ${dateFormat.format(prayer.createdAt)}\n';
    if (prayer.answer != null) {
      shareText += '\nResposta: ${prayer.answer}\n';
      shareText += 'Respondida em: ${dateFormat.format(prayer.answeredAt!)}\n';
    }
    Share.share(shareText);
  }

  Future<void> _exportBackup() async {
    try {
      final data = await DatabaseHelper.instance.exportDatabase();
      Share.share(data);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Backup exportado com sucesso!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao exportar backup: $e')),
      );
    }
  }

  Future<void> _importBackup() async {
    // TODO: Implement file picker for importing backup
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Função de importação em desenvolvimento')),
    );
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => AboutDialog(
        applicationName: 'Orações Respondidas',
        applicationVersion: '1.0.0',
        applicationIcon: Icon(Icons.book),
        children: [
          Text(
            'Um aplicativo para registrar suas orações e suas respostas.',
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
