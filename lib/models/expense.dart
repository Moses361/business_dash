class Expense {
  final int? id;
  final String title;
  final double amount;
  final String category;
  final DateTime createdAt;

  const Expense({
    this.id,
    required this.title,
    required this.amount,
    required this.category,
    required this.createdAt,
  });
}
