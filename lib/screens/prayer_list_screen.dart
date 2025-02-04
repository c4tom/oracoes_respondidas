import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import '../models/prayer.dart';
import '../models/tag.dart';
import '../services/database_helper.dart';
import 'prayer_form_screen.dart';
import 'tag_management_screen.dart';

class PrayerListScreen extends StatefulWidget {
  const PrayerListScreen({super.key});

  @override
  _PrayerListScreenState createState() => _PrayerListScreenState();
}

class _PrayerListScreenState extends State<PrayerListScreen> {
  List<Prayer> _prayers = [];
  List<Tag> _availableTags = [];
  List<Tag> _selectedTags = [];
  String _searchQuery = '';
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final prayers = await DatabaseHelper.instance.searchPrayers(
      query: _searchQuery.isEmpty ? null : _searchQuery,
      tagIds: _selectedTags.isEmpty ? null : _selectedTags.map((t) => t.id!).toList(),
    );
    final tags = await DatabaseHelper.instance.getAllTags();
    
    setState(() {
      _prayers = prayers;
      _availableTags = tags;
    });
  }

  void _toggleSearch() {
    setState(() {
      _isSearching = !_isSearching;
      if (!_isSearching) {
        _searchController.clear();
        _searchQuery = '';
        _loadData();
      }
    });
  }

  void _showFilterDialog() async {
    final result = await showDialog<List<Tag>>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Filtrar por Tags'),
        content: Container(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Wrap(
                spacing: 8,
                children: _availableTags.map((tag) {
                  final isSelected = _selectedTags.contains(tag);
                  return FilterChip(
                    label: Text(tag.name),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedTags.add(tag);
                        } else {
                          _selectedTags.remove(tag);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _selectedTags.clear();
              });
              Navigator.pop(context);
              _loadData();
            },
            child: Text('Limpar Filtros'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _loadData();
            },
            child: Text('Aplicar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: _isSearching ? BackButton(onPressed: _toggleSearch) : null,
        title: _isSearching
            ? TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Pesquisar orações...',
                  border: InputBorder.none,
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                  _loadData();
                },
                autofocus: true,
              )
            : Text('Orações'),
        actions: [
          if (!_isSearching) ...[
            IconButton(
              icon: Icon(Icons.search),
              tooltip: 'Pesquisar',
              onPressed: _toggleSearch,
            ),
            IconButton(
              icon: Stack(
                children: [
                  Icon(Icons.filter_list),
                  if (_selectedTags.isNotEmpty)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        padding: EdgeInsets.all(1),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        constraints: BoxConstraints(
                          minWidth: 12,
                          minHeight: 12,
                        ),
                        child: Text(
                          '${_selectedTags.length}',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
              tooltip: 'Filtrar por Tags',
              onPressed: _showFilterDialog,
            ),
            IconButton(
              icon: Icon(Icons.label),
              tooltip: 'Gerenciar Tags',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TagManagementScreen(),
                  ),
                ).then((_) => _loadData());
              },
            ),
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
        ],
      ),
      body: Column(
        children: [
          if (_selectedTags.isNotEmpty)
            Container(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.symmetric(horizontal: 8),
                children: _selectedTags.map((tag) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Chip(
                      label: Text(tag.name),
                      onDeleted: () {
                        setState(() {
                          _selectedTags.remove(tag);
                        });
                        _loadData();
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
          Expanded(
            child: _prayers.isEmpty
                ? Center(
                    child: Text(
                      _searchQuery.isEmpty && _selectedTags.isEmpty
                          ? 'Nenhuma oração cadastrada'
                          : 'Nenhuma oração encontrada',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  )
                : ListView.builder(
                    itemCount: _prayers.length,
                    itemBuilder: (context, index) {
                      final prayer = _prayers[index];
                      return Card(
                        margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: ExpansionTile(
                          title: Text(
                            prayer.description.length > 50
                                ? '${prayer.description.substring(0, 50)}...'
                                : prayer.description,
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Registrada em: ${dateFormat.format(prayer.createdAt)}',
                              ),
                              if (prayer.tags.isNotEmpty)
                                Wrap(
                                  spacing: 4,
                                  children: prayer.tags
                                      .map((tag) => Chip(
                                            label: Text(
                                              tag.name,
                                              style: TextStyle(fontSize: 12),
                                            ),
                                          ))
                                      .toList(),
                                ),
                            ],
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
                  ),
          ),
        ],
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
      _loadData();
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
      _loadData();
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
      _loadData();
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
