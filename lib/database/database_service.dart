import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseService {
  static const String _databaseName = 'business_dash.db';
  static const int _databaseVersion = 2;

  static const String productsTable = 'products';
  static const String salesTable = 'sales';

  Database? _database;

  Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }

    _database = await _initializeDatabase();
    return _database!;
  }

  Future<Database> _initializeDatabase() async {
    final databasePath = await getDatabasesPath();
    final path = join(databasePath, _databaseName);

    return openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _createDatabase,
      onUpgrade: _upgradeDatabase,
    );
  }

  Future<void> _createDatabase(Database database, int version) async {
    await database.execute('''
      CREATE TABLE $productsTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        category TEXT NOT NULL,
        buying_price REAL NOT NULL,
        selling_price REAL NOT NULL,
        stock_quantity INTEGER NOT NULL
      )
    ''');

    await database.execute('''
      CREATE TABLE $salesTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        product_id INTEGER NOT NULL,
        product_name TEXT NOT NULL,
        quantity INTEGER NOT NULL,
        selling_price REAL NOT NULL,
        total_amount REAL NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');
  }

  Future<void> _upgradeDatabase(
    Database database,
    int oldVersion,
    int newVersion,
  ) async {
    if (oldVersion < 2) {
      await database.execute('''
        CREATE TABLE $salesTable (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          product_id INTEGER NOT NULL,
          product_name TEXT NOT NULL,
          quantity INTEGER NOT NULL,
          selling_price REAL NOT NULL,
          total_amount REAL NOT NULL,
          created_at TEXT NOT NULL
        )
      ''');
    }
  }
}
