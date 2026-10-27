import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

class DatabaseService {
  static const String _databaseName = 'veroon.db';
  static const int _databaseVersion = 10;

  final String? testDatabasePath;
  final String? testBackupDirectory;

  DatabaseService({this.testDatabasePath, this.testBackupDirectory});

  static const String productsTable = 'products';
  static const String salesTable = 'sales';
  static const String expensesTable = 'expenses';
  static const String inventoryMovementsTable = 'inventory_movements';

  // Metadata reserved for future offline-to-cloud synchronization.
  static const String syncIdColumn = 'sync_id';
  static const String syncStatusColumn = 'sync_status';
  static const String updatedAtColumn = 'updated_at';
  static const String deletedAtColumn = 'deleted_at';

  Database? _database;

  /// Closes this service's database connection.
  Future<void> close() async {
    final db = _database;
    _database = null;

    if (db != null && db.isOpen) {
      await db.close();
    }
  }

  Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }

    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final databasesPath = await getDatabasesPath();
    final path = testDatabasePath ?? join(databasesPath, _databaseName);

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
        product_sync_id TEXT,
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
    await _ensureSyncMetadataSchema(db);
    await _createInventoryMovementsTable(db);
    await _createOpeningBalanceMovements(db);
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

    if (oldVersion < 8) {
      await _ensureSyncMetadataSchema(db);
    }

    if (oldVersion < 9) {
      await _ensureSalesProductSyncId(db);
    }

    if (oldVersion < 10) {
      await _createInventoryMovementsTable(db);
      await _createOpeningBalanceMovements(db);
    }
  }

  Future<void> _createInventoryMovementsTable(DatabaseExecutor db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS inventory_movements (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        sync_id TEXT NOT NULL UNIQUE,
        product_sync_id TEXT NOT NULL,
        movement_type TEXT NOT NULL,
        quantity_delta INTEGER NOT NULL,
        source_sale_sync_id TEXT,
        note TEXT,
        created_at TEXT NOT NULL,
        sync_status TEXT NOT NULL DEFAULT 'pending',
        updated_at TEXT NOT NULL,
        deleted_at TEXT
      )
    ''');

    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_inventory_movements_product
      ON inventory_movements(product_sync_id)
    ''');

    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_inventory_movements_sync_status
      ON inventory_movements(sync_status)
    ''');
  }

  Future<void> _createOpeningBalanceMovements(DatabaseExecutor db) async {
    final products = await db.query(
      productsTable,
      columns: [syncIdColumn, 'stock_quantity', updatedAtColumn],
      where: '$deletedAtColumn IS NULL',
    );

    for (final product in products) {
      final productSyncId = product[syncIdColumn] as String?;

      if (productSyncId == null || productSyncId.isEmpty) {
        continue;
      }

      final existingMovements = await db.query(
        inventoryMovementsTable,
        columns: ['id'],
        where: 'product_sync_id = ? AND movement_type = ?',
        whereArgs: [productSyncId, 'opening_balance'],
        limit: 1,
      );

      if (existingMovements.isNotEmpty) {
        continue;
      }

      final now = DateTime.now().toUtc().toIso8601String();

      await db.insert(inventoryMovementsTable, {
        'sync_id': const Uuid().v4(),
        'product_sync_id': productSyncId,
        'movement_type': 'opening_balance',
        'quantity_delta': product['stock_quantity'] as int,
        'source_sale_sync_id': null,
        'note': 'Stock balance when inventory tracking was introduced',
        'created_at': now,
        syncStatusColumn: 'pending',
        updatedAtColumn: now,
        deletedAtColumn: null,
      });
    }
  }

  Future<void> _ensureSalesProductSyncId(DatabaseExecutor db) async {
    final columns = await db.rawQuery('PRAGMA table_info(sales)');

    if (!columns.any((row) => row['name'] == 'product_sync_id')) {
      await db.execute('ALTER TABLE sales ADD COLUMN product_sync_id TEXT');
    }

    await db.execute('''
      UPDATE sales
      SET product_sync_id = (
        SELECT products.sync_id
        FROM products
        WHERE products.id = sales.product_id
      )
      WHERE product_sync_id IS NULL
    ''');
  }

  Future<void> _ensureSyncMetadataValues(DatabaseExecutor db) async {
    for (final table in <String>[productsTable, salesTable, expensesTable]) {
      await db.execute(
        'UPDATE $table SET sync_id = lower(hex(randomblob(16))) '
        'WHERE sync_id IS NULL OR length(sync_id) = 0',
      );

      await db.execute(
        "UPDATE $table SET sync_status = 'pending' "
        'WHERE sync_status IS NULL OR length(sync_status) = 0',
      );

      await db.execute(
        "UPDATE $table SET updated_at = "
        "strftime('%Y-%m-%dT%H:%M:%fZ', 'now') "
        'WHERE updated_at IS NULL',
      );
    }
  }

  Future<void> _ensureSyncMetadataSchema(DatabaseExecutor db) async {
    final tables = <String>[productsTable, salesTable, expensesTable];

    for (final table in tables) {
      final columns = await db.rawQuery('PRAGMA table_info($table)');

      final additions = <String, String>{
        syncIdColumn: 'TEXT',
        syncStatusColumn: "TEXT NOT NULL DEFAULT 'pending'",
        updatedAtColumn: 'TEXT',
        deletedAtColumn: 'TEXT',
      };

      for (final column in additions.entries) {
        if (!columns.any((row) => row['name'] == column.key)) {
          await db.execute(
            'ALTER TABLE $table ADD COLUMN ${column.key} ${column.value}',
          );
        }
      }

      await db.execute(
        'UPDATE $table SET sync_id = lower(hex(randomblob(16))) '
        'WHERE sync_id IS NULL OR length(sync_id) = 0',
      );

      await db.execute(
        "UPDATE $table SET sync_status = 'pending' "
        'WHERE sync_status IS NULL OR length(sync_status) = 0',
      );

      await db.execute(
        "UPDATE $table SET updated_at = "
        "strftime('%Y-%m-%dT%H:%M:%fZ', 'now') "
        'WHERE updated_at IS NULL',
      );

      await db.execute(
        'CREATE UNIQUE INDEX IF NOT EXISTS idx_${table}_sync_id '
        'ON $table(sync_id) WHERE sync_id IS NOT NULL',
      );

      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_${table}_sync_status '
        'ON $table(sync_status)',
      );
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

  /// Exports business records, including inventory history, to JSON.
  Future<String> exportDatabase() async {
    final db = await database;

    final backup = await db.transaction((txn) async {
      final products = await txn.query(productsTable, orderBy: 'id ASC');

      final sales = await txn.query(salesTable, orderBy: 'id ASC');

      final expenses = await txn.query(expensesTable, orderBy: 'id ASC');

      final inventoryMovements = await txn.query(
        inventoryMovementsTable,
        orderBy: 'id ASC',
      );

      return <String, dynamic>{
        'format': 'veroon_json_backup',
        'formatVersion': 1,
        'databaseVersion': _databaseVersion,
        'exportedAt': DateTime.now().toUtc().toIso8601String(),
        'counts': {
          'products': products.length,
          'sales': sales.length,
          'expenses': expenses.length,
          'inventory_movements': inventoryMovements.length,
        },
        'products': products,
        'sales': sales,
        'expenses': expenses,
        'inventory_movements': inventoryMovements,
      };
    });

    // Tests inject a directory to avoid platform-channel dependencies.
    // Normal application usage falls back to the system temporary directory.
    final String directoryPath;

    if (testBackupDirectory != null) {
      directoryPath = testBackupDirectory!;
    } else {
      directoryPath = (await getTemporaryDirectory()).path;
    }

    final directory = Directory(directoryPath);
    await directory.create(recursive: true);

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

  /// Restores a Veroon JSON backup after validation and a safety export.
  ///
  /// Legacy backups without inventory_movements remain supported.
  Future<Map<String, dynamic>> restoreDatabase(String backupFilePath) async {
    final source = File(backupFilePath);

    if (!await source.exists()) {
      throw const FileSystemException('Backup file not found.');
    }

    final decoded = jsonDecode(await source.readAsString());

    if (decoded is! Map) {
      throw const FormatException('Invalid backup: expected a JSON object.');
    }

    final backup = Map<String, dynamic>.from(decoded);
    final backupVersion = backup['databaseVersion'];

    if (backup['format'] != 'veroon_json_backup' ||
        backup['formatVersion'] != 1 ||
        backupVersion is! int ||
        ![7, 8, 9, 10].contains(backupVersion)) {
      throw const FormatException(
        'Unsupported backup format or database version. '
        'Supported database versions are 7, 8, 9, and 10.',
      );
    }

    final products = _validatedRecords(backup['products'], 'products', [
      'id',
      'name',
      'category',
      'buying_price',
      'selling_price',
      'stock_quantity',
    ]);

    final sales = _validatedRecords(backup['sales'], 'sales', [
      'id',
      'product_id',
      'product_name',
      'quantity',
      'buying_price',
      'selling_price',
      'total_amount',
      'created_at',
    ]);

    final expenses = _validatedRecords(backup['expenses'], 'expenses', [
      'id',
      'title',
      'amount',
      'category',
      'created_at',
    ]);

    final hasMovementRecords = backup.containsKey('inventory_movements');

    final inventoryMovements = hasMovementRecords
        ? _validatedRecords(
            backup['inventory_movements'],
            'inventory_movements',
            [
              'id',
              'sync_id',
              'product_sync_id',
              'movement_type',
              'quantity_delta',
              'created_at',
              'sync_status',
              'updated_at',
            ],
          )
        : <Map<String, Object?>>[];

    // Validate movements before creating a safety backup or changing data.
    for (final movement in inventoryMovements) {
      final quantityDelta = movement['quantity_delta'];

      if (movement['sync_id'] is! String ||
          (movement['sync_id'] as String).trim().isEmpty ||
          movement['product_sync_id'] is! String ||
          (movement['product_sync_id'] as String).trim().isEmpty ||
          movement['movement_type'] is! String ||
          quantityDelta is! num ||
          quantityDelta.toInt() != quantityDelta ||
          movement['created_at'] is! String ||
          movement['sync_status'] is! String ||
          movement['updated_at'] is! String) {
        throw const FormatException(
          'Invalid inventory movement record in backup.',
        );
      }

      final sourceSaleSyncId = movement['source_sale_sync_id'];
      final note = movement['note'];
      final deletedAt = movement['deleted_at'];

      if ((sourceSaleSyncId != null && sourceSaleSyncId is! String) ||
          (note != null && note is! String) ||
          (deletedAt != null && deletedAt is! String)) {
        throw const FormatException(
          'Invalid optional field in inventory movement record.',
        );
      }
    }

    // Preserve the current database in a separate JSON safety copy.
    final safetyBackupPath = await exportDatabase();
    final db = await database;

    await db.transaction((txn) async {
      await txn.delete(inventoryMovementsTable);
      await txn.delete(salesTable);
      await txn.delete(expensesTable);
      await txn.delete(productsTable);

      for (final record in products) {
        await txn.insert(
          productsTable,
          record,
          conflictAlgorithm: ConflictAlgorithm.abort,
        );
      }

      for (final record in sales) {
        await txn.insert(
          salesTable,
          record,
          conflictAlgorithm: ConflictAlgorithm.abort,
        );
      }

      for (final record in expenses) {
        await txn.insert(
          expensesTable,
          record,
          conflictAlgorithm: ConflictAlgorithm.abort,
        );
      }

      for (final record in inventoryMovements) {
        await txn.insert(
          inventoryMovementsTable,
          record,
          conflictAlgorithm: ConflictAlgorithm.abort,
        );
      }

      await _ensureSyncMetadataValues(txn);
      await _ensureSalesProductSyncId(txn);

      // Legacy backups get opening balances without changing stock.
      if (!hasMovementRecords) {
        await _createOpeningBalanceMovements(txn);
      }
    });

    final restoredDb = await database;

    final movementCount =
        Sqflite.firstIntValue(
          await restoredDb.rawQuery(
            'SELECT COUNT(*) FROM $inventoryMovementsTable',
          ),
        ) ??
        0;

    return {
      'products': products.length,
      'sales': sales.length,
      'expenses': expenses.length,
      'inventory_movements': movementCount,
      'safetyBackupPath': safetyBackupPath,
    };
  }

  List<Map<String, Object?>> _validatedRecords(
    dynamic value,
    String tableName,
    List<String> requiredFields,
  ) {
    if (value is! List) {
      throw FormatException('Invalid backup: $tableName must be a list.');
    }

    final records = <Map<String, Object?>>[];
    final seenIds = <int>{};
    final seenSyncIds = <String>{};

    for (final item in value) {
      if (item is! Map) {
        throw FormatException('Invalid record in $tableName.');
      }

      final record = Map<String, dynamic>.from(item);

      for (final field in requiredFields) {
        if (!record.containsKey(field) || record[field] == null) {
          throw FormatException(
            'A $tableName record is missing required field "$field".',
          );
        }
      }

      final rawId = record['id'];

      if (rawId is! num || rawId.toInt() != rawId || rawId <= 0) {
        throw FormatException('Invalid record ID in $tableName.');
      }

      final id = rawId.toInt();

      if (!seenIds.add(id)) {
        throw FormatException('Duplicate record ID $id in $tableName.');
      }

      final rawSyncId = record[syncIdColumn];

      if (rawSyncId != null) {
        if (rawSyncId is! String) {
          throw FormatException('Invalid sync ID in $tableName.');
        }

        final syncId = rawSyncId.trim();

        if (syncId.isNotEmpty && !seenSyncIds.add(syncId)) {
          throw FormatException('Duplicate sync ID in $tableName.');
        }
      }

      records.add(Map<String, Object?>.from(record));
    }

    return records;
  }

  /// Opens the sharing menu with the exported JSON backup.
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
