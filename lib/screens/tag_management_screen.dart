import 'package:flutter/material.dart';
import '../models/tag.dart';
import '../services/database_helper.dart';

class TagManagementScreen extends StatefulWidget {
  const TagManagementScreen({super.key});

  @override
  _TagManagementScreenState createState() => _TagManagementScreenState();
}

class _TagManagementScreenState extends State<TagManagementScreen> {
  List<Tag> _tags = [];
  Map<int, int> _tagUsageCount = {};

  @override
  void initState() {
    super.initState();
    _loadTags();
  }

  Future<void> _loadTags() async {
    final tags = await DatabaseHelper.instance.getAllTags();
    final usageCount = <int, int>{};
    
    for (var tag in tags) {
      if (tag.id != null) {
        final count = await DatabaseHelper.instance.getTagUsageCount(tag.id!);
        usageCount[tag.id!] = count;
      }
    }

    setState(() {
      _tags = tags;
      _tagUsageCount = usageCount;
    });
  }

  Future<void> _addTag() async {
    final TextEditingController controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Nova Tag'),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: 'Nome da Tag',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: Text('Adicionar'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      try {
        await DatabaseHelper.instance.createTag(result);
        _loadTags();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao criar tag: $e')),
        );
      }
    }
  }

  Future<void> _editTag(Tag tag) async {
    final TextEditingController controller = TextEditingController(text: tag.name);
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Editar Tag'),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: 'Nome da Tag',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: Text('Salvar'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty && result != tag.name) {
      try {
        await DatabaseHelper.instance.updateTag(tag.id!, result);
        _loadTags();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao atualizar tag: $e')),
        );
      }
    }
  }

  Future<void> _deleteTag(Tag tag) async {
    final usageCount = _tagUsageCount[tag.id] ?? 0;
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Excluir Tag'),
        content: Text(
          usageCount > 0
              ? 'Esta tag está sendo usada em $usageCount ${usageCount == 1 ? 'oração' : 'orações'}. '
                  'Tem certeza que deseja excluí-la?'
              : 'Tem certeza que deseja excluir esta tag?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: Text('Excluir'),
          ),
        ],
      ),
    );

    if (result == true) {
      try {
        await DatabaseHelper.instance.deleteTag(tag.id!);
        _loadTags();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao excluir tag: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Gerenciar Tags'),
      ),
      body: ListView.builder(
        itemCount: _tags.length,
        itemBuilder: (context, index) {
          final tag = _tags[index];
          final usageCount = _tagUsageCount[tag.id] ?? 0;
          return ListTile(
            leading: CircleAvatar(
              child: Text(tag.name[0].toUpperCase()),
            ),
            title: Text(tag.name),
            subtitle: Text(
              '$usageCount ${usageCount == 1 ? 'oração' : 'orações'}',
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(Icons.edit),
                  onPressed: () => _editTag(tag),
                ),
                IconButton(
                  icon: Icon(Icons.delete),
                  onPressed: () => _deleteTag(tag),
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addTag,
        child: Icon(Icons.add),
      ),
    );
  }
}
