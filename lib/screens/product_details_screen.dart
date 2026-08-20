import 'package:flutter/material.dart';

import '../models/product.dart';
import 'add_product_screen.dart';

class ProductDetailsScreen extends StatefulWidget {
  final Product product;

  const ProductDetailsScreen({super.key, required this.product});

  @override
  State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  late Product _product;

  @override
  void initState() {
    super.initState();
    _product = widget.product;
  }

  Future<void> _deleteProduct() async {
    final bool? shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete Product'),
          content: Text(
            'Are you sure you want to delete '
            '"${_product.name}"?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFD64545),
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true || !mounted) {
      return;
    }

    // Do NOT delete here.
    // Return the product to ProductsScreen so it can
    // perform the deletion and provide the standard
    // 4-second UNDO action.
    Navigator.pop(context, _product);
  }

  Future<void> _editProduct() async {
    final Product? updatedProduct = await Navigator.push<Product>(
      context,
      MaterialPageRoute(builder: (_) => AddProductScreen(product: _product)),
    );

    if (!mounted || updatedProduct == null) {
      return;
    }

    setState(() {
      _product = updatedProduct;
    });

    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Product updated successfully'),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
        persist: false,
      ),
    );
  }

  String _formatAmount(double amount) {
    return 'KSh ${amount.toStringAsFixed(2)}';
  }

  @override
  Widget build(BuildContext context) {
    final Product product = _product;

    final double profit = product.sellingPrice - product.buyingPrice;

    final double stockValue = product.buyingPrice * product.stockQuantity;

    final bool lowStock = product.stockQuantity <= 5;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8F7),
      appBar: AppBar(
        title: const Text(
          'Product Details',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            onPressed: _editProduct,
            tooltip: 'Edit product',
            icon: const Icon(Icons.edit_outlined),
          ),
          IconButton(
            onPressed: _deleteProduct,
            tooltip: 'Delete product',
            icon: const Icon(Icons.delete_outline_rounded),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 30),
        children: [
          _buildHero(product),

          const SizedBox(height: 20),

          const Text(
            'Product information',
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w800,
              color: Color(0xFF17221D),
            ),
          ),

          const SizedBox(height: 12),

          _InfoCard(
            icon: Icons.shopping_cart_outlined,
            title: 'Buying Price',
            value: _formatAmount(product.buyingPrice),
          ),

          _InfoCard(
            icon: Icons.point_of_sale_outlined,
            title: 'Selling Price',
            value: _formatAmount(product.sellingPrice),
            valueColor: const Color(0xFF176B4D),
          ),

          _InfoCard(
            icon: Icons.inventory_2_outlined,
            title: 'Current Stock',
            value: '${product.stockQuantity} units',
            valueColor: lowStock ? const Color(0xFFD58A18) : null,
          ),

          _InfoCard(
            icon: profit >= 0
                ? Icons.trending_up_rounded
                : Icons.trending_down_rounded,
            title: 'Profit Per Unit',
            value: _formatAmount(profit),
            valueColor: profit >= 0
                ? const Color(0xFF176B4D)
                : const Color(0xFFD64545),
          ),

          _InfoCard(
            icon: Icons.account_balance_wallet_outlined,
            title: 'Stock Value',
            value: _formatAmount(stockValue),
          ),

          const SizedBox(height: 16),

          if (lowStock)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3DD),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: Color(0xFFD58A18)),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'This product is low on stock. '
                      'Consider restocking soon.',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFD58A18),
                      ),
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 20),

          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 50,
                  child: OutlinedButton.icon(
                    onPressed: _editProduct,
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('Edit Product'),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SizedBox(
                  height: 50,
                  child: OutlinedButton.icon(
                    onPressed: _deleteProduct,
                    icon: const Icon(Icons.delete_outline_rounded),
                    label: const Text('Delete'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFD64545),
                      side: const BorderSide(color: Color(0xFFD64545)),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHero(Product product) {
    final bool lowStock = product.stockQuantity <= 5;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF176B4D), Color(0xFF0F513A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Icon(
                  Icons.inventory_2_rounded,
                  color: Colors.white,
                  size: 27,
                ),
              ),
              const Spacer(),
              if (product.id != null)
                Text(
                  '#${product.id}',
                  style: const TextStyle(
                    color: Colors.white60,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),

          const SizedBox(height: 18),

          Text(
            product.name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 25,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.4,
            ),
          ),

          const SizedBox(height: 5),

          Text(
            product.category,
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),

          const SizedBox(height: 18),

          Row(
            children: [
              Expanded(
                child: _HeroMetric(
                  label: 'Selling price',
                  value: _formatAmount(product.sellingPrice),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _HeroMetric(
                  label: 'Stock',
                  value: '${product.stockQuantity}',
                  warning: lowStock,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroMetric extends StatelessWidget {
  final String label;
  final String value;
  final bool warning;

  const _HeroMetric({
    required this.label,
    required this.value,
    this.warning = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 10),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: warning ? const Color(0xFFFFD27A) : Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
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
  final Color? valueColor;

  const _InfoCard({
    required this.icon,
    required this.title,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFFE1E9E4)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFFE1F1EA),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, color: const Color(0xFF176B4D), size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(color: Color(0xFF66736D), fontSize: 12),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: valueColor ?? const Color(0xFF17221D),
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
