import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:business_dash/database/database_service.dart';
import 'package:business_dash/models/product.dart';
import 'package:business_dash/repositories/product_repository.dart';

void main() {
  late DatabaseService databaseService;
  late ProductRepository repository;
  late Directory temporaryDirectory;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    temporaryDirectory = await Directory.systemTemp.createTemp(
      'veroon_product_test_',
    );

    databaseService = DatabaseService(
      testDatabasePath: '${temporaryDirectory.path}/test.db',
    );

    repository = ProductRepository(databaseService: databaseService);
  });

  tearDown(() async {
    await databaseService.close();

    if (await temporaryDirectory.exists()) {
      await temporaryDirectory.delete(recursive: true);
    }
  });

  test('Product can be saved and retrieved', () async {
    final id = await repository.insertProduct(
      Product(
        name: 'Test Brake Pads',
        category: 'Motorcycle Parts',
        buyingPrice: 1500,
        sellingPrice: 2500,
        stockQuantity: 10,
      ),
    );

    expect(id, greaterThan(0));

    final products = await repository.getProducts();

    expect(products, hasLength(1));
    expect(products.single.name, 'Test Brake Pads');
    expect(products.single.stockQuantity, 10);
  });

  test('Updating product details does not change stock', () async {
    final id = await repository.insertProduct(
      Product(
        name: 'Test Brake Pads',
        category: 'Motorcycle Parts',
        buyingPrice: 1500,
        sellingPrice: 2500,
        stockQuantity: 10,
      ),
    );

    final updatedCount = await repository.updateProduct(
      Product(
        id: id,
        name: 'Updated Brake Pads',
        category: 'Motorcycle Parts',
        buyingPrice: 1600,
        sellingPrice: 2600,
        stockQuantity: 999,
      ),
    );

    expect(updatedCount, 1);

    final products = await repository.getProducts();

    expect(products, hasLength(1));
    expect(products.single.name, 'Updated Brake Pads');
    expect(products.single.buyingPrice, 1600);
    expect(products.single.sellingPrice, 2600);
    expect(products.single.stockQuantity, 10);
  });

  test('Updating a product without an ID is rejected', () async {
    await expectLater(
      repository.updateProduct(
        Product(
          name: 'Brake Pads',
          category: 'Motorcycle Parts',
          buyingPrice: 1500,
          sellingPrice: 2500,
          stockQuantity: 10,
        ),
      ),
      throwsA(isA<ArgumentError>()),
    );
  });

  test('Stock adjustment records an inventory movement', () async {
    final id = await repository.insertProduct(
      Product(
        name: 'Test Brake Pads',
        category: 'Motorcycle Parts',
        buyingPrice: 1500,
        sellingPrice: 2500,
        stockQuantity: 10,
      ),
    );

    final db = await databaseService.database;
    final productRows = await db.query(
      DatabaseService.productsTable,
      where: 'id = ?',
      whereArgs: [id],
    );

    final productSyncId =
        productRows.single[DatabaseService.syncIdColumn] as String;

    final adjusted = await repository.adjustStock(
      productId: id,
      quantityDelta: 5,
      note: 'Received new stock',
    );

    expect(adjusted, 15);

    final updatedRows = await db.query(
      DatabaseService.productsTable,
      where: 'id = ?',
      whereArgs: [id],
    );

    expect(updatedRows.single['stock_quantity'], 15);

    final movements = await db.query(
      DatabaseService.inventoryMovementsTable,
      where: 'product_sync_id = ? AND movement_type = ?',
      whereArgs: [productSyncId, 'adjustment'],
    );

    expect(movements, hasLength(1));
    expect(movements.single['quantity_delta'], 5);
    expect(movements.single['note'], 'Received new stock');
    expect(movements.single[DatabaseService.syncStatusColumn], 'pending');
  });

  test(
    'Stock adjustment can reduce stock and record a negative movement',
    () async {
      final id = await repository.insertProduct(
        Product(
          name: 'Test Brake Pads',
          category: 'Motorcycle Parts',
          buyingPrice: 1500,
          sellingPrice: 2500,
          stockQuantity: 10,
        ),
      );

      final db = await databaseService.database;
      final productRows = await db.query(
        DatabaseService.productsTable,
        where: 'id = ?',
        whereArgs: [id],
      );

      final productSyncId =
          productRows.single[DatabaseService.syncIdColumn] as String;

      final adjusted = await repository.adjustStock(
        productId: id,
        quantityDelta: -4,
        note: 'Damaged stock',
      );

      expect(adjusted, 6);

      final products = await db.query(
        DatabaseService.productsTable,
        where: 'id = ?',
        whereArgs: [id],
      );

      expect(products.single['stock_quantity'], 6);

      final movements = await db.query(
        DatabaseService.inventoryMovementsTable,
        where: 'product_sync_id = ? AND movement_type = ?',
        whereArgs: [productSyncId, 'adjustment'],
      );

      expect(movements, hasLength(1));
      expect(movements.single['quantity_delta'], -4);
      expect(movements.single['note'], 'Damaged stock');
    },
  );

  test('Stock adjustment cannot make stock negative', () async {
    final id = await repository.insertProduct(
      Product(
        name: 'Test Brake Pads',
        category: 'Motorcycle Parts',
        buyingPrice: 1500,
        sellingPrice: 2500,
        stockQuantity: 3,
      ),
    );

    final db = await databaseService.database;

    await expectLater(
      repository.adjustStock(
        productId: id,
        quantityDelta: -4,
        note: 'Test over-adjustment',
      ),
      throwsA(isA<StateError>()),
    );

    final products = await db.query(
      DatabaseService.productsTable,
      where: 'id = ?',
      whereArgs: [id],
    );

    final movements = await db.query(
      DatabaseService.inventoryMovementsTable,
      where: 'movement_type = ?',
      whereArgs: ['adjustment'],
    );

    expect(products.single['stock_quantity'], 3);
    expect(movements, isEmpty);
  });

  test('Stock adjustment rejects a zero quantity change', () async {
    final id = await repository.insertProduct(
      Product(
        name: 'Test Brake Pads',
        category: 'Motorcycle Parts',
        buyingPrice: 1500,
        sellingPrice: 2500,
        stockQuantity: 10,
      ),
    );

    await expectLater(
      repository.adjustStock(
        productId: id,
        quantityDelta: 0,
        note: 'No change',
      ),
      throwsA(isA<ArgumentError>()),
    );

    final db = await databaseService.database;
    final movements = await db.query(
      DatabaseService.inventoryMovementsTable,
      where: 'movement_type = ?',
      whereArgs: ['adjustment'],
    );

    expect(movements, isEmpty);
  });

  test('Stock adjustment rejects a blank note', () async {
    final id = await repository.insertProduct(
      Product(
        name: 'Test Brake Pads',
        category: 'Motorcycle Parts',
        buyingPrice: 1500,
        sellingPrice: 2500,
        stockQuantity: 10,
      ),
    );

    await expectLater(
      repository.adjustStock(productId: id, quantityDelta: 3, note: '   '),
      throwsA(isA<ArgumentError>()),
    );

    final db = await databaseService.database;
    final products = await db.query(
      DatabaseService.productsTable,
      where: 'id = ?',
      whereArgs: [id],
    );

    final movements = await db.query(
      DatabaseService.inventoryMovementsTable,
      where: 'movement_type = ?',
      whereArgs: ['adjustment'],
    );

    expect(products.single['stock_quantity'], 10);
    expect(movements, isEmpty);
  });

  test('Stock adjustment rejects a missing product', () async {
    await expectLater(
      repository.adjustStock(
        productId: 999999,
        quantityDelta: 3,
        note: 'Received new stock',
      ),
      throwsA(isA<StateError>()),
    );

    final db = await databaseService.database;
    final movements = await db.query(
      DatabaseService.inventoryMovementsTable,
      where: 'movement_type = ?',
      whereArgs: ['adjustment'],
    );

    expect(movements, isEmpty);
  });
}
