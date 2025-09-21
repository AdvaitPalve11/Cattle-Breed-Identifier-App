import 'dart:async';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import '../models/prediction.dart';

class DBProvider {
  static final DBProvider _instance = DBProvider._internal();
  factory DBProvider() => _instance;
  DBProvider._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('predictions.db');
    return _database!;
  }

  Future<Database> _initDB(String fileName) async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final path = join(documentsDirectory.path, fileName);
    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  FutureOr<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE predictions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        breed TEXT NOT NULL,
        confidence REAL NOT NULL,
        imagePath TEXT NOT NULL,
        timestamp INTEGER NOT NULL
      )
    ''');
  }

  Future<int> insertPrediction(Prediction p) async {
    final db = await database;
    return await db.insert('predictions', p.toMap());
  }

  Future<List<Prediction>> getAllPredictions() async {
    final db = await database;
    final maps = await db.query('predictions', orderBy: 'timestamp DESC');
    return maps.map((m) => Prediction.fromMap(m)).toList();
  }

  Future<int> deletePrediction(int id) async {
    final db = await database;
    return await db.delete('predictions', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }
}
