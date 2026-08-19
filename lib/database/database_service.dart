import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseService {
  static const String _databaseName = 'veroon.db';
  static const int _databaseVersion = 7;

  static const String productsTable = 'products';
  static const String salesTable = 'sales';
  static const String expensesTable = 'expenses';

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }

    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final String databasesPath = await getDatabasesPath();
    final String path = join(databasesPath, _databaseName);

    final Database database = await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _createDatabase,
      onUpgrade: _upgradeDatabase,
    );

    debugPrintDatabase(path);

    return database;
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
        buying_price REAL NOT NULL,
        selling_price REAL NOT NULL,
        total_amount REAL NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');

    await database.execute('''
      CREATE TABLE $expensesTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        amount REAL NOT NULL,
        category TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');

    await _createIndexes(database);
  }

  Future<void> _upgradeDatabase(
    Database database,
    int oldVersion,
    int newVersion,
  ) async {
    if (oldVersion < 4) {
      await database.execute('''
        CREATE TABLE IF NOT EXISTS $expensesTable (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          title TEXT NOT NULL,
          amount REAL NOT NULL,
          category TEXT NOT NULL,
          created_at TEXT NOT NULL
        )
      ''');
    }

    if (oldVersion < 5) {
      try {
        await database.execute('''
          ALTER TABLE $salesTable
          ADD COLUMN buying_price REAL NOT NULL DEFAULT 0
        ''');
      } catch (_) {
        // Column already exists.
      }
    }

    if (oldVersion < 6) {
      try {
        await database.execute('''
          ALTER TABLE $productsTable
          ADD COLUMN category TEXT NOT NULL DEFAULT 'Other'
        ''');
      } catch (_) {
        // Column already exists.
      }
    }

    if (oldVersion < 7) {
      await _createIndexes(database);
    }
  }

  Future<void> _createIndexes(Database database) async {
    await database.execute('''
      CREATE INDEX IF NOT EXISTS idx_products_category
      ON $productsTable(category)
    ''');

    await database.execute('''
      CREATE INDEX IF NOT EXISTS idx_products_stock
      ON $productsTable(stock_quantity)
    ''');

    await database.execute('''
      CREATE INDEX IF NOT EXISTS idx_sales_created_at
      ON $salesTable(created_at)
    ''');

    await database.execute('''
      CREATE INDEX IF NOT EXISTS idx_sales_product_id
      ON $salesTable(product_id)
    ''');

    await database.execute('''
      CREATE INDEX IF NOT EXISTS idx_expenses_created_at
      ON $expensesTable(created_at)
    ''');

    await database.execute('''
      CREATE INDEX IF NOT EXISTS idx_expenses_category
      ON $expensesTable(category)
    ''');
  }

  void debugPrintDatabase(String path) {
    print('========================================');
    print('VEROON DATABASE');
    print('Database path: $path');
    print('Database version: $_databaseVersion');
    print('========================================');
  }
}
