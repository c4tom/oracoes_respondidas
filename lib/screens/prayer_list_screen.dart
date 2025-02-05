import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/prayer.dart';
import '../models/tag.dart';
import '../services/database_helper.dart';
import '../services/settings_service.dart';
import '../utils/tag_colors.dart';
import '../theme/theme_provider.dart';
import '../theme/app_theme.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:path/path.dart' show basename;
import 'dart:io';
import 'prayer_form_screen.dart';
import 'backup_manager_screen.dart';
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
  bool _isLoading = false;
  final TextEditingController _searchController = TextEditingController();
  final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final prayers = await DatabaseHelper.instance.searchPrayers(
        query: _searchQuery.isEmpty ? null : _searchQuery,
        tagIds: _selectedTags.isEmpty ? null : _selectedTags.map((t) => t.id!).toList(),
      );
      final tags = await DatabaseHelper.instance.getAllTags();
      
      if (mounted) {
        setState(() {
          _prayers = prayers;
          _availableTags = tags;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar dados: $e')),
        );
      }
    }
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
            PopupMenuButton<String>(
              onSelected: (value) {
                switch (value) {
                  case 'settings':
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SettingsScreen(),
                      ),
                    );
                    break;
                  case 'about':
                    _showAboutDialog();
                    break;
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'settings',
                  child: ListTile(
                    leading: Icon(Icons.settings),
                    title: Text('Configurações'),
                  ),
                ),
                PopupMenuItem(
                  value: 'about',
                  child: ListTile(
                    leading: Icon(Icons.info),
                    title: Text('Sobre'),
                  ),
                ),
              ],
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
              icon: Icon(Icons.backup),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => BackupManagerScreen(),
                  ),
                );
              },
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
            child: _isLoading
                ? Center(
                    child: CircularProgressIndicator(),
                  )
                : _prayers.isEmpty
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
                                  title: MarkdownBody(
                                    data: prayer.description,
                                    styleSheet: MarkdownStyleSheet(
                                      p: Theme.of(context).textTheme.bodyLarge,
                                    ),
                                    selectable: true,
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
                                        MarkdownBody(
                                          data: prayer.answer!,
                                          styleSheet: MarkdownStyleSheet(
                                            p: Theme.of(context).textTheme.bodyMedium,
                                          ),
                                          selectable: true,
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

  Future<void> _sharePrayer(Prayer prayer) async {
    try {
      final settingsService = SettingsService();
      final dateFormat = DateFormat('dd/MM/yyyy');

      if (prayer.answer != null && prayer.answer!.isNotEmpty) {
        // Compartilhar oração respondida
        String template = await settingsService.getAnsweredPrayerMessage();
        
        // Substituir os campos do template
        final message = template
          .replaceAll('{DATA_REGISTRO}', dateFormat.format(prayer.createdAt))
          .replaceAll('{DESCRICAO_ORACAO}', prayer.description)
          .replaceAll('{RESPOSTA_ORACAO}', prayer.answer!)
          .replaceAll('{DATA_RESPOSTA}', dateFormat.format(prayer.answeredAt!));

        await Share.share(
          message,
          subject: 'Testemunho de Oração Respondida',
        );
      } else {
        // Compartilhar oração não respondida
        final shareMessage = await settingsService.getDefaultShareMessage();
        await Share.share(
          shareMessage,
          subject: 'Pedido de Oração',
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao compartilhar: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
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

  void _showThemeMenu(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Escolha o Tema'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final themeName in AppTheme.themes.keys)
                ListTile(
                  title: Text(themeName),
                  leading: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: AppTheme.themes[themeName]!.colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  onTap: () {
                    themeProvider.setTheme(themeName);
                    Navigator.pop(context);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}
