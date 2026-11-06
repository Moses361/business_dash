import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:business_dash/database/database_service.dart';
import 'package:business_dash/models/product.dart';
import 'package:business_dash/models/sale.dart';
import 'package:business_dash/repositories/product_repository.dart';
import 'package:business_dash/repositories/sale_repository.dart';

void main() {
  late DatabaseService databaseService;
  late ProductRepository productRepository;
  late SaleRepository saleRepository;
  late Directory temporaryDirectory;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    temporaryDirectory = await Directory.systemTemp.createTemp(
      'veroon_sale_test_',
    );

    databaseService = DatabaseService(
      testDatabasePath: '${temporaryDirectory.path}/test.db',
    );

    productRepository = ProductRepository(databaseService: databaseService);

    saleRepository = SaleRepository(databaseService: databaseService);
  });

  tearDown(() async {
    await databaseService.close();

    if (await temporaryDirectory.exists()) {
      await temporaryDirectory.delete(recursive: true);
    }
  });

  Future<int> createProduct({int stock = 10}) {
    return productRepository.insertProduct(
      Product(
        name: 'Test Brake Pads',
        category: 'Motorcycle Parts',
        buyingPrice: 1500,
        sellingPrice: 2500,
        stockQuantity: stock,
      ),
    );
  }

  Sale makeSale({required int productId, int quantity = 2}) {
    return Sale(
      productId: productId,
      productName: 'Test Brake Pads',
      quantity: quantity,
      buyingPrice: 1500,
      sellingPrice: 2500,
      totalAmount: quantity * 2500,
      createdAt: DateTime.now(),
    );
  }

  test('Recording a sale reduces stock and records its movement', () async {
    final productId = await createProduct(stock: 10);

    final saleId = await saleRepository.recordSale(
      sale: makeSale(productId: productId, quantity: 3),
    );

    final products = await productRepository.getProducts();
    final sales = await saleRepository.getSales();
    final db = await databaseService.database;

    final saleRows = await db.query(
      DatabaseService.salesTable,
      where: 'id = ?',
      whereArgs: [saleId],
    );

    final saleSyncId = saleRows.single[DatabaseService.syncIdColumn] as String;

    final movements = await db.query(
      DatabaseService.inventoryMovementsTable,
      where: 'source_sale_sync_id = ?',
      whereArgs: [saleSyncId],
    );

    expect(saleId, greaterThan(0));
    expect(products.single.stockQuantity, 7);
    expect(sales, hasLength(1));
    expect(sales.single.quantity, 3);
    expect(sales.single.totalAmount, 7500);

    expect(movements, hasLength(1));
    expect(movements.single['movement_type'], 'sale');
    expect(movements.single['quantity_delta'], -3);
    expect(
      movements.single['product_sync_id'],
      saleRows.single['product_sync_id'],
    );
    expect(movements.single['source_sale_sync_id'], saleSyncId);
    expect(movements.single[DatabaseService.syncStatusColumn], 'pending');
    expect(
      (movements.single[DatabaseService.syncIdColumn] as String).isNotEmpty,
      isTrue,
    );
  });

  test('A sale cannot reduce stock below zero', () async {
    final productId = await createProduct(stock: 2);

    await expectLater(
      saleRepository.recordSale(
        sale: makeSale(productId: productId, quantity: 3),
      ),
      throwsA(isA<StateError>()),
    );

    final products = await productRepository.getProducts();
    final sales = await saleRepository.getSales();
    final db = await databaseService.database;
    final movements = await db.query(DatabaseService.inventoryMovementsTable);

    expect(products.single.stockQuantity, 2);
    expect(sales, isEmpty);
    expect(movements, isEmpty);
  });

  test('A sale with zero quantity is rejected', () async {
    final productId = await createProduct(stock: 10);

    await expectLater(
      saleRepository.recordSale(
        sale: makeSale(productId: productId, quantity: 0),
      ),
      throwsA(isA<ArgumentError>()),
    );

    final db = await databaseService.database;
    final movements = await db.query(DatabaseService.inventoryMovementsTable);

    expect(await saleRepository.getSales(), isEmpty);
    expect((await productRepository.getProducts()).single.stockQuantity, 10);
    expect(movements, isEmpty);
  });

  test('A sale for a missing product is rejected', () async {
    await expectLater(
      saleRepository.recordSale(sale: makeSale(productId: 999999)),
      throwsA(isA<StateError>()),
    );

    final db = await databaseService.database;
    final movements = await db.query(DatabaseService.inventoryMovementsTable);

    expect(await saleRepository.getSales(), isEmpty);
    expect(movements, isEmpty);
  });

  test('A recorded sale has stable synchronization identifiers', () async {
    final productId = await createProduct(stock: 10);

    await saleRepository.recordSale(sale: makeSale(productId: productId));

    final db = await databaseService.database;

    final rows = await db.query(DatabaseService.salesTable);

    expect(rows, hasLength(1));
    expect(rows.single[DatabaseService.syncIdColumn], isA<String>());
    expect(
      (rows.single[DatabaseService.syncIdColumn] as String).isNotEmpty,
      isTrue,
    );
    expect(rows.single[DatabaseService.syncStatusColumn], 'pending');
    expect(rows.single['product_sync_id'], isA<String>());
    expect((rows.single['product_sync_id'] as String).isNotEmpty, isTrue);
  });
  test(
    'Returning one resalable item restores stock and records the return',
    () async {
      final productId = await createProduct(stock: 10);
      final saleId = await saleRepository.recordSale(
        sale: makeSale(productId: productId, quantity: 2),
      );

      final db = await databaseService.database;
      final saleRows = await db.query(
        DatabaseService.salesTable,
        where: 'id = ?',
        whereArgs: [saleId],
      );
      final saleSyncId =
          saleRows.single[DatabaseService.syncIdColumn] as String;

      final returnId = await saleRepository.recordReturn(
        saleId: saleId,
        quantity: 1,
        restockedQuantity: 1,
        reason: 'Customer returned one unopened item',
        requestSyncId: 'test-return-request-001',
      );

      final products = await productRepository.getProducts();
      final sales = await saleRepository.getSales();
      final returns = await db.query(
        DatabaseService.salesReturnsTable,
        where: 'id = ?',
        whereArgs: [returnId],
      );
      final movements = await db.query(
        DatabaseService.inventoryMovementsTable,
        where: 'source_sale_sync_id = ? AND movement_type = ?',
        whereArgs: [saleSyncId, 'return'],
      );

      expect(products.single.stockQuantity, 9);
      expect(sales, hasLength(1));
      expect(sales.single.quantity, 2);
      expect(returns, hasLength(1));
      expect(returns.single['quantity'], 1);
      expect(returns.single['restocked_quantity'], 1);
      expect((returns.single['refund_amount'] as num).toDouble(), 2500);
      expect(movements, hasLength(1));
      expect(movements.single['quantity_delta'], 1);
    },
  );

  test(
    'Damaged returned item is refunded without restoring sellable stock',
    () async {
      final productId = await createProduct(stock: 10);
      final saleId = await saleRepository.recordSale(
        sale: makeSale(productId: productId, quantity: 2),
      );

      final db = await databaseService.database;
      final saleRows = await db.query(
        DatabaseService.salesTable,
        where: 'id = ?',
        whereArgs: [saleId],
      );
      final saleSyncId =
          saleRows.single[DatabaseService.syncIdColumn] as String;

      final returnId = await saleRepository.recordReturn(
        saleId: saleId,
        quantity: 1,
        restockedQuantity: 0,
        reason: 'Item returned damaged',
        requestSyncId: 'test-damaged-return-001',
      );

      final products = await productRepository.getProducts();
      final returns = await db.query(
        DatabaseService.salesReturnsTable,
        where: 'id = ?',
        whereArgs: [returnId],
      );
      final movements = await db.query(
        DatabaseService.inventoryMovementsTable,
        where: 'source_sale_sync_id = ? AND movement_type = ?',
        whereArgs: [saleSyncId, 'return'],
      );

      expect(products.single.stockQuantity, 8);
      expect(returns, hasLength(1));
      expect(returns.single['quantity'], 1);
      expect(returns.single['restocked_quantity'], 0);
      expect((returns.single['refund_amount'] as num).toDouble(), 2500);
      expect(movements, isEmpty);
    },
  );

  test(
    'Retrying the same return request does not restore stock twice',
    () async {
      final productId = await createProduct(stock: 10);
      final saleId = await saleRepository.recordSale(
        sale: makeSale(productId: productId, quantity: 2),
      );

      final db = await databaseService.database;
      final requestId = 'test-duplicate-return-001';

      final firstReturnId = await saleRepository.recordReturn(
        saleId: saleId,
        quantity: 1,
        restockedQuantity: 1,
        reason: 'Duplicate retry test',
        requestSyncId: requestId,
      );
      final retryReturnId = await saleRepository.recordReturn(
        saleId: saleId,
        quantity: 1,
        restockedQuantity: 1,
        reason: 'Duplicate retry test',
        requestSyncId: requestId,
      );

      final products = await productRepository.getProducts();
      final returns = await db.query(
        DatabaseService.salesReturnsTable,
        where: 'sync_id = ?',
        whereArgs: [requestId],
      );

      expect(retryReturnId, firstReturnId);
      expect(products.single.stockQuantity, 9);
      expect(returns, hasLength(1));
    },
  );

  test('Cancelling a sale restores stock and records the reason', () async {
    final productId = await createProduct(stock: 10);
    final saleId = await saleRepository.recordSale(
      sale: makeSale(productId: productId, quantity: 3),
    );

    final db = await databaseService.database;
    final saleRowsBefore = await db.query(
      DatabaseService.salesTable,
      where: 'id = ?',
      whereArgs: [saleId],
    );
    final saleSyncId =
        saleRowsBefore.single[DatabaseService.syncIdColumn] as String;

    await saleRepository.cancelSale(
      saleId: saleId,
      reason: 'Sale entered by mistake',
    );

    final products = await productRepository.getProducts();
    final saleRowsAfter = await db.query(
      DatabaseService.salesTable,
      where: 'id = ?',
      whereArgs: [saleId],
    );
    final movements = await db.query(
      DatabaseService.inventoryMovementsTable,
      where: 'source_sale_sync_id = ? AND movement_type = ?',
      whereArgs: [saleSyncId, 'cancellation'],
    );

    expect(products.single.stockQuantity, 10);
    expect(saleRowsAfter.single['status'], 'cancelled');
    expect(
      saleRowsAfter.single['cancellation_reason'],
      'Sale entered by mistake',
    );
    expect(saleRowsAfter.single['cancelled_at'], isNotNull);
    expect(saleRowsAfter.single[DatabaseService.syncStatusColumn], 'pending');
    expect(movements, hasLength(1));
    expect(movements.single['quantity_delta'], 3);
    expect(
      movements.single['note'],
      'Sale cancellation: Sale entered by mistake',
    );
  });

  test('Retrying the same cancellation does not restore stock twice', () async {
    final productId = await createProduct(stock: 10);
    final saleId = await saleRepository.recordSale(
      sale: makeSale(productId: productId, quantity: 2),
    );

    final db = await databaseService.database;

    await saleRepository.cancelSale(
      saleId: saleId,
      reason: 'Duplicate cancellation retry',
    );
    await saleRepository.cancelSale(
      saleId: saleId,
      reason: 'Duplicate cancellation retry',
    );

    final products = await productRepository.getProducts();
    final movements = await db.query(
      DatabaseService.inventoryMovementsTable,
      where: 'movement_type = ?',
      whereArgs: ['cancellation'],
    );

    expect(products.single.stockQuantity, 10);
    expect(movements, hasLength(1));
  });

  test('Cancelling a sale with an existing return is rejected', () async {
    final productId = await createProduct(stock: 10);
    final saleId = await saleRepository.recordSale(
      sale: makeSale(productId: productId, quantity: 2),
    );

    await saleRepository.recordReturn(
      saleId: saleId,
      quantity: 1,
      restockedQuantity: 1,
      reason: 'One item returned',
      requestSyncId: 'return-before-cancellation-test',
    );

    await expectLater(
      saleRepository.cancelSale(
        saleId: saleId,
        reason: 'Attempted cancellation after return',
      ),
      throwsA(isA<StateError>()),
    );

    final products = await productRepository.getProducts();
    final db = await databaseService.database;
    final saleRows = await db.query(
      DatabaseService.salesTable,
      where: 'id = ?',
      whereArgs: [saleId],
    );
    final movements = await db.query(
      DatabaseService.inventoryMovementsTable,
      where: 'movement_type = ?',
      whereArgs: ['cancellation'],
    );

    expect(products.single.stockQuantity, 9);
    expect(saleRows.single['status'], 'completed');
    expect(movements, isEmpty);
  });
}
