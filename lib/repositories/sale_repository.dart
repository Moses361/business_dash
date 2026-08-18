import 'package:sqflite/sqflite.dart';

import '../database/database_service.dart';
import '../models/sale.dart';

class SaleRepository {
  final DatabaseService _databaseService;

  SaleRepository({DatabaseService? databaseService})
      : _databaseService = databaseService ?? DatabaseService();

  Future<int> insertSale(Sale sale) async {
    final Database database = await _databaseService.database;

    return database.insert(DatabaseService.salesTable, {
      'product_id': sale.productId,
      'product_name': sale.productName,
      'quantity': sale.quantity,
      'buying_price': sale.buyingPrice,
      'selling_price': sale.sellingPrice,
      'total_amount': sale.totalAmount,
      'created_at': sale.createdAt.toIso8601String(),
    });
  }

  Future<int> recordSale({required Sale sale}) async {
    if (sale.quantity <= 0) {
      throw ArgumentError('Sale quantity must be greater than zero');
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
        [
          sale.quantity,
          sale.productId,
          sale.quantity,
        ],
      );

      if (updatedRows == 0) {
        throw StateError('Insufficient stock or product not found');
      }

      return transaction.insert(
        DatabaseService.salesTable,
        {
          'product_id': sale.productId,
          'product_name': sale.productName,
          'quantity': sale.quantity,
          'buying_price': sale.buyingPrice,
          'selling_price': sale.sellingPrice,
          'total_amount': sale.totalAmount,
          'created_at': sale.createdAt.toIso8601String(),
        },
      );
    });
  }

  Future<List<Sale>> getSales() async {
    final Database database = await _databaseService.database;

    final List<Map<String, dynamic>> rows = await database.query(
      DatabaseService.salesTable,
      orderBy: 'id DESC',
    );

    return rows.map<Sale>((row) {
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
    }).toList();
  }

  Future<double> getTotalSales() async {
    final Database database = await _databaseService.database;

    final result = await database.rawQuery(
      '''
      SELECT COALESCE(SUM(total_amount), 0) AS total
      FROM ${DatabaseService.salesTable}
      ''',
    );

    final total = result.first['total'];
    return (total as num?)?.toDouble() ?? 0.0;
  }

  Future<double> getTodaySales() async {
    final Database database = await _databaseService.database;

    final today = DateTime.now().toIso8601String().substring(0, 10);

    final result = await database.rawQuery(
      '''
      SELECT COALESCE(SUM(total_amount), 0) AS total
      FROM ${DatabaseService.salesTable}
      WHERE substr(created_at, 1, 10) = ?
      ''',
      [today],
    );

    final total = result.first['total'];
    return (total as num?)?.toDouble() ?? 0.0;
  }

  Future<int> getSaleCount() async {
    final Database database = await _databaseService.database;

    final result = await database.rawQuery(
      '''
      SELECT COUNT(*) AS count
      FROM ${DatabaseService.salesTable}
      ''',
    );

    return Sqflite.firstIntValue(result) ?? 0;
  }
}
