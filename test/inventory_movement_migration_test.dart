import 'dart:convert';
import 'dart:io';

import 'package:business_dash/database/database_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late DatabaseService databaseService;
  late Directory temporaryDirectory;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    temporaryDirectory = await Directory.systemTemp.createTemp(
      'veroon_backup_test_',
    );

    databaseService = DatabaseService(
      testDatabasePath: '${temporaryDirectory.path}/test.db',
      testBackupDirectory: temporaryDirectory.path,
    );
  });

  tearDown(() async {
    await databaseService.close();

    if (await temporaryDirectory.exists()) {
      await temporaryDirectory.delete(recursive: true);
    }
  });

  Future<Map<String, Object?>> insertProduct(
    DatabaseExecutor db, {
    required String name,
    required int stock,
  }) async {
    final now = DateTime.now().toUtc().toIso8601String();

    final id = await db.insert('products', {
      'name': name,
      'category': 'Test',
      'buying_price': 10.0,
      'selling_price': 20.0,
      'stock_quantity': stock,
      'updated_at': now,
      'deleted_at': null,
      'sync_id': 'product-$name',
      'sync_status': 'synced',
    });

    final rows = await db.query('products', where: 'id = ?', whereArgs: [id]);

    return rows.single;
  }

  Future<Map<String, Object?>> insertMovement(
    DatabaseExecutor db, {
    required String productSyncId,
    required String syncId,
    required int quantityDelta,
    String movementType = 'adjustment',
  }) async {
    final now = DateTime.now().toUtc().toIso8601String();

    final id = await db.insert('inventory_movements', {
      'sync_id': syncId,
      'product_sync_id': productSyncId,
      'movement_type': movementType,
      'quantity_delta': quantityDelta,
      'source_sale_sync_id': null,
      'note': 'Backup test',
      'created_at': now,
      'sync_status': 'synced',
      'updated_at': now,
      'deleted_at': null,
    });

    final rows = await db.query(
      'inventory_movements',
      where: 'id = ?',
      whereArgs: [id],
    );

    return rows.single;
  }

  test('Fresh database creates inventory movements table', () async {
    final db = await databaseService.database;

    final tables = await db.rawQuery(
      "SELECT name FROM sqlite_master "
      "WHERE type = 'table' AND name = 'inventory_movements'",
    );

    expect(tables, hasLength(1));

    final columns = await db.rawQuery('PRAGMA table_info(inventory_movements)');
    final columnNames = columns.map((column) => column['name']).toSet();

    expect(columnNames, contains('sync_id'));
    expect(columnNames, contains('product_sync_id'));
    expect(columnNames, contains('movement_type'));
    expect(columnNames, contains('quantity_delta'));
    expect(columnNames, contains('sync_status'));
  });

  test('Export includes products and inventory movement history', () async {
    final db = await databaseService.database;

    await insertProduct(db, name: 'Brake Pads', stock: 10);

    await insertMovement(
      db,
      productSyncId: 'product-Brake Pads',
      syncId: 'movement-brake-pads-1',
      quantityDelta: 10,
      movementType: 'opening_balance',
    );

    final backupPath = await databaseService.exportDatabase();
    final backupFile = File(backupPath);
    final backup =
        jsonDecode(await backupFile.readAsString()) as Map<String, dynamic>;

    expect(backup['format'], 'veroon_json_backup');
    expect(backup['formatVersion'], 1);
    expect(backup['products'], hasLength(1));
    expect(backup['inventory_movements'], hasLength(1));
    expect(
      backup['inventory_movements'][0]['sync_id'],
      'movement-brake-pads-1',
    );
    expect(backup['counts']['inventory_movements'], 1);
  });

  test('Restore preserves product stock and movement history', () async {
    final db = await databaseService.database;

    await insertProduct(db, name: 'Brake Pads', stock: 10);

    await insertMovement(
      db,
      productSyncId: 'product-Brake Pads',
      syncId: 'movement-brake-pads-1',
      quantityDelta: 10,
      movementType: 'opening_balance',
    );

    await insertMovement(
      db,
      productSyncId: 'product-Brake Pads',
      syncId: 'movement-brake-pads-2',
      quantityDelta: -2,
    );

    final backupPath = await databaseService.exportDatabase();

    await db.update(
      'products',
      {'stock_quantity': 3},
      where: 'sync_id = ?',
      whereArgs: ['product-Brake Pads'],
    );

    await db.delete('inventory_movements');

    final result = await databaseService.restoreDatabase(backupPath);

    final restoredProducts = await db.query('products');
    final restoredMovements = await db.query(
      'inventory_movements',
      orderBy: 'id ASC',
    );

    expect(restoredProducts, hasLength(1));
    expect(restoredProducts.single['stock_quantity'], 10);

    expect(restoredMovements, hasLength(2));
    expect(restoredMovements.map((row) => row['sync_id']).toList(), [
      'movement-brake-pads-1',
      'movement-brake-pads-2',
    ]);

    expect(result['products'], 1);
    expect(result['inventory_movements'], 2);
    expect(File(result['safetyBackupPath'] as String).existsSync(), isTrue);
  });

  test(
    'Legacy backup creates opening balances without changing stock',
    () async {
      final db = await databaseService.database;

      await insertProduct(db, name: 'Legacy Item', stock: 7);

      final backupPath = await databaseService.exportDatabase();
      final backupFile = File(backupPath);
      final backup =
          jsonDecode(await backupFile.readAsString()) as Map<String, dynamic>;

      backup.remove('inventory_movements');
      (backup['counts'] as Map<String, dynamic>).remove('inventory_movements');
      backup['databaseVersion'] = 9;

      final legacyPath = '${temporaryDirectory.path}/legacy_backup.json';

      await File(legacyPath).writeAsString(jsonEncode(backup));

      await db.update(
        'products',
        {'stock_quantity': 2},
        where: 'sync_id = ?',
        whereArgs: ['product-Legacy Item'],
      );

      final result = await databaseService.restoreDatabase(legacyPath);

      final restoredProducts = await db.query(
        'products',
        where: 'sync_id = ?',
        whereArgs: ['product-Legacy Item'],
      );

      final movements = await db.query(
        'inventory_movements',
        where: 'product_sync_id = ?',
        whereArgs: ['product-Legacy Item'],
      );

      expect(restoredProducts.single['stock_quantity'], 7);
      expect(movements, hasLength(1));
      expect(movements.single['movement_type'], 'opening_balance');
      expect(movements.single['quantity_delta'], 7);
      expect(result['inventory_movements'], 1);
    },
  );

  test('Invalid movement data is rejected without replacing records', () async {
    final db = await databaseService.database;

    await insertProduct(db, name: 'Existing Item', stock: 5);

    final backupPath = await databaseService.exportDatabase();
    final backupFile = File(backupPath);
    final backup =
        jsonDecode(await backupFile.readAsString()) as Map<String, dynamic>;

    backup['inventory_movements'] = [
      {
        'id': 1,
        'sync_id': '',
        'product_sync_id': 'product-Existing Item',
        'movement_type': 'adjustment',
        'quantity_delta': 2,
        'created_at': DateTime.now().toUtc().toIso8601String(),
        'sync_status': 'synced',
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      },
    ];

    final invalidPath = '${temporaryDirectory.path}/invalid_backup.json';

    await File(invalidPath).writeAsString(jsonEncode(backup));

    await expectLater(
      databaseService.restoreDatabase(invalidPath),
      throwsA(isA<FormatException>()),
    );

    final products = await db.query('products');

    expect(products, hasLength(1));
    expect(products.single['name'], 'Existing Item');
    expect(products.single['stock_quantity'], 5);
  });
}
