import 'package:sqflite/sqflite.dart';

import 'package:uuid/uuid.dart';

import '../database/database_service.dart';
import '../models/product.dart';

class ProductRepository {
  final DatabaseService _databaseService;

  ProductRepository({DatabaseService? databaseService})
    : _databaseService = databaseService ?? DatabaseService();

  String get _nowUtc => DateTime.now().toUtc().toIso8601String();

  Future<int> insertProduct(Product product) async {
    final Database database = await _databaseService.database;
    final now = _nowUtc;

    final id = await database.insert(DatabaseService.productsTable, {
      'name': product.name,
      'category': product.category,
      'buying_price': product.buyingPrice,
      'selling_price': product.sellingPrice,
      'stock_quantity': product.stockQuantity,
      DatabaseService.syncIdColumn: const Uuid().v4(),
      DatabaseService.syncStatusColumn: 'pending',
      DatabaseService.updatedAtColumn: now,
      DatabaseService.deletedAtColumn: null,
    });

    print('VEROON INSERT: ${product.name} -> ID $id');
    return id;
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
        DatabaseService.syncStatusColumn: 'pending',
        DatabaseService.updatedAtColumn: _nowUtc,
      },
      where: "id = ? AND deleted_at IS NULL",
      whereArgs: [product.id],
    );
  }

  Future<List<Product>> getProducts() async {
    final Database database = await _databaseService.database;

    final rows = await database.query(
      DatabaseService.productsTable,
      where: '${DatabaseService.deletedAtColumn} IS NULL',
      orderBy: 'id DESC',
    );

    print('========================================');
    print('VEROON PRODUCTS READ');
    print('Number of products: ${rows.length}');

    for (final row in rows) {
      print(
        'ID=${row['id']} '
        'NAME=${row['name']} '
        'STOCK=${row['stock_quantity']} '
        'PRICE=${row['selling_price']}',
      );
    }

    print('========================================');

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

    final result = await database.rawQuery('''
      SELECT COUNT(*) AS count
      FROM ${DatabaseService.productsTable}
      WHERE ${DatabaseService.deletedAtColumn} IS NULL
      ''');

    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<int> getLowStockCount({int threshold = 5}) async {
    final Database database = await _databaseService.database;

    final result = await database.rawQuery(
      '''
      SELECT COUNT(*) AS count
      FROM ${DatabaseService.productsTable}
      WHERE stock_quantity <= ?
        AND ${DatabaseService.deletedAtColumn} IS NULL
      ''',
      [threshold],
    );

    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<int> deleteProduct(int id) async {
    final Database database = await _databaseService.database;

    return database.update(
      DatabaseService.productsTable,
      {
        DatabaseService.deletedAtColumn: _nowUtc,
        DatabaseService.syncStatusColumn: 'pending',
        DatabaseService.updatedAtColumn: _nowUtc,
      },
      where: 'id = ? AND ${DatabaseService.deletedAtColumn} IS NULL',
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
      SET stock_quantity = stock_quantity - ?,
          ${DatabaseService.syncStatusColumn} = 'pending',
          ${DatabaseService.updatedAtColumn} = ?
      WHERE id = ?
        AND stock_quantity >= ?
        AND ${DatabaseService.deletedAtColumn} IS NULL
      ''',
      [quantity, _nowUtc, productId, quantity],
    );
  }
}
