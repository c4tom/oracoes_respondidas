import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/prayer.dart';
import '../models/tag.dart';
import 'dart:convert';
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('prayers.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    // Deletar o banco existente para recriar com as novas tabelas
    await deleteDatabase(path);

    return await openDatabase(
      path,
      version: 2,  // Aumentando a versão para forçar a recriação
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Criar novas tabelas se não existirem
      await db.execute('''
        CREATE TABLE IF NOT EXISTS tags (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL UNIQUE
        )
      ''');

      await db.execute('''
        CREATE TABLE IF NOT EXISTS prayer_tags (
          prayer_id INTEGER,
          tag_id INTEGER,
          PRIMARY KEY (prayer_id, tag_id),
          FOREIGN KEY (prayer_id) REFERENCES prayers (id) ON DELETE CASCADE,
          FOREIGN KEY (tag_id) REFERENCES tags (id) ON DELETE CASCADE
        )
      ''');
    }
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE prayers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        description TEXT NOT NULL,
        createdAt TEXT NOT NULL,
        answer TEXT,
        answeredAt TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE tags (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE
      )
    ''');

    await db.execute('''
      CREATE TABLE prayer_tags (
        prayer_id INTEGER,
        tag_id INTEGER,
        PRIMARY KEY (prayer_id, tag_id),
        FOREIGN KEY (prayer_id) REFERENCES prayers (id) ON DELETE CASCADE,
        FOREIGN KEY (tag_id) REFERENCES tags (id) ON DELETE CASCADE
      )
    ''');

    // Add sample data with tags
    final tag1Id = await db.insert('tags', {'name': 'Família'});
    final tag2Id = await db.insert('tags', {'name': 'Saúde'});
    final tag3Id = await db.insert('tags', {'name': 'Trabalho'});

    final prayer1Id = await db.insert('prayers', {
      'description': 'Oração pela saúde da família',
      'createdAt': DateTime.now().toIso8601String(),
    });

    final prayer2Id = await db.insert('prayers', {
      'description': 'Oração por orientação no trabalho',
      'createdAt': DateTime.now().toIso8601String(),
    });

    // Relacionar orações com tags
    await db.insert('prayer_tags', {'prayer_id': prayer1Id, 'tag_id': tag1Id});
    await db.insert('prayer_tags', {'prayer_id': prayer1Id, 'tag_id': tag2Id});
    await db.insert('prayer_tags', {'prayer_id': prayer2Id, 'tag_id': tag3Id});
  }

  Future<Prayer> create(Prayer prayer) async {
    final db = await instance.database;
    final id = await db.insert('prayers', prayer.toMap());
    final newPrayer = Prayer(
      id: id,
      description: prayer.description,
      createdAt: prayer.createdAt,
      answer: prayer.answer,
      answeredAt: prayer.answeredAt,
      tags: prayer.tags,
    );

    // Salvar as tags
    for (var tag in prayer.tags) {
      if (tag.id != null) {
        await addTagToPrayer(id, tag.id!);
      }
    }

    return newPrayer;
  }

  Future<List<Prayer>> getAllPrayers() async {
    final db = await instance.database;
    final result = await db.query('prayers', orderBy: 'createdAt DESC');
    final prayers = result.map((json) => Prayer.fromMap(json)).toList();
    
    // Carregar tags para cada oração
    for (var prayer in prayers) {
      prayer.tags = await getTagsForPrayer(prayer.id!);
    }
    
    return prayers;
  }

  Future<List<Tag>> getAllTags() async {
    final db = await instance.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'tags',
      orderBy: 'name',
    );
    return List.generate(maps.length, (i) => Tag.fromMap(maps[i]));
  }

  Future<List<Tag>> getTagsForPrayer(int prayerId) async {
    final db = await instance.database;
    final result = await db.rawQuery('''
      SELECT t.* FROM tags t
      INNER JOIN prayer_tags pt ON pt.tag_id = t.id
      WHERE pt.prayer_id = ?
      ORDER BY t.name
    ''', [prayerId]);
    return result.map((json) => Tag.fromMap(json)).toList();
  }

  Future<Tag> createTag(String name) async {
    final db = await instance.database;
    
    // Verificar se a tag já existe
    final existingTag = await db.query(
      'tags',
      where: 'name = ?',
      whereArgs: [name],
    );

    if (existingTag.isNotEmpty) {
      return Tag.fromMap(existingTag.first);
    }

    // Criar nova tag
    final id = await db.insert('tags', {'name': name});
    return Tag(id: id, name: name);
  }

  Future<void> addTagToPrayer(int prayerId, int tagId) async {
    final db = await instance.database;
    try {
      await db.insert('prayer_tags', {
        'prayer_id': prayerId,
        'tag_id': tagId,
      });
    } catch (e) {
      // Ignora erro de chave duplicada
      if (!e.toString().contains('UNIQUE constraint failed')) {
        rethrow;
      }
    }
  }

  Future<void> removeTagFromPrayer(int prayerId, int tagId) async {
    final db = await instance.database;
    await db.delete(
      'prayer_tags',
      where: 'prayer_id = ? AND tag_id = ?',
      whereArgs: [prayerId, tagId],
    );
  }

  Future<int> update(Prayer prayer) async {
    final db = await instance.database;
    
    // Atualizar a oração
    final result = await db.update(
      'prayers',
      prayer.toMap(),
      where: 'id = ?',
      whereArgs: [prayer.id],
    );

    // Atualizar as tags
    await db.delete(
      'prayer_tags',
      where: 'prayer_id = ?',
      whereArgs: [prayer.id],
    );

    for (var tag in prayer.tags) {
      if (tag.id != null) {
        await addTagToPrayer(prayer.id!, tag.id!);
      }
    }

    return result;
  }

  Future<int> delete(int id) async {
    final db = await instance.database;
    return await db.delete(
      'prayers',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<String> getBackupFilename() async {
    final now = DateTime.now();
    final timestamp = DateFormat('yyyy-MM-dd_HH-mm-ss').format(now);
    return 'backup_$timestamp.json.gz';
  }

  Future<String> getBackupDirectory() async {
    final dbPath = await getDatabasesPath();
    final backupDir = join(dbPath, 'backups');
    final dir = Directory(backupDir);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return backupDir;
  }

  Future<List<FileSystemEntity>> listBackups() async {
    final backupDir = await getBackupDirectory();
    final dir = Directory(backupDir);
    final List<FileSystemEntity> files = await dir
        .list()
        .where((entity) => entity.path.endsWith('.json.gz'))
        .toList();
    return files..sort((a, b) => b.statSync().modified.compareTo(a.statSync().modified));
  }

  Future<File> exportDatabaseToFile([String? customPath]) async {
    final db = await instance.database;
    
    // Exportar dados
    final Map<String, dynamic> backup = {
      'version': 1,
      'timestamp': DateTime.now().toIso8601String(),
      'prayers': await db.query('prayers'),
      'tags': await db.query('tags'),
      'prayer_tags': await db.query('prayer_tags'),
    };
    
    // Converter para JSON e comprimir
    final jsonString = jsonEncode(backup);
    final gzipBytes = GZipCodec().encode(utf8.encode(jsonString));
    
    // Salvar arquivo
    final String filePath;
    if (customPath != null) {
      filePath = customPath;
    } else {
      final backupDir = await getBackupDirectory();
      final filename = await getBackupFilename();
      filePath = join(backupDir, filename);
    }
    
    final file = File(filePath);
    await file.writeAsBytes(gzipBytes);
    return file;
  }

  Future<void> importDatabaseFromFile(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) {
      throw Exception('Arquivo de backup não encontrado');
    }

    try {
      // Ler e descomprimir arquivo
      final bytes = await file.readAsBytes();
      final jsonString = utf8.decode(GZipCodec().decode(bytes));
      final backup = jsonDecode(jsonString) as Map<String, dynamic>;
      
      // Verificar versão
      final version = backup['version'] as int;
      if (version != 1) {
        throw Exception('Versão do backup incompatível');
      }

      final db = await instance.database;
      await db.transaction((txn) async {
        // Limpar dados existentes
        await txn.delete('prayer_tags');
        await txn.delete('prayers');
        await txn.delete('tags');

        // Importar tags
        final List<dynamic> tags = backup['tags'];
        for (var tag in tags) {
          await txn.insert('tags', tag as Map<String, dynamic>);
        }

        // Importar orações
        final List<dynamic> prayers = backup['prayers'];
        for (var prayer in prayers) {
          await txn.insert('prayers', prayer as Map<String, dynamic>);
        }

        // Importar relações
        final List<dynamic> prayerTags = backup['prayer_tags'];
        for (var prayerTag in prayerTags) {
          await txn.insert('prayer_tags', prayerTag as Map<String, dynamic>);
        }
      });
    } catch (e) {
      throw Exception('Erro ao importar backup: ${e.toString()}');
    }
  }

  Future<int> updateTag(int id, String newName) async {
    final db = await instance.database;
    return db.update(
      'tags',
      {'name': newName},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteTag(int id) async {
    final db = await instance.database;
    return db.delete(
      'tags',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> getTagUsageCount(int tagId) async {
    final db = await instance.database;
    final result = await db.rawQuery('''
      SELECT COUNT(*) as count
      FROM prayer_tags
      WHERE tag_id = ?
    ''', [tagId]);
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<List<Prayer>> searchPrayers({String? query, List<int>? tagIds}) async {
    final db = await instance.database;
    
    var prayersQuery = '''
      SELECT DISTINCT p.*
      FROM prayers p
      LEFT JOIN prayer_tags pt ON p.id = pt.prayer_id
      LEFT JOIN tags t ON pt.tag_id = t.id
    ''';

    List<dynamic> arguments = [];
    List<String> conditions = [];

    if (query != null && query.isNotEmpty) {
      conditions.add('(p.description LIKE ? OR p.answer LIKE ?)');
      arguments.add('%$query%');
      arguments.add('%$query%');
    }

    if (tagIds != null && tagIds.isNotEmpty) {
      conditions.add('pt.tag_id IN (${List.filled(tagIds.length, '?').join(',')})');
      arguments.addAll(tagIds);
    }

    if (conditions.isNotEmpty) {
      prayersQuery += ' WHERE ${conditions.join(' AND ')}';
    }

    prayersQuery += ' ORDER BY p.createdAt DESC';

    final List<Map<String, dynamic>> maps = await db.rawQuery(prayersQuery, arguments);
    
    final prayers = await Future.wait(maps.map((map) async {
      final prayer = Prayer.fromMap(map);
      prayer.tags = await getTagsForPrayer(prayer.id!);
      return prayer;
    }));

    return prayers;
  }

  Future<Tag?> insertTag(Tag tag) async {
    final db = await instance.database;
    try {
      // Verificar se a tag já existe
      final existingTag = await db.query(
        'tags',
        where: 'name = ?',
        whereArgs: [tag.name],
      );

      if (existingTag.isNotEmpty) {
        return Tag.fromMap(existingTag.first);
      }

      // Criar nova tag
      final id = await db.insert('tags', {'name': tag.name});
      return Tag(id: id, name: tag.name);
    } catch (e) {
      print('Erro ao inserir tag: $e');
      return null;
    }
  }

  Future<Prayer?> insertPrayer(Prayer prayer) async {
    final db = await instance.database;
    try {
      final id = await db.insert('prayers', {
        'description': prayer.description,
        'createdAt': prayer.createdAt.toIso8601String(),
        'answer': prayer.answer,
        'answeredAt': prayer.answeredAt?.toIso8601String(),
      });
      
      return Prayer(
        id: id,
        description: prayer.description,
        createdAt: prayer.createdAt,
        answer: prayer.answer,
        answeredAt: prayer.answeredAt,
      );
    } catch (e) {
      print('Erro ao inserir oração: $e');
      return null;
    }
  }

  Future<Prayer?> updatePrayer(Prayer prayer) async {
    final db = await instance.database;
    try {
      await db.update(
        'prayers',
        {
          'description': prayer.description,
          'answer': prayer.answer,
          'answeredAt': prayer.answeredAt?.toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [prayer.id],
      );
      return prayer;
    } catch (e) {
      print('Erro ao atualizar oração: $e');
      return null;
    }
  }

  Future<void> updatePrayerTags(int prayerId, List<Tag> tags) async {
    final db = await instance.database;
    await db.transaction((txn) async {
      // Remover todas as tags atuais
      await txn.delete(
        'prayer_tags',
        where: 'prayer_id = ?',
        whereArgs: [prayerId],
      );

      // Adicionar as novas tags
      for (var tag in tags) {
        if (tag.id != null) {
          await txn.insert('prayer_tags', {
            'prayer_id': prayerId,
            'tag_id': tag.id,
          });
        }
      }
    });
  }

  Future<BackupStats> analyzeBackupFile(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) {
      throw Exception('Arquivo de backup não encontrado');
    }

    try {
      // Ler e descomprimir arquivo
      final bytes = await file.readAsBytes();
      final jsonString = utf8.decode(GZipCodec().decode(bytes));
      final backup = jsonDecode(jsonString) as Map<String, dynamic>;
      
      // Verificar versão
      final version = backup['version'] as int;
      if (version != 1) {
        throw Exception('Versão do backup incompatível');
      }

      final List<dynamic> prayers = backup['prayers'];
      final List<dynamic> tags = backup['tags'];
      
      // Contar orações respondidas
      final answeredPrayers = prayers.where((prayer) => 
        prayer['answer'] != null && prayer['answer'].toString().isNotEmpty
      ).length;

      return BackupStats(
        totalPrayers: prayers.length,
        answeredPrayers: answeredPrayers,
        totalTags: tags.length,
        timestamp: backup['timestamp'] as String,
      );
    } catch (e) {
      throw Exception('Erro ao analisar backup: ${e.toString()}');
    }
  }
}

class BackupStats {
  final int totalPrayers;
  final int answeredPrayers;
  final int totalTags;
  final String timestamp;

  BackupStats({
    required this.totalPrayers,
    required this.answeredPrayers,
    required this.totalTags,
    required this.timestamp,
  });
}
