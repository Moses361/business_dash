
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
    temporaryDirectory =
        await Directory.systemTemp.createTemp('veroon_sale_test_');

    databaseService = DatabaseService(
      testDatabasePath: '${temporaryDirectory.path}/test.db',
    );

    productRepository = ProductRepository(
      databaseService: databaseService,
    );

    saleRepository = SaleRepository(
      databaseService: databaseService,
    );
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

  Sale makeSale({
    required int productId,
    int quantity = 2,
  }) {
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

  test('Recording a sale reduces stock and saves the sale', () async {
    final productId = await createProduct(stock: 10);

    final saleId = await saleRepository.recordSale(
      sale: makeSale(productId: productId, quantity: 3),
    );

    final products = await productRepository.getProducts();
    final sales = await saleRepository.getSales();

    expect(saleId, greaterThan(0));
    expect(products.single.stockQuantity, 7);
    expect(sales, hasLength(1));
    expect(sales.single.quantity, 3);
    expect(sales.single.totalAmount, 7500);
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

    expect(products.single.stockQuantity, 2);
    expect(sales, isEmpty);
  });

  test('A sale with zero quantity is rejected', () async {
    final productId = await createProduct(stock: 10);

    await expectLater(
      saleRepository.recordSale(
        sale: makeSale(productId: productId, quantity: 0),
      ),
      throwsA(isA<ArgumentError>()),
    );

    expect(await saleRepository.getSales(), isEmpty);
    expect(
      (await productRepository.getProducts()).single.stockQuantity,
      10,
    );
  });

  test('A sale for a missing product is rejected', () async {
    await expectLater(
      saleRepository.recordSale(
        sale: makeSale(productId: 999999),
      ),
      throwsA(isA<StateError>()),
    );

    expect(await saleRepository.getSales(), isEmpty);
  });

  test('A recorded sale has stable synchronization identifiers', () async {
    final productId = await createProduct(stock: 10);

    await saleRepository.recordSale(
      sale: makeSale(productId: productId),
    );

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
}
