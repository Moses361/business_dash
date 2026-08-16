import 'package:sqflite/sqflite.dart';

import '../database/database_service.dart';
import '../models/product.dart';

class ProductRepository {
  final DatabaseService _databaseService;

  ProductRepository({DatabaseService? databaseService})
    : _databaseService = databaseService ?? DatabaseService();

  Future<int> insertProduct(Product product) async {
    final Database database = await _databaseService.database;

    return database.insert(DatabaseService.productsTable, {
      'name': product.name,
      'category': product.category,
      'buying_price': product.buyingPrice,
      'selling_price': product.sellingPrice,
      'stock_quantity': product.stockQuantity,
    });
  }

  Future<int> updateProduct(Product product) async {
    final Database database = await _databaseService.database;

    if (product.id == null) {
      throw ArgumentError('Product id is required to update a product');
    }

    return database.update(
      DatabaseService.productsTable,
      {
        'name': product.name,
        'category': product.category,
        'buying_price': product.buyingPrice,
        'selling_price': product.sellingPrice,
        'stock_quantity': product.stockQuantity,
      },
      where: 'id = ?',
      whereArgs: [product.id],
    );
  }

  Future<List<Product>> getProducts() async {
    final Database database = await _databaseService.database;

    final List<Map<String, dynamic>> rows = await database.query(
      DatabaseService.productsTable,
      orderBy: 'id DESC',
    );

    return rows.map((row) {
      return Product(
        id: row['id'] as int,
        name: row['name'] as String,
        category: row['category'] as String,
        buyingPrice: (row['buying_price'] as num).toDouble(),
        sellingPrice: (row['selling_price'] as num).toDouble(),
        stockQuantity: row['stock_quantity'] as int,
      );
    }).toList();
  }

  Future<int> getProductCount() async {
    final Database database = await _databaseService.database;

    final result = await database.rawQuery(
      'SELECT COUNT(*) AS count FROM ${DatabaseService.productsTable}',
    );

    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<int> getLowStockCount({int threshold = 5}) async {
    final Database database = await _databaseService.database;

    final result = await database.rawQuery(
      '''
      SELECT COUNT(*) AS count
      FROM ${DatabaseService.productsTable}
      WHERE stock_quantity <= ?
      ''',
      [threshold],
    );

    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<int> deleteProduct(int id) async {
    final Database database = await _databaseService.database;

    return database.delete(
      DatabaseService.productsTable,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> reduceStock({
    required int productId,
    required int quantity,
  }) async {
    if (quantity <= 0) {
      throw ArgumentError('Quantity must be greater than zero');
    }

    final Database database = await _databaseService.database;

    return database.rawUpdate(
      '''
      UPDATE ${DatabaseService.productsTable}
      SET stock_quantity = stock_quantity - ?
      WHERE id = ?
        AND stock_quantity >= ?
      ''',
      [quantity, productId, quantity],
    );
  }
}
