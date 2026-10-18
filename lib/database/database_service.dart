import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseService {
  static const String _databaseName = 'veroon.db';
  static const int _databaseVersion = 7;

  static const String productsTable = 'products';
  static const String salesTable = 'sales';
  static const String expensesTable = 'expenses';

  Database? _database;

  Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }

    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, _databaseName);

    final db = await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _createDatabase,
      onUpgrade: _upgradeDatabase,
    );

    debugPrintDatabase(path);

    return db;
  }

  Future<void> _createDatabase(Database db, int version) async {
    await db.execute('''
      CREATE TABLE products (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        category TEXT NOT NULL,
        buying_price REAL NOT NULL,
        selling_price REAL NOT NULL,
        stock_quantity INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE sales (
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

    await db.execute('''
      CREATE TABLE expenses (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        amount REAL NOT NULL,
        category TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');

    await _createIndexes(db);
  }

  Future<void> _upgradeDatabase(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    if (oldVersion < 4) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS expenses (
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
        await db.execute(
          'ALTER TABLE sales ADD COLUMN buying_price REAL NOT NULL DEFAULT 0',
        );
      } catch (_) {}
    }

    if (oldVersion < 6) {
      try {
        await db.execute(
          "ALTER TABLE products ADD COLUMN category TEXT NOT NULL DEFAULT 'Other'",
        );
      } catch (_) {}
    }

    if (oldVersion < 7) {
      await _createIndexes(db);
    }
  }

  Future<void> _createIndexes(Database db) async {
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_products_category
      ON products(category)
    ''');

    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_products_stock
      ON products(stock_quantity)
    ''');

    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_sales_created_at
      ON sales(created_at)
    ''');

    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_sales_product_id
      ON sales(product_id)
    ''');

    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_expenses_created_at
      ON expenses(created_at)
    ''');

    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_expenses_category
      ON expenses(category)
    ''');
  }

  void debugPrintDatabase(String path) {
    print('Veroon database path: $path');
    print('Veroon database version: $_databaseVersion');
  }

  /// Exports business records to a JSON file.
  /// This does not modify or replace the live database.
  Future<String> exportDatabase() async {
    final db = await database;

    final backup = await db.transaction((txn) async {
      final products = await txn.query(productsTable, orderBy: 'id ASC');

      final sales = await txn.query(salesTable, orderBy: 'id ASC');

      final expenses = await txn.query(expensesTable, orderBy: 'id ASC');

      return <String, dynamic>{
        'format': 'veroon_json_backup',
        'formatVersion': 1,
        'databaseVersion': _databaseVersion,
        'exportedAt': DateTime.now().toUtc().toIso8601String(),
        'counts': {
          'products': products.length,
          'sales': sales.length,
          'expenses': expenses.length,
        },
        'products': products,
        'sales': sales,
        'expenses': expenses,
      };
    });

    final directory = await getTemporaryDirectory();

    final file = File(
      join(
        directory.path,
        'veroon_backup_${DateTime.now().millisecondsSinceEpoch}.json',
      ),
    );

    await file.writeAsString(
      const JsonEncoder.withIndent('  ').convert(backup),
      flush: true,
    );

    return file.path;
  }

  /// Opens the Android sharing menu with the exported JSON backup.
  Future<void> shareDatabaseBackup() async {
    final filePath = await exportDatabase();

    await SharePlus.instance.share(
      ShareParams(
        title: 'Veroon Business Data Backup',
        text: 'Veroon business data backup. Please handle this file securely.',
        files: [XFile(filePath)],
      ),
    );
  }
}
