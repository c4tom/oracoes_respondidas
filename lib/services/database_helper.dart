import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/prayer.dart';
import '../models/tag.dart';

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

  Future<String> exportDatabase() async {
    final db = await instance.database;
    final List<Map<String, dynamic>> maps = await db.query('prayers');
    return maps.toString();
  }

  Future<void> importDatabase(String data) async {
    final db = await instance.database;
    await db.delete('prayers');
    
    final List<dynamic> prayers = data as List;
    for (var prayerMap in prayers) {
      await db.insert('prayers', Map<String, dynamic>.from(prayerMap));
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
    String whereClause = '';
    List<dynamic> whereArgs = [];

    if (query != null && query.isNotEmpty) {
      whereClause = 'p.description LIKE ? OR p.answer LIKE ?';
      whereArgs.addAll(['%$query%', '%$query%']);
    }

    if (tagIds != null && tagIds.isNotEmpty) {
      final tagPlaceholders = List.filled(tagIds.length, '?').join(',');
      final tagWhereClause = '''
        p.id IN (
          SELECT prayer_id 
          FROM prayer_tags 
          WHERE tag_id IN ($tagPlaceholders)
          GROUP BY prayer_id
          HAVING COUNT(DISTINCT tag_id) = ${tagIds.length}
        )
      ''';
      
      whereClause = whereClause.isEmpty 
          ? tagWhereClause 
          : '$whereClause AND $tagWhereClause';
      whereArgs.addAll(tagIds);
    }

    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT DISTINCT p.* 
      FROM prayers p
      ${whereClause.isNotEmpty ? 'WHERE $whereClause' : ''}
      ORDER BY p.createdAt DESC
    ''', whereArgs);

    final prayers = await Future.wait(
      maps.map((map) async {
        final prayer = Prayer.fromMap(map);
        if (prayer.id != null) {
          prayer.tags = await getTagsForPrayer(prayer.id!);
        }
        return prayer;
      }),
    );

    return prayers;
  }
}
