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
  final _searchController = TextEditingController();
  List<Prayer> _prayers = [];
  List<Prayer> _filteredPrayers = [];
  List<Tag> _selectedTags = [];
  bool _isSearching = false;
  bool _isLoading = false;
  DateTime? _selectedDate;

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
      final prayers = await DatabaseHelper.instance.searchPrayers();
      final tags = await DatabaseHelper.instance.getAllTags();
      
      if (mounted) {
        setState(() {
          _prayers = prayers;
          _filteredPrayers = prayers;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar orações: $e')),
        );
      }
    }
  }

  void _filterPrayers(String query) {
    setState(() {
      _filteredPrayers = _prayers.where((prayer) {
        // Filtro por texto
        bool matchesQuery = query.isEmpty ||
            prayer.description.toLowerCase().contains(query.toLowerCase());
        
        // Filtro por tags
        bool matchesTags = _selectedTags.isEmpty ||
            prayer.tags.any((tag) => _selectedTags.contains(tag));
        
        // Filtro por data
        bool matchesDate = _selectedDate == null ||
            (prayer.createdAt.year == _selectedDate!.year &&
             prayer.createdAt.month == _selectedDate!.month);
        
        return matchesQuery && matchesTags && matchesDate;
      }).toList();
    });
  }

  void _toggleSearch() {
    setState(() {
      _isSearching = !_isSearching;
      if (!_isSearching) {
        _searchController.clear();
        _loadData();
      }
    });
  }

  Future<void> _showDateFilterDialog() async {
    final currentDate = DateTime.now();
    final firstPrayerDate = _prayers.isEmpty 
        ? currentDate 
        : _prayers.map((p) => p.createdAt).reduce((a, b) => a.isBefore(b) ? a : b);
    
    final years = List.generate(
      currentDate.year - firstPrayerDate.year + 1,
      (index) => firstPrayerDate.year + index,
    ).reversed.toList();

    final months = [
      'Janeiro', 'Fevereiro', 'Março', 'Abril',
      'Maio', 'Junho', 'Julho', 'Agosto',
      'Setembro', 'Outubro', 'Novembro', 'Dezembro'
    ];

    int? selectedYear = _selectedDate?.year;
    int? selectedMonth = _selectedDate?.month;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('Filtrar por Data'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<int>(
                value: selectedYear,
                decoration: InputDecoration(labelText: 'Ano'),
                items: [
                  DropdownMenuItem(
                    value: null,
                    child: Text('Todos os anos'),
                  ),
                  ...years.map((year) => DropdownMenuItem(
                    value: year,
                    child: Text(year.toString()),
                  )),
                ],
                onChanged: (value) {
                  setState(() {
                    selectedYear = value;
                    if (value == null) selectedMonth = null;
                  });
                },
              ),
              SizedBox(height: 16),
              DropdownButtonFormField<int>(
                value: selectedMonth,
                decoration: InputDecoration(labelText: 'Mês'),
                items: [
                  DropdownMenuItem(
                    value: null,
                    child: Text('Todos os meses'),
                  ),
                  ...List.generate(12, (index) => DropdownMenuItem(
                    value: index + 1,
                    child: Text(months[index]),
                  )),
                ],
                onChanged: selectedYear == null ? null : (value) {
                  setState(() => selectedMonth = value);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  if (selectedYear != null && selectedMonth != null) {
                    _selectedDate = DateTime(selectedYear!, selectedMonth!);
                  } else {
                    _selectedDate = null;
                  }
                  _filterPrayers(_searchController.text);
                });
                Navigator.of(context).pop();
              },
              child: Text('Aplicar'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showTagFilterDialog() async {
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
                children: _prayers.map((prayer) => prayer.tags).expand((tags) => tags).toSet().map((tag) {
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
    final themeProvider = Provider.of<ThemeProvider>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Orações'),
        actions: [
          IconButton(
            icon: Icon(Icons.search),
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) {
                  _searchController.clear();
                  _loadData();
                }
              });
            },
          ),
          IconButton(
            icon: Icon(Icons.calendar_month),
            onPressed: _showDateFilterDialog,
          ),
          IconButton(
            icon: Icon(Icons.filter_list),
            onPressed: _showTagFilterDialog,
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
        ],
      ),
      body: Column(
        children: [
          if (_isSearching)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  labelText: 'Pesquisar',
                  suffixIcon: IconButton(
                    icon: Icon(Icons.clear),
                    onPressed: () {
                      _searchController.clear();
                      _loadData();
                    },
                  ),
                ),
                onChanged: (value) {
                  _filterPrayers(value);
                },
              ),
            ),
          Container(
            height: _hasActiveFilters ? 40 : 0,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: 8),
              children: [
                if (_selectedDate != null)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Chip(
                      label: Text(
                        '${_getMonthName(_selectedDate!.month)}/${_selectedDate!.year}',
                      ),
                      onDeleted: () {
                        setState(() {
                          _selectedDate = null;
                          _filterPrayers(_searchController.text);
                        });
                      },
                    ),
                  ),
                ..._selectedTags.map((tag) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Chip(
                      label: Text(tag.name),
                      onDeleted: () {
                        setState(() {
                          _selectedTags.remove(tag);
                          _filterPrayers(_searchController.text);
                        });
                      },
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? Center(
                    child: CircularProgressIndicator(),
                  )
                : _filteredPrayers.isEmpty
                    ? Center(
                        child: Text(
                          _searchController.text.isEmpty && _selectedTags.isEmpty && _selectedDate == null
                              ? 'Nenhuma oração cadastrada'
                              : 'Nenhuma oração encontrada',
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      )
                    : ListView.builder(
                        itemCount: _filteredPrayers.length,
                        itemBuilder: (context, index) {
                          final prayer = _filteredPrayers[index];
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
                                            DateFormat('dd/MM/yyyy HH:mm').format(prayer.createdAt),
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
                                          'Respondida em: ${DateFormat('dd/MM/yyyy HH:mm').format(prayer.answeredAt!)}',
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

  bool get _hasActiveFilters => 
    _selectedDate != null || _selectedTags.isNotEmpty;

  String _getMonthName(int month) {
    final months = [
      'Jan', 'Fev', 'Mar', 'Abr',
      'Mai', 'Jun', 'Jul', 'Ago',
      'Set', 'Out', 'Nov', 'Dez'
    ];
    return months[month - 1];
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
