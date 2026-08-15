import 'package:flutter/material.dart';

class ProductCard extends StatelessWidget {
  final String name;
  final String category;
  final int stock;
  final String price;

  const ProductCard({
    super.key,
    required this.name,
    required this.category,
    required this.stock,
    required this.price,
  });

  bool get isLowStock => stock <= 5;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(child: Icon(Icons.inventory_2_outlined)),

            const SizedBox(width: 16),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 4),

                  Text(category, style: TextStyle(color: Colors.grey.shade600)),

                  const SizedBox(height: 8),

                  Row(
                    children: [
                      Text(
                        isLowStock ? 'LOW STOCK' : 'Stock: $stock',
                        style: TextStyle(
                          color: isLowStock ? Colors.red : Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const Spacer(),

                      Text(
                        price,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            PopupMenuButton<String>(
              onSelected: (value) {
                // Edit/delete actions will be added later.
              },
              itemBuilder: (context) => const [
                PopupMenuItem(value: 'edit', child: Text('Edit')),
                PopupMenuItem(value: 'delete', child: Text('Delete')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
