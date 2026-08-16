import 'package:flutter/material.dart';

import '../models/product.dart';
import '../repositories/product_repository.dart';
import 'add_product_screen.dart';

class ProductDetailsScreen extends StatefulWidget {
  final Product product;

  const ProductDetailsScreen({super.key, required this.product});

  @override
  State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  final ProductRepository _repository = ProductRepository();
  late Product _product;

  @override
  void initState() {
    super.initState();
    _product = widget.product;
  }

  Future<void> _deleteProduct() async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Product'),
          content: Text('Are you sure you want to delete "${_product.name}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true) {
      return;
    }

    await _repository.deleteProduct(_product.id!);

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Product deleted successfully')),
    );

    Navigator.pop(context, true);
  }

  Future<void> _editProduct() async {
    final updatedProduct = await Navigator.push<Product>(
      context,
      MaterialPageRoute(
        builder: (context) => AddProductScreen(product: _product),
      ),
    );

    if (!mounted || updatedProduct == null) {
      return;
    }

    setState(() {
      _product = updatedProduct;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Product updated successfully')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final product = _product;

    final profit = product.sellingPrice - product.buyingPrice;
    final stockValue = product.buyingPrice * product.stockQuantity;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Product Details'),
        actions: [
          IconButton(
            onPressed: _editProduct,
            tooltip: 'Edit product',
            icon: const Icon(Icons.edit_outlined),
          ),
          IconButton(
            onPressed: _deleteProduct,
            tooltip: 'Delete product',
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.green.shade700,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 36,
                  backgroundColor: Colors.white.withValues(alpha: 0.2),
                  child: const Icon(
                    Icons.inventory_2,
                    color: Colors.white,
                    size: 36,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  product.name,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 25,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  product.category,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          const Text(
            'Product Information',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 12),

          _InfoCard(
            icon: Icons.shopping_cart_outlined,
            title: 'Buying Price',
            value: 'KSh ${product.buyingPrice.toStringAsFixed(0)}',
          ),

          _InfoCard(
            icon: Icons.sell_outlined,
            title: 'Selling Price',
            value: 'KSh ${product.sellingPrice.toStringAsFixed(0)}',
          ),

          _InfoCard(
            icon: Icons.inventory_outlined,
            title: 'Current Stock',
            value: '${product.stockQuantity} units',
          ),

          _InfoCard(
            icon: Icons.trending_up,
            title: 'Profit Per Unit',
            value: 'KSh ${profit.toStringAsFixed(0)}',
          ),

          _InfoCard(
            icon: Icons.account_balance_wallet_outlined,
            title: 'Stock Value',
            value: 'KSh ${stockValue.toStringAsFixed(0)}',
          ),

          const SizedBox(height: 20),

          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 52,
                  child: OutlinedButton.icon(
                    onPressed: _editProduct,
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('Edit Product'),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SizedBox(
                  height: 52,
                  child: OutlinedButton.icon(
                    onPressed: _deleteProduct,
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Delete Product'),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _InfoCard({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.green.shade700),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              title,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
            ),
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
