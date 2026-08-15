import 'package:flutter/material.dart';

import '../widgets/product_card.dart';
import 'add_product_screen.dart';

class ProductsScreen extends StatelessWidget {
  const ProductsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Products')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              decoration: InputDecoration(
                hintText: 'Search products...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),

            const SizedBox(height: 16),

            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  FilterChip(
                    label: const Text('All'),
                    selected: true,
                    onSelected: (_) {},
                  ),

                  const SizedBox(width: 8),

                  FilterChip(
                    label: const Text('Motorcycle Parts'),
                    selected: false,
                    onSelected: (_) {},
                  ),

                  const SizedBox(width: 8),

                  FilterChip(
                    label: const Text('Agrovet'),
                    selected: false,
                    onSelected: (_) {},
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            const Text(
              '125 Products',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 12),

            Expanded(
              child: ListView(
                children: const [
                  ProductCard(
                    name: 'Brake Pads',
                    category: 'Motorcycle Parts',
                    stock: 15,
                    price: 'KSh 2,500',
                  ),

                  ProductCard(
                    name: 'Chain Kit',
                    category: 'Motorcycle Parts',
                    stock: 8,
                    price: 'KSh 1,800',
                  ),

                  ProductCard(
                    name: 'Engine Oil',
                    category: 'Lubricants',
                    stock: 4,
                    price: 'KSh 1,200',
                  ),

                  ProductCard(
                    name: 'Spark Plug',
                    category: 'Motorcycle Parts',
                    stock: 20,
                    price: 'KSh 450',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddProductScreen()),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Product'),
      ),
    );
  }
}
