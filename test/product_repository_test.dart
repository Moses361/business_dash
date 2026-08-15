import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:business_dash/models/product.dart';
import 'package:business_dash/repositories/product_repository.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  test('Product can be saved and retrieved', () async {
    final repository = ProductRepository();

    final product = Product(
      name: 'Test Brake Pads',
      category: 'Motorcycle Parts',
      buyingPrice: 1500,
      sellingPrice: 2500,
      stockQuantity: 10,
    );

    final id = await repository.insertProduct(product);

    expect(id, greaterThan(0));

    final products = await repository.getProducts();

    expect(products, isNotEmpty);
    expect(products.first.name, 'Test Brake Pads');
  });
}
