import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/prayer.dart';

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

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
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
    // Add sample data
    await db.insert('prayers', {
      'description': 'Oração de exemplo 1',
      'createdAt': DateTime.now().toIso8601String(),
    });
    await db.insert('prayers', {
      'description': 'Oração de exemplo 2',
      'createdAt': DateTime.now().toIso8601String(),
    });
  }

  Future<Prayer> create(Prayer prayer) async {
    final db = await instance.database;
    final id = await db.insert('prayers', prayer.toMap());
    return prayer.id == null ? Prayer(
      id: id,
      description: prayer.description,
      createdAt: prayer.createdAt,
      answer: prayer.answer,
      answeredAt: prayer.answeredAt,
    ) : prayer;
  }

  Future<List<Prayer>> getAllPrayers() async {
    final db = await instance.database;
    final result = await db.query('prayers', orderBy: 'createdAt DESC');
    return result.map((json) => Prayer.fromMap(json)).toList();
  }

  Future<int> update(Prayer prayer) async {
    final db = await instance.database;
    return db.update(
      'prayers',
      prayer.toMap(),
      where: 'id = ?',
      whereArgs: [prayer.id],
    );
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
}
