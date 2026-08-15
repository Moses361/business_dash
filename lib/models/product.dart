class Product {
  final int? id;
  final String name;
  final String category;
  final double buyingPrice;
  final double sellingPrice;
  final int stockQuantity;

  const Product({
    this.id,
    required this.name,
    required this.category,
    required this.buyingPrice,
    required this.sellingPrice,
    required this.stockQuantity,
  });
}
