import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:business_dash/database/database_service.dart';
import 'package:business_dash/models/checkout_models.dart';
import 'package:business_dash/models/product.dart';
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
      'veroon_checkout_test_',
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

  Future<int> createProduct({
    required String name,
    required double buyingPrice,
    required double sellingPrice,
    int stock = 10,
  }) {
    return productRepository.insertProduct(
      Product(
        name: name,
        category: 'Test',
        buyingPrice: buyingPrice,
        sellingPrice: sellingPrice,
        stockQuantity: stock,
      ),
    );
  }

  test('Checkout supports multiple products and split payments', () async {
    final firstId = await createProduct(
      name: 'Product A',
      buyingPrice: 100,
      sellingPrice: 200,
      stock: 5,
    );
    final secondId = await createProduct(
      name: 'Product B',
      buyingPrice: 300,
      sellingPrice: 500,
      stock: 4,
    );

    final result = await saleRepository.checkout(
      items: [
        CheckoutCartItem(productId: firstId, quantity: 2),
        CheckoutCartItem(productId: secondId, quantity: 1),
      ],
      payments: const [
        CheckoutPaymentInput(
          method: CheckoutPaymentMethod.mpesa,
          amount: 300,
          reference: 'MANUAL-REF-1',
        ),
        CheckoutPaymentInput(method: CheckoutPaymentMethod.cash, amount: 600),
      ],
    );

    final db = await databaseService.database;
    final orders = await db.query(DatabaseService.saleOrdersTable);
    final payments = await db.query(DatabaseService.salePaymentsTable);
    final sales = await db.query(
      DatabaseService.salesTable,
      where: 'order_sync_id = ?',
      whereArgs: [result.orderSyncId],
    );
    final products = await productRepository.getProducts();

    expect(result.totalAmount, 900);
    expect(result.amountPaid, 900);
    expect(result.balanceDue, 0);
    expect(result.saleIds, hasLength(2));
    expect(orders, hasLength(1));
    expect(orders.single['total_amount'], 900);
    expect(payments, hasLength(2));
    expect(sales, hasLength(2));
    expect(products.firstWhere((p) => p.id == firstId).stockQuantity, 3);
    expect(products.firstWhere((p) => p.id == secondId).stockQuantity, 3);

    expect(payments.map((p) => p['payment_method']).toSet(), {'cash', 'mpesa'});

    final movements = await db.query(DatabaseService.inventoryMovementsTable);
    expect(movements, hasLength(2));
  });

  test("Checkout rejects partial and unpaid sales without changing stock or records", () async {
    final productId = await createProduct(
      name: "Product A",
      buyingPrice: 100,
      sellingPrice: 500,
      stock: 3,
    );

    await expectLater(
      saleRepository.checkout(
        items: [CheckoutCartItem(productId: productId, quantity: 1)],
        payments: const [
          CheckoutPaymentInput(method: CheckoutPaymentMethod.cash, amount: 200),
        ],
      ),
      throwsA(isA<ArgumentError>()),
    );

    await expectLater(
      saleRepository.checkout(
        items: [CheckoutCartItem(productId: productId, quantity: 1)],
      ),
      throwsA(isA<ArgumentError>()),
    );

    final db = await databaseService.database;
    final products = await productRepository.getProducts();

    expect(products.single.stockQuantity, 3);
    expect(await db.query(DatabaseService.saleOrdersTable), isEmpty);
    expect(await db.query(DatabaseService.salesTable), isEmpty);
    expect(await db.query(DatabaseService.salePaymentsTable), isEmpty);
    expect(await db.query(DatabaseService.inventoryMovementsTable), isEmpty);
  });

  test(
    'Checkout rejects overpayment without changing stock or records',
    () async {
      final productId = await createProduct(
        name: 'Product A',
        buyingPrice: 100,
        sellingPrice: 500,
        stock: 3,
      );

      await expectLater(
        saleRepository.checkout(
          items: [CheckoutCartItem(productId: productId, quantity: 1)],
          payments: const [
            CheckoutPaymentInput(
              method: CheckoutPaymentMethod.cash,
              amount: 600,
            ),
          ],
        ),
        throwsA(isA<ArgumentError>()),
      );

      final db = await databaseService.database;
      final products = await productRepository.getProducts();

      expect(products.single.stockQuantity, 3);
      expect(await db.query(DatabaseService.saleOrdersTable), isEmpty);
      expect(await db.query(DatabaseService.salesTable), isEmpty);
      expect(await db.query(DatabaseService.salePaymentsTable), isEmpty);
      expect(await db.query(DatabaseService.inventoryMovementsTable), isEmpty);
    },
  );

  test('Insufficient stock rejects checkout without partial records', () async {
    final firstId = await createProduct(
      name: 'Available Product',
      buyingPrice: 100,
      sellingPrice: 200,
      stock: 5,
    );
    final secondId = await createProduct(
      name: 'Low Stock Product',
      buyingPrice: 100,
      sellingPrice: 300,
      stock: 1,
    );

    await expectLater(
      saleRepository.checkout(
        items: [
          CheckoutCartItem(productId: firstId, quantity: 2),
          CheckoutCartItem(productId: secondId, quantity: 2),
        ],
      ),
      throwsA(isA<StateError>()),
    );

    final db = await databaseService.database;
    final products = await productRepository.getProducts();

    expect(products.firstWhere((p) => p.id == firstId).stockQuantity, 5);
    expect(products.firstWhere((p) => p.id == secondId).stockQuantity, 1);
    expect(await db.query(DatabaseService.saleOrdersTable), isEmpty);
    expect(await db.query(DatabaseService.salesTable), isEmpty);
    expect(await db.query(DatabaseService.salePaymentsTable), isEmpty);
    expect(await db.query(DatabaseService.inventoryMovementsTable), isEmpty);
  });
}
