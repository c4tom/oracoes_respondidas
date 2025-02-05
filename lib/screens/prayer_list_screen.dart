import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import '../models/prayer.dart';
import '../models/tag.dart';
import '../services/database_helper.dart';
import '../utils/tag_colors.dart';
import '../theme/theme_provider.dart';
import 'prayer_form_screen.dart';
import 'tag_management_screen.dart';
import 'settings_screen.dart';

class PrayerListScreen extends StatefulWidget {
  const PrayerListScreen({super.key});

  @override
  State<PrayerListScreen> createState() => _PrayerListScreenState();
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
            : Text('Orações Respondidas'),
        actions: [
          if (!_isSearching) ...[
            IconButton(
              icon: Icon(Icons.search),
              onPressed: () {
                setState(() {
                  _isSearching = true;
                });
              },
            ),
            IconButton(
              icon: Icon(Icons.settings),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SettingsScreen(),
                  ),
                );
              },
            ),
            IconButton(
              icon: Icon(Icons.local_offer),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const TagManagementScreen(),
                  ),
                );
              },
            ),
            IconButton(
              icon: Icon(Icons.info),
              onPressed: _showAboutDialog,
            ),
          ] else
            IconButton(
              icon: Icon(Icons.close),
              onPressed: () {
                setState(() {
                  _isSearching = false;
                  _searchController.clear();
                  _searchQuery = '';
                });
                _loadData();
              },
            ),
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
                        color: prayer.answer != null 
                          ? Provider.of<ThemeProvider>(context).answeredPrayerColor
                          : Colors.white,
                        elevation: 2,
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Column(
                          children: [
                            ListTile(
                              contentPadding: EdgeInsets.all(16),
                              title: Text(
                                prayer.description,
                                style: Theme.of(context).textTheme.bodyLarge,
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.calendar_today,
                                        size: 16,
                                        color: Theme.of(context).colorScheme.primary.withOpacity(0.7),
                                      ),
                                      SizedBox(width: 4),
                                      Text(
                                        dateFormat.format(prayer.createdAt),
                                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                          color: Theme.of(context).colorScheme.primary.withOpacity(0.7),
                                        ),
                                      ),
                                      if (prayer.answeredAt != null) ...[
                                        SizedBox(width: 16),
                                        Icon(
                                          Icons.check_circle,
                                          size: 16,
                                          color: Colors.green,
                                        ),
                                        SizedBox(width: 4),
                                        Text(
                                          'Respondida',
                                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                            color: Colors.green,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  if (prayer.tags.isNotEmpty) ...[
                                    SizedBox(height: 8),
                                    Wrap(
                                      spacing: 4,
                                      runSpacing: 4,
                                      children: prayer.tags.map((tag) {
                                        final tagColor = TagColors.getColorForTag(tag.name);
                                        return Chip(
                                          label: Text(
                                            tag.name,
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: tagColor,
                                            ),
                                          ),
                                          backgroundColor: TagColors.getBackgroundColorForTag(tag.name),
                                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                          padding: EdgeInsets.zero,
                                          labelPadding: EdgeInsets.symmetric(horizontal: 8),
                                          side: BorderSide(
                                            color: tagColor.withOpacity(0.2),
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            if (prayer.answer != null)
                              Container(
                                width: double.infinity,
                                padding: EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.primary.withOpacity(0.05),
                                  borderRadius: BorderRadius.only(
                                    bottomLeft: Radius.circular(16),
                                    bottomRight: Radius.circular(16),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Resposta:',
                                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                        color: Theme.of(context).colorScheme.primary,
                                      ),
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      prayer.answer!,
                                      style: Theme.of(context).textTheme.bodyMedium,
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      'Respondida em: ${dateFormat.format(prayer.answeredAt!)}',
                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: Theme.of(context).colorScheme.primary.withOpacity(0.7),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ButtonBar(
                              alignment: MainAxisAlignment.end,
                              children: [
                                IconButton(
                                  icon: Icon(Icons.edit),
                                  tooltip: 'Editar',
                                  onPressed: () => _editPrayer(prayer),
                                ),
                                IconButton(
                                  icon: Icon(Icons.share),
                                  tooltip: 'Compartilhar',
                                  onPressed: () => _sharePrayer(prayer),
                                ),
                                IconButton(
                                  icon: Icon(Icons.delete),
                                  tooltip: 'Excluir',
                                  color: Colors.red,
                                  onPressed: () => _deletePrayer(prayer),
                                ),
                              ],
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
        applicationIcon: Image.asset(
          'assets/images/app_icon.png',
          width: 100,
          height: 100,
        ),
        children: [
          SizedBox(height: 16),
          Text(
            'Um aplicativo para registrar e acompanhar suas orações e suas respostas.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          SizedBox(height: 16),
          Text(
            'Desenvolvido por:',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            'Candido H Tominaga',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          SizedBox(height: 16),
          Text(
            '© ${DateTime.now().year} Todos os direitos reservados',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
