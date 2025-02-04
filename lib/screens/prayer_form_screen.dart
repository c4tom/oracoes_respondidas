import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../models/prayer.dart';
import '../services/database_helper.dart';

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

  @override
  void initState() {
    super.initState();
    _descriptionController =
        TextEditingController(text: widget.prayer?.description ?? '');
    _answerController =
        TextEditingController(text: widget.prayer?.answer ?? '');
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
          child: Column(
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
    );
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
        createdAt: widget.prayer?.createdAt ?? DateTime.now(),
        answer: _answerController.text.isEmpty ? null : _answerController.text,
        answeredAt: _answerController.text.isEmpty ? null : DateTime.now(),
      );

      if (widget.prayer == null) {
        await DatabaseHelper.instance.create(prayer);
      } else {
        await DatabaseHelper.instance.update(prayer);
      }

      Navigator.pop(context, true);
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _answerController.dispose();
    super.dispose();
  }
}
