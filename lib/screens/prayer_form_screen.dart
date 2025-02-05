import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../models/prayer.dart';
import '../models/tag.dart';
import '../services/database_helper.dart';
import '../utils/tag_colors.dart';

class PrayerFormScreen extends StatefulWidget {
  final Prayer? prayer;

  const PrayerFormScreen({super.key, this.prayer});

  @override
  _PrayerFormScreenState createState() => _PrayerFormScreenState();
}

class _PrayerFormScreenState extends State<PrayerFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _descriptionController;
  late TextEditingController _answerController;
  bool _isPreview = false;
  List<Tag> _selectedTags = [];
  List<Tag> _availableTags = [];

  @override
  void initState() {
    super.initState();
    _descriptionController =
        TextEditingController(text: widget.prayer?.description ?? '');
    _answerController =
        TextEditingController(text: widget.prayer?.answer ?? '');
    _loadTags();
  }

  Future<void> _loadTags() async {
    _availableTags = await DatabaseHelper.instance.getAllTags();
    if (widget.prayer != null) {
      _selectedTags = await DatabaseHelper.instance.getTagsForPrayer(widget.prayer!.id!);
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.prayer == null ? 'Nova Oração' : 'Editar Oração'),
        actions: [
          IconButton(
            icon: Icon(_isPreview ? Icons.edit : Icons.preview),
            onPressed: () {
              setState(() {
                _isPreview = !_isPreview;
              });
            },
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (!_isPreview)
                  TextFormField(
                    controller: _descriptionController,
                    decoration: InputDecoration(
                      labelText: 'Descrição da Oração',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 5,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor, digite sua oração';
                      }
                      return null;
                    },
                  )
                else
                  Expanded(
                    child: Markdown(
                      data: _descriptionController.text,
                    ),
                  ),
                SizedBox(height: 16),
                if (!_isPreview) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Tags:',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      TextButton.icon(
                        icon: Icon(Icons.add),
                        label: Text('Adicionar Tag'),
                        onPressed: _showTagDialog,
                      ),
                    ],
                  ),
                  if (_selectedTags.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        'Nenhuma tag selecionada. Clique em "Adicionar Tag" para começar.',
                        style: TextStyle(
                          color: Theme.of(context).hintColor,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    )
                  else
                    Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Theme.of(context).dividerColor,
                          width: 1,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _selectedTags.map((tag) {
                          final tagColor = TagColors.getColorForTag(tag.name);
                          return Chip(
                            label: Text(
                              tag.name,
                              style: TextStyle(
                                color: tagColor,
                              ),
                            ),
                            backgroundColor: TagColors.getBackgroundColorForTag(tag.name),
                            deleteIconColor: tagColor,
                            onDeleted: () {
                              setState(() {
                                _selectedTags.remove(tag);
                              });
                            },
                          );
                        }).toList(),
                      ),
                    ),
                ],
                if (widget.prayer != null) ...[
                  if (!_isPreview)
                    TextFormField(
                      controller: _answerController,
                      decoration: InputDecoration(
                        labelText: 'Resposta da Oração',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    )
                  else
                    Expanded(
                      child: Markdown(
                        data: _answerController.text,
                      ),
                    ),
                ],
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  child: Row(
                    children: [
                      TextButton.icon(
                        icon: Icon(Icons.format_bold),
                        label: Text('Negrito'),
                        onPressed: () => _insertMarkdown('**', '**'),
                      ),
                      TextButton.icon(
                        icon: Icon(Icons.format_italic),
                        label: Text('Itálico'),
                        onPressed: () => _insertMarkdown('_', '_'),
                      ),
                      TextButton.icon(
                        icon: Icon(Icons.format_list_bulleted),
                        label: Text('Lista'),
                        onPressed: () => _insertMarkdown('\n- ', ''),
                      ),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: _savePrayer,
                  child: Text('Salvar'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showTagDialog() async {
    final result = await showDialog<Tag>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Adicionar Tag'),
        content: Container(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_availableTags.where((tag) => !_selectedTags.contains(tag)).isEmpty)
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    'Nenhuma tag disponível.',
                    style: TextStyle(
                      color: Theme.of(context).hintColor,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                )
              else
                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: _availableTags
                          .where((tag) => !_selectedTags.contains(tag))
                          .map((tag) => ListTile(
                                title: Text(
                                  tag.name,
                                  style: TextStyle(
                                    color: TagColors.getTextColorForTag(tag.name),
                                  ),
                                ),
                                tileColor: TagColors.getBackgroundColorForTag(tag.name),
                                onTap: () => Navigator.pop(context, tag),
                              ))
                          .toList(),
                    ),
                  ),
                ),
              Divider(),
              ListTile(
                leading: Icon(Icons.add),
                title: Text('Nova Tag'),
                onTap: () async {
                  Navigator.pop(context);
                  await _showNewTagDialog();
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar'),
          ),
        ],
      ),
    );

    if (result != null && !_selectedTags.contains(result)) {
      setState(() {
        _selectedTags.add(result);
      });
    }
  }

  Future<void> _showNewTagDialog() async {
    final TextEditingController tagController = TextEditingController();
    final newTagName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Nova Tag'),
        content: TextField(
          controller: tagController,
          decoration: InputDecoration(
            labelText: 'Nome da Tag',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
          textCapitalization: TextCapitalization.words,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              if (tagController.text.isNotEmpty) {
                Navigator.pop(context, tagController.text);
              }
            },
            child: Text('Adicionar'),
          ),
        ],
      ),
    );

    if (newTagName != null && newTagName.isNotEmpty) {
      final newTag = Tag(name: newTagName);
      final insertedTag = await DatabaseHelper.instance.insertTag(newTag);
      if (insertedTag != null) {
        setState(() {
          _availableTags.add(insertedTag);
          _selectedTags.add(insertedTag);
        });
      }
    }
  }

  void _insertMarkdown(String prefix, String suffix) {
    final text = _descriptionController.text;
    final selection = _descriptionController.selection;
    final newText = text.replaceRange(
      selection.start,
      selection.end,
      '$prefix${text.substring(selection.start, selection.end)}$suffix',
    );
    _descriptionController.text = newText;
  }

  Future<void> _savePrayer() async {
    if (_formKey.currentState!.validate()) {
      final prayer = Prayer(
        id: widget.prayer?.id,
        description: _descriptionController.text,
        answer: _answerController.text.isEmpty ? null : _answerController.text,
        createdAt: widget.prayer?.createdAt ?? DateTime.now(),
        answeredAt: _answerController.text.isEmpty ? null : DateTime.now(),
      );

      final savedPrayer = widget.prayer == null
          ? await DatabaseHelper.instance.insertPrayer(prayer)
          : await DatabaseHelper.instance.updatePrayer(prayer);

      if (savedPrayer != null) {
        // Atualiza as tags
        await DatabaseHelper.instance.updatePrayerTags(savedPrayer.id!, _selectedTags);
        if (mounted) {
          Navigator.pop(context, true);
        }
      }
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _answerController.dispose();
    super.dispose();
  }
}
