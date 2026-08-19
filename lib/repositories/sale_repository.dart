import 'package:sqflite/sqflite.dart';

import '../database/database_service.dart';
import '../models/sale.dart';

class SaleRepository {
  final DatabaseService _databaseService;

  SaleRepository({DatabaseService? databaseService})
    : _databaseService = databaseService ?? DatabaseService();

  Future<int> recordSale({required Sale sale}) async {
    if (sale.quantity <= 0) {
      throw ArgumentError('Sale quantity must be greater than zero');
    }

    if (sale.sellingPrice < 0 || sale.buyingPrice < 0) {
      throw ArgumentError('Prices cannot be negative');
    }

    final Database database = await _databaseService.database;

    return database.transaction<int>((transaction) async {
      final int updatedRows = await transaction.rawUpdate(
        '''
        UPDATE ${DatabaseService.productsTable}
        SET stock_quantity = stock_quantity - ?
        WHERE id = ?
          AND stock_quantity >= ?
        ''',
        [sale.quantity, sale.productId, sale.quantity],
      );

      if (updatedRows == 0) {
        throw StateError('Insufficient stock or product not found');
      }

      return transaction.insert(DatabaseService.salesTable, {
        'product_id': sale.productId,
        'product_name': sale.productName,
        'quantity': sale.quantity,
        'buying_price': sale.buyingPrice,
        'selling_price': sale.sellingPrice,
        'total_amount': sale.totalAmount,
        'created_at': sale.createdAt.toIso8601String(),
      });
    });
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
    );
  }

  double _doubleValue(List<Map<String, dynamic>> result, String column) {
    if (result.isEmpty) {
      return 0.0;
    }

    return (result.first[column] as num?)?.toDouble() ?? 0.0;
  }
}
