class Sale {
  final int? id;
  final int productId;
  final String productName;
  final int quantity;
  final double sellingPrice;
  final double totalAmount;
  final DateTime createdAt;

  const Sale({
    this.id,
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.sellingPrice,
    required this.totalAmount,
    required this.createdAt,
  });
}
