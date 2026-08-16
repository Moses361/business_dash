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

  Future<List<Product>> getProducts() async {
    final Database database = await _databaseService.database;

    final List<Map<String, dynamic>> rows = await database.query(
      DatabaseService.productsTable,
      orderBy: 'id DESC',
    );

    return rows.map(_productFromMap).toList();
  }

  Future<Product?> getProductById(int id) async {
    final Database database = await _databaseService.database;

    final List<Map<String, dynamic>> rows = await database.query(
      DatabaseService.productsTable,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (rows.isEmpty) {
      return null;
    }

    return _productFromMap(rows.first);
  }

  Future<int> updateProduct(Product product) async {
    if (product.id == null) {
      throw ArgumentError('Product ID is required to update a product.');
    }

    final Database database = await _databaseService.database;

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

  Future<int> deleteProduct(int id) async {
    final Database database = await _databaseService.database;

    return database.delete(
      DatabaseService.productsTable,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Product _productFromMap(Map<String, dynamic> row) {
    return Product(
      id: row['id'] as int,
      name: row['name'] as String,
      category: row['category'] as String,
      buyingPrice: (row['buying_price'] as num).toDouble(),
      sellingPrice: (row['selling_price'] as num).toDouble(),
      stockQuantity: row['stock_quantity'] as int,
    );
  }
}
