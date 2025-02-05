import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as path;
import 'dart:io';
import '../services/database_helper.dart';
import 'package:share_plus/share_plus.dart';
import 'prayer_list_screen.dart';

class BackupManagerScreen extends StatefulWidget {
  const BackupManagerScreen({Key? key}) : super(key: key);

  @override
  _BackupManagerScreenState createState() => _BackupManagerScreenState();
}

class _BackupManagerScreenState extends State<BackupManagerScreen> {
  List<FileSystemEntity> _backups = [];
  bool _isLoading = true;
  bool _isSelectionMode = false;
  final Set<String> _selectedBackups = {};

  @override
  void initState() {
    super.initState();
    _loadBackups();
  }

  Future<void> _loadBackups() async {
    setState(() => _isLoading = true);
    try {
      final backups = await DatabaseHelper.instance.listBackups();
      setState(() {
        _backups = backups;
        _isLoading = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao carregar backups: $e')),
      );
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteBackups(List<String> paths) async {
    try {
      for (var path in paths) {
        final file = File(path);
        if (await file.exists()) {
          await file.delete();
        }
      }
      await _loadBackups();
      setState(() {
        _isSelectionMode = false;
        _selectedBackups.clear();
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Backups excluídos com sucesso!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao excluir backups: $e')),
        );
      }
    }
  }

  Future<void> _confirmDelete() async {
    if (_selectedBackups.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirmar Exclusão'),
        content: Text(
          'Tem certeza que deseja excluir ${_selectedBackups.length} backup(s)?\n'
          'Esta ação não pode ser desfeita.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              'Excluir',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _deleteBackups(_selectedBackups.toList());
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  Future<void> _exportBackup() async {
    try {
      // Mostrar diálogo para escolher destino
      final action = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Exportar Backup'),
          content: Text('Onde você deseja salvar o backup?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop('local'),
              child: Text('Pasta Local'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop('share'),
              child: Text('Compartilhar'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop('custom'),
              child: Text('Escolher Pasta'),
            ),
          ],
        ),
      );

      if (action == null) return;

      late final File backupFile;
      if (action == 'custom') {
        // TODO: Implementar seleção de pasta personalizada
        // Por enquanto, usa pasta local
        backupFile = await DatabaseHelper.instance.exportDatabaseToFile();
      } else {
        backupFile = await DatabaseHelper.instance.exportDatabaseToFile();
      }

      if (action == 'share') {
        await Share.shareFiles(
          [backupFile.path],
          text: 'Backup Orações Respondidas',
        );
      }

      await _loadBackups(); // Recarrega a lista

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Backup exportado com sucesso!'),
          action: action == 'local' ? SnackBarAction(
            label: 'Abrir Pasta',
            onPressed: () async {
              final backupDir = await DatabaseHelper.instance.getBackupDirectory();
              // TODO: Abrir pasta no explorador de arquivos
            },
          ) : null,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao exportar backup: $e')),
      );
    }
  }

  Future<void> _importBackup() async {
    try {
      // Mostrar diálogo para escolher origem
      final action = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Importar Backup'),
          content: Text('De onde você deseja importar o backup?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop('file'),
              child: Text('Escolher Arquivo'),
            ),
          ],
        ),
      );

      if (action == null) return;

      // TODO: Implementar seleção de arquivo
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Seleção de arquivo em desenvolvimento')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao importar backup: $e')),
      );
    }
  }

  Future<void> _restoreBackup(String backupPath) async {
    try {
      // Confirmar restauração
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Restaurar Backup'),
          content: Text(
            'Esta ação irá substituir todas as orações existentes pelos dados do backup.\n\n'
            'Tem certeza que deseja restaurar este backup?'
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text('Restaurar'),
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).primaryColor,
              ),
            ),
          ],
        ),
      );

      if (confirm != true) return;

      // Restaurar backup
      await DatabaseHelper.instance.importDatabaseFromFile(backupPath);

      // Notificar sucesso
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Backup restaurado com sucesso!')),
      );

      // Voltar para a tela inicial e forçar reconstrução
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const PrayerListScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao restaurar backup: $e')),
        );
      }
    }
  }

  Future<void> _showBackupReport(String backupPath) async {
    try {
      final stats = await DatabaseHelper.instance.analyzeBackupFile(backupPath);
      final backupDate = DateTime.parse(stats.timestamp);

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Relatório do Backup'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ListTile(
                leading: Icon(Icons.calendar_today),
                title: Text('Data do Backup'),
                subtitle: Text(DateFormat('dd/MM/yyyy HH:mm').format(backupDate)),
              ),
              Divider(),
              ListTile(
                leading: Icon(Icons.format_list_numbered),
                title: Text('Total de Orações'),
                subtitle: Text('${stats.totalPrayers}'),
              ),
              ListTile(
                leading: Icon(Icons.check_circle),
                title: Text('Orações Respondidas'),
                subtitle: Text('${stats.answeredPrayers} (${((stats.answeredPrayers / stats.totalPrayers) * 100).toStringAsFixed(1)}%)'),
              ),
              ListTile(
                leading: Icon(Icons.label),
                title: Text('Total de Tags'),
                subtitle: Text('${stats.totalTags}'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Fechar'),
            ),
          ],
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao gerar relatório: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Gerenciar Backups'),
        actions: [
          if (_backups.isNotEmpty) ...[
            if (_isSelectionMode) ...[
              TextButton(
                onPressed: () {
                  setState(() {
                    if (_selectedBackups.length == _backups.length) {
                      _selectedBackups.clear();
                    } else {
                      _selectedBackups.addAll(_backups.map((b) => b.path));
                    }
                  });
                },
                child: Text(
                  _selectedBackups.length == _backups.length
                      ? 'Desmarcar Todos'
                      : 'Selecionar Todos',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ] else
              IconButton(
                icon: Icon(Icons.select_all),
                tooltip: 'Modo Seleção',
                onPressed: () {
                  setState(() {
                    _isSelectionMode = true;
                  });
                },
              ),
          ],
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'export':
                  _exportBackup();
                  break;
                case 'import':
                  _importBackup();
                  break;
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'export',
                child: ListTile(
                  leading: Icon(Icons.upload),
                  title: Text('Exportar Backup'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              PopupMenuItem(
                value: 'import',
                child: ListTile(
                  leading: Icon(Icons.download),
                  title: Text('Importar Backup'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _backups.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Nenhum backup encontrado',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      SizedBox(height: 16),
                      ElevatedButton.icon(
                        icon: Icon(Icons.add),
                        label: Text('Criar Backup'),
                        onPressed: _exportBackup,
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadBackups,
                  child: ListView.separated(
                    padding: EdgeInsets.all(8),
                    itemCount: _backups.length,
                    separatorBuilder: (context, index) => Divider(height: 1),
                    itemBuilder: (context, index) {
                      final backup = _backups[index];
                      final filename = path.basename(backup.path);
                      final date = backup.statSync().modified;
                      final size = backup.statSync().size;
                      final isSelected = _selectedBackups.contains(backup.path);

                      return ListTile(
                        leading: Icon(
                          Icons.backup,
                          color: Theme.of(context).primaryColor,
                        ),
                        title: Text(filename),
                        subtitle: Text(
                          '${DateFormat('dd/MM/yyyy HH:mm').format(date)}\n'
                          'Tamanho: ${_formatFileSize(size)}',
                        ),
                        isThreeLine: true,
                        trailing: _isSelectionMode
                            ? Checkbox(
                                value: isSelected,
                                onChanged: (checked) {
                                  setState(() {
                                    if (checked == true) {
                                      _selectedBackups.add(backup.path);
                                    } else {
                                      _selectedBackups.remove(backup.path);
                                    }
                                  });
                                },
                              )
                            : Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: Icon(Icons.analytics),
                                    tooltip: 'Ver Relatório',
                                    onPressed: () => _showBackupReport(backup.path),
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.restore),
                                    tooltip: 'Restaurar',
                                    onPressed: () => _restoreBackup(backup.path),
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.delete_outline),
                                    tooltip: 'Excluir',
                                    onPressed: () => _deleteBackups([backup.path]),
                                  ),
                                ],
                              ),
                        onTap: _isSelectionMode
                            ? () {
                                setState(() {
                                  if (isSelected) {
                                    _selectedBackups.remove(backup.path);
                                  } else {
                                    _selectedBackups.add(backup.path);
                                  }
                                });
                              }
                            : null,
                        onLongPress: () {
                          if (!_isSelectionMode) {
                            setState(() {
                              _isSelectionMode = true;
                              _selectedBackups.add(backup.path);
                            });
                          }
                        },
                      );
                    },
                  ),
                ),
      floatingActionButton: _isSelectionMode && _selectedBackups.isNotEmpty
          ? FloatingActionButton(
              onPressed: _confirmDelete,
              backgroundColor: Colors.red,
              child: Icon(Icons.delete),
            )
          : FloatingActionButton(
              onPressed: _exportBackup,
              child: Icon(Icons.backup),
              tooltip: 'Criar Backup',
            ),
    );
  }
}
