import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static const _databaseName = "finance.db";
  static const _databaseVersion = 1;
  static const table = 'logs';
  static const columnId = '_id';
  static const columnName = 'name';
  static const columnCategory = 'category';
  static const columnAmount = 'amount';

  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    await init();
    return _db!;
  }

  Future<void> init() async {
    try {
      final documentsDirectory = await getApplicationDocumentsDirectory();
      final path = join(documentsDirectory.path, _databaseName);
      _db = await openDatabase(path, version: _databaseVersion, onCreate: _onCreate);
    } catch (e) {
      print('Database initialization failed: $e');
    }
  }

  Future _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $table (
        $columnId INTEGER PRIMARY KEY,
        $columnName TEXT NOT NULL,
        $columnCategory TEXT NOT NULL,
        $columnAmount INTEGER NOT NULL
      )
    ''');
  }

  Future<int> insert(Map<String, dynamic> row) async {
    final db = await database;
    return await db.insert(table, row);
  }

  Future<List<Map<String, dynamic>>> queryAllRows() async {
    final db = await database;
    return await db.query(table);
  }

  Future<int> queryRowCount() async {
    final db = await database;
    final results = await db.rawQuery('SELECT COUNT(*) FROM $table');
    return Sqflite.firstIntValue(results) ?? 0;
  }

  Future<int> update(Map<String, dynamic> row) async {
    final db = await database;
    int? id = row[columnId] as int?;
    if (id == null) throw ArgumentError('ID is required for updating');
    return await db.update(table, row, where: '$columnId = ?', whereArgs: [id]);
  }

  Future<int> delete(int id) async {
    final db = await database;
    return await db.delete(table, where: '$columnId = ?', whereArgs: [id]);
  }
}
