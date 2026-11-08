import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import '../database/database_service.dart';
import '../models/sale.dart';
import '../models/checkout_models.dart';

class SaleRepository {
  final DatabaseService _databaseService;

  SaleRepository({DatabaseService? databaseService})
    : _databaseService = databaseService ?? DatabaseService();

  String get _nowUtc => DateTime.now().toUtc().toIso8601String();

  Future<int> recordSale({required Sale sale}) async {
    if (sale.quantity <= 0) {
      throw ArgumentError('Sale quantity must be greater than zero');
    }

    if (sale.sellingPrice < 0 || sale.buyingPrice < 0) {
      throw ArgumentError('Prices cannot be negative');
    }

    final Database database = await _databaseService.database;

    return database.transaction<int>((transaction) async {
      final now = _nowUtc;
      final saleSyncId = const Uuid().v4();
      final movementSyncId = const Uuid().v4();

      final productRows = await transaction.query(
        DatabaseService.productsTable,
        columns: [DatabaseService.syncIdColumn],
        where: 'id = ? AND ${DatabaseService.deletedAtColumn} IS NULL',
        whereArgs: [sale.productId],
        limit: 1,
      );

      if (productRows.isEmpty) {
        throw StateError('Product not found');
      }

      final productSyncId =
          productRows.first[DatabaseService.syncIdColumn] as String?;

      if (productSyncId == null || productSyncId.isEmpty) {
        throw StateError('Product synchronization ID is missing');
      }

      final int updatedRows = await transaction.rawUpdate(
        '''
        UPDATE ${DatabaseService.productsTable}
        SET stock_quantity = stock_quantity - ?,
            ${DatabaseService.syncStatusColumn} = 'pending',
            ${DatabaseService.updatedAtColumn} = ?
        WHERE id = ?
          AND stock_quantity >= ?
          AND ${DatabaseService.deletedAtColumn} IS NULL
        ''',
        [sale.quantity, now, sale.productId, sale.quantity],
      );

      if (updatedRows == 0) {
        throw StateError('Insufficient stock or product not found');
      }

      final saleId = await transaction.insert(DatabaseService.salesTable, {
        'product_id': sale.productId,
        'product_sync_id': productSyncId,
        'product_name': sale.productName,
        'quantity': sale.quantity,
        'buying_price': sale.buyingPrice,
        'selling_price': sale.sellingPrice,
        'total_amount': sale.totalAmount,
        'created_at': sale.createdAt.toIso8601String(),
        DatabaseService.syncIdColumn: saleSyncId,
        DatabaseService.syncStatusColumn: 'pending',
        DatabaseService.updatedAtColumn: now,
        DatabaseService.deletedAtColumn: null,
      });

      await transaction.insert(DatabaseService.inventoryMovementsTable, {
        'sync_id': movementSyncId,
        'product_sync_id': productSyncId,
        'movement_type': 'sale',
        'quantity_delta': -sale.quantity,
        'source_sale_sync_id': saleSyncId,
        'note': 'Stock deducted for sale',
        'created_at': now,
        DatabaseService.syncStatusColumn: 'pending',
        DatabaseService.updatedAtColumn: now,
        DatabaseService.deletedAtColumn: null,
      });

      return saleId;
    });
  }

  Future<CheckoutResult> checkout({
    required List<CheckoutCartItem> items,
    List<CheckoutPaymentInput> payments = const [],
  }) async {
    if (items.isEmpty) {
      throw ArgumentError('The cart cannot be empty');
    }

    final seenProductIds = <int>{};
    for (final item in items) {
      if (item.productId <= 0 || item.quantity <= 0) {
        throw ArgumentError('Each product must have a valid ID and quantity');
      }
      if (!seenProductIds.add(item.productId)) {
        throw ArgumentError('A product appears more than once in the cart');
      }
    }

    int toCents(double amount) {
      if (!amount.isFinite || amount < 0) {
        throw ArgumentError('Amounts must be finite and non-negative');
      }
      return (amount * 100).round();
    }

    for (final payment in payments) {
      final cents = toCents(payment.amount);
      if (cents <= 0) {
        throw ArgumentError('Payment amounts must be greater than zero');
      }
    }

    final paidCents = payments.fold<int>(
      0,
      (sum, payment) => sum + toCents(payment.amount),
    );

    final Database database = await _databaseService.database;

    return database.transaction<CheckoutResult>((transaction) async {
      final now = _nowUtc;
      const uuid = Uuid();
      final orderSyncId = uuid.v4();

      final cartLines = <Map<String, Object?>>[];
      var totalCents = 0;

      for (final item in items) {
        final rows = await transaction.query(
          DatabaseService.productsTable,
          columns: [
            'id',
            'name',
            'buying_price',
            'selling_price',
            'stock_quantity',
            DatabaseService.syncIdColumn,
          ],
          where: 'id = ? AND ${DatabaseService.deletedAtColumn} IS NULL',
          whereArgs: [item.productId],
          limit: 1,
        );

        if (rows.isEmpty) {
          throw StateError('Product ${item.productId} was not found');
        }

        final product = rows.first;
        final productSyncId = product[DatabaseService.syncIdColumn] as String?;
        if (productSyncId == null || productSyncId.isEmpty) {
          throw StateError('Product synchronization ID is missing');
        }

        final buyingPrice = (product['buying_price'] as num).toDouble();
        final sellingPrice = (product['selling_price'] as num).toDouble();
        final stockQuantity = (product['stock_quantity'] as num).toInt();

        if (!buyingPrice.isFinite ||
            !sellingPrice.isFinite ||
            buyingPrice < 0 ||
            sellingPrice < 0) {
          throw StateError('Product prices are invalid');
        }
        if (stockQuantity < item.quantity) {
          throw StateError(
            'Insufficient stock for ${product['name']}. Available: $stockQuantity',
          );
        }

        final unitCents = toCents(sellingPrice);
        final lineCents = unitCents * item.quantity;
        totalCents += lineCents;

        cartLines.add({
          'product_id': item.productId,
          'product_sync_id': productSyncId,
          'product_name': product['name'] as String,
          'quantity': item.quantity,
          'buying_price': buyingPrice,
          'selling_price': sellingPrice,
          'total_amount': lineCents / 100.0,
          'line_cents': lineCents,
        });
      }

      if (paidCents != totalCents) {
        throw ArgumentError(
          'Full payment is required before completing a sale',
        );
      }

      final orderId = await transaction.insert(
        DatabaseService.saleOrdersTable,
        {
          DatabaseService.syncIdColumn: orderSyncId,
          'total_amount': totalCents / 100.0,
          'status': 'completed',
          'created_at': now,
          DatabaseService.syncStatusColumn: 'pending',
          DatabaseService.updatedAtColumn: now,
          DatabaseService.deletedAtColumn: null,
        },
      );

      final saleIds = <int>[];

      for (final line in cartLines) {
        final productId = line['product_id'] as int;
        final quantity = line['quantity'] as int;
        final productSyncId = line['product_sync_id'] as String;
        final saleSyncId = uuid.v4();
        final movementSyncId = uuid.v4();

        final updatedRows = await transaction.rawUpdate(
          '''
          UPDATE ${DatabaseService.productsTable}
          SET stock_quantity = stock_quantity - ?,
              ${DatabaseService.syncStatusColumn} = 'pending',
              ${DatabaseService.updatedAtColumn} = ?
          WHERE id = ?
            AND stock_quantity >= ?
            AND ${DatabaseService.deletedAtColumn} IS NULL
          ''',
          [quantity, now, productId, quantity],
        );

        if (updatedRows != 1) {
          throw StateError(
            'Stock changed during checkout. Please review the cart and try again.',
          );
        }

        final saleId = await transaction.insert(DatabaseService.salesTable, {
          'product_id': productId,
          'product_sync_id': productSyncId,
          'order_sync_id': orderSyncId,
          'product_name': line['product_name'],
          'quantity': quantity,
          'buying_price': line['buying_price'],
          'selling_price': line['selling_price'],
          'total_amount': line['total_amount'],
          'created_at': now,
          DatabaseService.syncIdColumn: saleSyncId,
          DatabaseService.syncStatusColumn: 'pending',
          DatabaseService.updatedAtColumn: now,
          DatabaseService.deletedAtColumn: null,
        });

        await transaction.insert(DatabaseService.inventoryMovementsTable, {
          'sync_id': movementSyncId,
          'product_sync_id': productSyncId,
          'movement_type': 'sale',
          'quantity_delta': -quantity,
          'source_sale_sync_id': saleSyncId,
          'note': 'Stock deducted for order $orderSyncId',
          'created_at': now,
          DatabaseService.syncStatusColumn: 'pending',
          DatabaseService.updatedAtColumn: now,
          DatabaseService.deletedAtColumn: null,
        });

        saleIds.add(saleId);
      }

      for (final payment in payments) {
        await transaction.insert(DatabaseService.salePaymentsTable, {
          DatabaseService.syncIdColumn: uuid.v4(),
          'order_sync_id': orderSyncId,
          'payment_method': payment.method.name,
          'amount': toCents(payment.amount) / 100.0,
          'reference': payment.reference?.trim().isEmpty ?? true
              ? null
              : payment.reference!.trim(),
          'note': payment.note?.trim().isEmpty ?? true
              ? null
              : payment.note!.trim(),
          'created_at': now,
          DatabaseService.syncStatusColumn: 'pending',
          DatabaseService.updatedAtColumn: now,
          DatabaseService.deletedAtColumn: null,
        });
      }

      return CheckoutResult(
        orderId: orderId,
        orderSyncId: orderSyncId,
        totalAmount: totalCents / 100.0,
        amountPaid: paidCents / 100.0,
        balanceDue: (totalCents - paidCents) / 100.0,
        saleIds: saleIds,
      );
    });
  }

  Future<Map<String, Object?>?> getOrderDetails(String orderSyncId) async {
    final Database database = await _databaseService.database;

    final orderRows = await database.query(
      DatabaseService.saleOrdersTable,
      where: 'sync_id = ? AND ${DatabaseService.deletedAtColumn} IS NULL',
      whereArgs: [orderSyncId],
      limit: 1,
    );

    if (orderRows.isEmpty) return null;

    final salesRows = await database.query(
      DatabaseService.salesTable,
      where: 'order_sync_id = ? AND ${DatabaseService.deletedAtColumn} IS NULL',
      whereArgs: [orderSyncId],
      orderBy: 'id ASC',
    );

    final paymentRows = await database.query(
      DatabaseService.salePaymentsTable,
      where: 'order_sync_id = ? AND ${DatabaseService.deletedAtColumn} IS NULL',
      whereArgs: [orderSyncId],
      orderBy: 'id ASC',
    );

    return {
      'order': orderRows.first,
      'sales': salesRows,
      'payments': paymentRows,
    };
  }

  Future<List<Sale>> getSales() async {
    final Database database = await _databaseService.database;

    final rows = await database.query(
      DatabaseService.salesTable,
      orderBy: 'created_at DESC, id DESC',
    );

    return rows.map(_saleFromRow).toList();
  }

  Future<List<Sale>> getSalesBetween(DateTime start, DateTime end) async {
    final Database database = await _databaseService.database;

    final rows = await database.query(
      DatabaseService.salesTable,
      where: 'created_at >= ? AND created_at < ?',
      whereArgs: [start.toIso8601String(), end.toIso8601String()],
      orderBy: 'created_at ASC, id ASC',
    );

    return rows.map(_saleFromRow).toList();
  }

  Future<double> getTotalSales() async {
    final Database database = await _databaseService.database;

    final result = await database.rawQuery('''
      SELECT COALESCE(SUM(total_amount), 0) AS total
      FROM ${DatabaseService.salesTable}
    ''');

    return _doubleValue(result, 'total');
  }

  Future<double> getTodaySales() async {
    final now = DateTime.now();

    return getSalesTotalBetween(
      DateTime(now.year, now.month, now.day),
      DateTime(now.year, now.month, now.day).add(const Duration(days: 1)),
    );
  }

  Future<double> getSalesTotalBetween(DateTime start, DateTime end) async {
    final Database database = await _databaseService.database;

    final result = await database.rawQuery(
      '''
      SELECT COALESCE(SUM(total_amount), 0) AS total
      FROM ${DatabaseService.salesTable}
      WHERE created_at >= ? AND created_at < ?
      ''',
      [start.toIso8601String(), end.toIso8601String()],
    );

    return _doubleValue(result, 'total');
  }

  Future<double> getTotalProfit() async {
    final Database database = await _databaseService.database;

    final result = await database.rawQuery('''
      SELECT COALESCE(
        SUM((selling_price - buying_price) * quantity),
        0
      ) AS profit
      FROM ${DatabaseService.salesTable}
    ''');

    return _doubleValue(result, 'profit');
  }

  Future<double> getTodayProfit() async {
    final now = DateTime.now();

    return getProfitBetween(
      DateTime(now.year, now.month, now.day),
      DateTime(now.year, now.month, now.day).add(const Duration(days: 1)),
    );
  }

  Future<double> getProfitBetween(DateTime start, DateTime end) async {
    final Database database = await _databaseService.database;

    final result = await database.rawQuery(
      '''
      SELECT COALESCE(
        SUM((selling_price - buying_price) * quantity),
        0
      ) AS profit
      FROM ${DatabaseService.salesTable}
      WHERE created_at >= ? AND created_at < ?
      ''',
      [start.toIso8601String(), end.toIso8601String()],
    );

    return _doubleValue(result, 'profit');
  }

  Future<double> getTotalCostOfGoodsSold() async {
    final Database database = await _databaseService.database;

    final result = await database.rawQuery('''
      SELECT COALESCE(
        SUM(buying_price * quantity),
        0
      ) AS cost
      FROM ${DatabaseService.salesTable}
    ''');

    return _doubleValue(result, 'cost');
  }

  Future<double> getCostOfGoodsSoldBetween(DateTime start, DateTime end) async {
    final Database database = await _databaseService.database;

    final result = await database.rawQuery(
      '''
      SELECT COALESCE(
        SUM(buying_price * quantity),
        0
      ) AS cost
      FROM ${DatabaseService.salesTable}
      WHERE created_at >= ? AND created_at < ?
      ''',
      [start.toIso8601String(), end.toIso8601String()],
    );

    return _doubleValue(result, 'cost');
  }

  Future<int> getSaleCount() async {
    final Database database = await _databaseService.database;

    final result = await database.rawQuery('''
      SELECT COUNT(*) AS count
      FROM ${DatabaseService.salesTable}
    ''');

    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<int> getSaleCountBetween(DateTime start, DateTime end) async {
    final Database database = await _databaseService.database;

    final result = await database.rawQuery(
      '''
      SELECT COUNT(*) AS count
      FROM ${DatabaseService.salesTable}
      WHERE created_at >= ? AND created_at < ?
      ''',
      [start.toIso8601String(), end.toIso8601String()],
    );

    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<List<Map<String, dynamic>>> getDailySales(
    DateTime start,
    DateTime end,
  ) async {
    final Database database = await _databaseService.database;

    return database.rawQuery(
      '''
      SELECT
        substr(created_at, 1, 10) AS date,
        COALESCE(SUM(total_amount), 0) AS sales,
        COALESCE(
          SUM((selling_price - buying_price) * quantity),
          0
        ) AS profit,
        COALESCE(SUM(quantity), 0) AS quantity
      FROM ${DatabaseService.salesTable}
      WHERE created_at >= ? AND created_at < ?
      GROUP BY substr(created_at, 1, 10)
      ORDER BY date ASC
      ''',
      [start.toIso8601String(), end.toIso8601String()],
    );
  }

  Future<List<Map<String, dynamic>>> getTopSellingProducts({
    DateTime? start,
    DateTime? end,
    int limit = 10,
  }) async {
    final Database database = await _databaseService.database;

    final whereParts = <String>[];
    final whereArgs = <dynamic>[];

    if (start != null) {
      whereParts.add('created_at >= ?');
      whereArgs.add(start.toIso8601String());
    }

    if (end != null) {
      whereParts.add('created_at < ?');
      whereArgs.add(end.toIso8601String());
    }

    final whereClause = whereParts.isEmpty
        ? ''
        : 'WHERE ${whereParts.join(' AND ')}';

    return database.rawQuery(
      '''
      SELECT
        product_id,
        product_name,
        SUM(quantity) AS quantity,
        SUM(total_amount) AS sales,
        SUM((selling_price - buying_price) * quantity) AS profit
      FROM ${DatabaseService.salesTable}
      $whereClause
      GROUP BY product_id, product_name
      ORDER BY quantity DESC
      LIMIT ?
      ''',
      [...whereArgs, limit],
    );
  }

  Future<List<Map<String, dynamic>>> getSalesByCategory({
    DateTime? start,
    DateTime? end,
  }) async {
    final Database database = await _databaseService.database;

    final whereParts = <String>[];
    final whereArgs = <dynamic>[];

    if (start != null) {
      whereParts.add('s.created_at >= ?');
      whereArgs.add(start.toIso8601String());
    }

    if (end != null) {
      whereParts.add('s.created_at < ?');
      whereArgs.add(end.toIso8601String());
    }

    final whereClause = whereParts.isEmpty
        ? ''
        : 'WHERE ${whereParts.join(' AND ')}';

    return database.rawQuery('''
      SELECT
        p.category AS category,
        COALESCE(SUM(s.quantity), 0) AS quantity,
        COALESCE(SUM(s.total_amount), 0) AS sales,
        COALESCE(
          SUM((s.selling_price - s.buying_price) * s.quantity),
          0
        ) AS profit
      FROM ${DatabaseService.salesTable} s
      INNER JOIN ${DatabaseService.productsTable} p
        ON p.id = s.product_id
      $whereClause
      GROUP BY p.category
      ORDER BY sales DESC
      ''', whereArgs);
  }

  /// Cancels a standalone sale or the entire checkout order it belongs to.
  /// Stock restoration, audit updates, and cancellation movements are atomic.
  Future<void> cancelSale({required int saleId, required String reason}) async {
    final trimmedReason = reason.trim();
    if (trimmedReason.isEmpty) {
      throw ArgumentError('A cancellation reason is required');
    }

    final database = await _databaseService.database;

    await database.transaction<void>((transaction) async {
      final now = _nowUtc;
      final selectedRows = await transaction.query(
        DatabaseService.salesTable,
        where: 'id = ? AND ${DatabaseService.deletedAtColumn} IS NULL',
        whereArgs: [saleId],
        limit: 1,
      );

      if (selectedRows.isEmpty) {
        throw StateError('Sale not found');
      }

      final selected = selectedRows.first;
      final orderSyncId = selected['order_sync_id'] as String?;
      final isOrderSale = orderSyncId != null && orderSyncId.isNotEmpty;

      final affectedSales = isOrderSale
          ? await transaction.query(
              DatabaseService.salesTable,
              where:
                  'order_sync_id = ? AND ${DatabaseService.deletedAtColumn} IS NULL',
              whereArgs: [orderSyncId],
              orderBy: 'id ASC',
            )
          : [selected];

      if (affectedSales.isEmpty) {
        throw StateError('No sale records were found for cancellation');
      }

      final allAlreadyCancelled = affectedSales.every(
        (sale) => sale['status'] == 'cancelled',
      );
      if (allAlreadyCancelled) {
        final sameReason = affectedSales.every(
          (sale) => sale['cancellation_reason'] == trimmedReason,
        );
        if (sameReason) {
          return;
        }
        throw StateError('This sale has already been cancelled');
      }

      if (affectedSales.any((sale) => sale['status'] == 'cancelled')) {
        throw StateError('The sale or order is only partially cancelled');
      }

      // Do not reverse a sale that already has a return: that could restore
      // stock twice or make the inventory and financial audit inconsistent.
      for (final sale in affectedSales) {
        final saleSyncId = sale[DatabaseService.syncIdColumn] as String?;
        if (saleSyncId == null || saleSyncId.isEmpty) {
          throw StateError('Sale synchronization ID is missing');
        }

        final returnRows = await transaction.query(
          DatabaseService.salesReturnsTable,
          columns: ['id'],
          where:
              'sale_sync_id = ? AND ${DatabaseService.deletedAtColumn} IS NULL',
          whereArgs: [saleSyncId],
          limit: 1,
        );
        if (returnRows.isNotEmpty) {
          throw StateError(
            'This sale has a customer return. Process the return separately; cancellation is not allowed.',
          );
        }
      }

      for (final sale in affectedSales) {
        final productId = sale['product_id'] as int;
        final quantity = sale['quantity'] as int;
        final productSyncId = sale['product_sync_id'] as String?;
        final saleSyncId = sale[DatabaseService.syncIdColumn] as String?;

        if (quantity <= 0 ||
            productSyncId == null ||
            productSyncId.isEmpty ||
            saleSyncId == null ||
            saleSyncId.isEmpty) {
          throw StateError('Sale or product data is incomplete');
        }

        final updatedProducts = await transaction.rawUpdate(
          '''
          UPDATE ${DatabaseService.productsTable}
          SET stock_quantity = stock_quantity + ?,
              ${DatabaseService.syncStatusColumn} = 'pending',
              ${DatabaseService.updatedAtColumn} = ?
          WHERE id = ?
            AND ${DatabaseService.syncIdColumn} = ?
            AND ${DatabaseService.deletedAtColumn} IS NULL
          ''',
          [quantity, now, productId, productSyncId],
        );

        if (updatedProducts != 1) {
          throw StateError(
            'Product not found; cancellation stock restoration was stopped',
          );
        }

        await transaction.insert(DatabaseService.inventoryMovementsTable, {
          'sync_id': const Uuid().v4(),
          'product_sync_id': productSyncId,
          'movement_type': 'cancellation',
          'quantity_delta': quantity,
          'source_sale_sync_id': saleSyncId,
          'note': 'Sale cancellation: $trimmedReason',
          'created_at': now,
          DatabaseService.syncStatusColumn: 'pending',
          DatabaseService.updatedAtColumn: now,
          DatabaseService.deletedAtColumn: null,
        }, conflictAlgorithm: ConflictAlgorithm.abort);

        final updatedSales = await transaction.update(
          DatabaseService.salesTable,
          {
            'status': 'cancelled',
            'cancellation_reason': trimmedReason,
            'cancelled_at': now,
            DatabaseService.syncStatusColumn: 'pending',
            DatabaseService.updatedAtColumn: now,
          },
          where: 'id = ? AND status = ?',
          whereArgs: [sale['id'], 'completed'],
        );

        if (updatedSales != 1) {
          throw StateError(
            'Sale status changed during cancellation; no changes were saved',
          );
        }
      }

      if (isOrderSale) {
        final updatedOrders = await transaction.update(
          DatabaseService.saleOrdersTable,
          {
            'status': 'cancelled',
            'cancellation_reason': trimmedReason,
            'cancelled_at': now,
            DatabaseService.syncStatusColumn: 'pending',
            DatabaseService.updatedAtColumn: now,
          },
          where: 'sync_id = ? AND status = ?',
          whereArgs: [orderSyncId, 'completed'],
        );

        if (updatedOrders != 1) {
          throw StateError(
            'Order status changed during cancellation; no changes were saved',
          );
        }
      }
    });
  }

  Sale _saleFromRow(Map<String, dynamic> row) {
    return Sale(
      id: row['id'] as int,
      productId: row['product_id'] as int,
      productName: row['product_name'] as String,
      quantity: row['quantity'] as int,
      buyingPrice: (row['buying_price'] as num?)?.toDouble() ?? 0.0,
      sellingPrice: (row['selling_price'] as num).toDouble(),
      totalAmount: (row['total_amount'] as num).toDouble(),
      createdAt: DateTime.parse(row['created_at'] as String),
      orderSyncId: row['order_sync_id'] as String?,
    );
  }

  double _doubleValue(List<Map<String, dynamic>> result, String column) {
    if (result.isEmpty) {
      return 0.0;
    }

    return (result.first[column] as num?)?.toDouble() ?? 0.0;
  }

  /// Records a full or partial customer return atomically.
  ///
  /// [restockedQuantity] is the portion of the returned quantity that is
  /// suitable for resale. Damaged items can be refunded without restocking.
  /// Pass the same [requestSyncId] when retrying a request.
  Future<int> recordReturn({
    required int saleId,
    required int quantity,
    required int restockedQuantity,
    required String reason,
    String? requestSyncId,
  }) async {
    if (quantity <= 0) {
      throw ArgumentError('Return quantity must be greater than zero');
    }
    if (restockedQuantity < 0 || restockedQuantity > quantity) {
      throw ArgumentError(
        'Restocked quantity must be between zero and return quantity',
      );
    }
    if (reason.trim().isEmpty) {
      throw ArgumentError('A return reason is required');
    }
    if (requestSyncId != null && requestSyncId.trim().isEmpty) {
      throw ArgumentError('Request synchronization ID cannot be empty');
    }

    final database = await _databaseService.database;

    return database.transaction<int>((transaction) async {
      final now = _nowUtc;
      final returnSyncId = requestSyncId ?? const Uuid().v4();

      // An identical retry returns the existing record without changing stock.
      final existingReturns = await transaction.query(
        DatabaseService.salesReturnsTable,
        where: 'sync_id = ?',
        whereArgs: [returnSyncId],
        limit: 1,
      );

      if (existingReturns.isNotEmpty) {
        final existing = existingReturns.first;
        final saleRows = await transaction.query(
          DatabaseService.salesTable,
          columns: [DatabaseService.syncIdColumn],
          where: 'id = ?',
          whereArgs: [saleId],
          limit: 1,
        );

        if (saleRows.isNotEmpty &&
            existing['sale_sync_id'] == saleRows.first['sync_id'] &&
            existing['quantity'] == quantity &&
            existing['restocked_quantity'] == restockedQuantity &&
            existing['reason'] == reason.trim()) {
          return existing['id'] as int;
        }

        throw StateError(
          'This return request ID has already been used for another request',
        );
      }

      final saleRows = await transaction.query(
        DatabaseService.salesTable,
        where: 'id = ? AND ${DatabaseService.deletedAtColumn} IS NULL',
        whereArgs: [saleId],
        limit: 1,
      );

      if (saleRows.isEmpty) {
        throw StateError('Sale not found');
      }

      final sale = saleRows.first;
      final saleSyncId = sale[DatabaseService.syncIdColumn] as String?;
      final productSyncId = sale['product_sync_id'] as String?;
      final productId = sale['product_id'] as int;
      final saleQuantity = sale['quantity'] as int;

      if (saleSyncId == null || saleSyncId.isEmpty) {
        throw StateError('Sale synchronization ID is missing');
      }
      if (productSyncId == null || productSyncId.isEmpty) {
        throw StateError('Sale product synchronization ID is missing');
      }

      final priorReturns = await transaction.rawQuery(
        '''
        SELECT COALESCE(SUM(quantity), 0) AS returned_quantity
        FROM ${DatabaseService.salesReturnsTable}
        WHERE sale_sync_id = ?
          AND ${DatabaseService.deletedAtColumn} IS NULL
        ''',
        [saleSyncId],
      );

      final returnedQuantity = (priorReturns.first['returned_quantity'] as num)
          .toInt();

      if (quantity > saleQuantity - returnedQuantity) {
        throw StateError(
          'Return quantity exceeds the remaining returnable quantity',
        );
      }

      final originalAmount = (sale['total_amount'] as num).toDouble();
      final buyingPrice = (sale['buying_price'] as num).toDouble();
      final sellingPrice = (sale['selling_price'] as num).toDouble();
      final refundAmount = originalAmount * quantity / saleQuantity;

      if (restockedQuantity > 0) {
        final updatedRows = await transaction.rawUpdate(
          '''
          UPDATE ${DatabaseService.productsTable}
          SET stock_quantity = stock_quantity + ?,
              ${DatabaseService.syncStatusColumn} = 'pending',
              ${DatabaseService.updatedAtColumn} = ?
          WHERE id = ?
            AND ${DatabaseService.deletedAtColumn} IS NULL
            AND ${DatabaseService.syncIdColumn} = ?
          ''',
          [restockedQuantity, now, productId, productSyncId],
        );

        if (updatedRows == 0) {
          throw StateError('Product not found; stock was not restored');
        }
      }

      final returnId = await transaction.insert(
        DatabaseService.salesReturnsTable,
        {
          'sync_id': returnSyncId,
          'sale_sync_id': saleSyncId,
          'product_id': productId,
          'product_sync_id': productSyncId,
          'product_name': sale['product_name'],
          'quantity': quantity,
          'restocked_quantity': restockedQuantity,
          'refund_amount': refundAmount,
          'buying_price': buyingPrice,
          'selling_price': sellingPrice,
          'reason': reason.trim(),
          'created_at': now,
          DatabaseService.syncStatusColumn: 'pending',
          DatabaseService.updatedAtColumn: now,
          DatabaseService.deletedAtColumn: null,
        },
        conflictAlgorithm: ConflictAlgorithm.abort,
      );

      if (restockedQuantity > 0) {
        await transaction.insert(DatabaseService.inventoryMovementsTable, {
          'sync_id': const Uuid().v4(),
          'product_sync_id': productSyncId,
          'movement_type': 'return',
          'quantity_delta': restockedQuantity,
          'source_sale_sync_id': saleSyncId,
          'note': 'Customer return: ${reason.trim()}',
          'created_at': now,
          DatabaseService.syncStatusColumn: 'pending',
          DatabaseService.updatedAtColumn: now,
          DatabaseService.deletedAtColumn: null,
        }, conflictAlgorithm: ConflictAlgorithm.abort);
      }

      return returnId;
    });
  }
}
