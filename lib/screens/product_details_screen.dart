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
  late Product _product;
  final ProductRepository _productRepository = ProductRepository();

  bool _savingAdjustment = false;

  static const Color _primary = Color(0xFF176B4D);
  static const Color _background = Color(0xFFF6F8F7);
  static const Color _textPrimary = Color(0xFF17221D);
  static const Color _textSecondary = Color(0xFF66736D);
  static const Color _warning = Color(0xFFD58A18);
  static const Color _danger = Color(0xFFD64545);

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
          content: Text('Are you sure you want to delete "${_product.name}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              style: FilledButton.styleFrom(backgroundColor: _danger),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true || !mounted) return;

    // ProductsScreen handles deletion and its undo action.
    Navigator.pop(context, _product);
  }

  Future<void> _editProduct() async {
    final Product? updatedProduct = await Navigator.push<Product>(
      context,
      MaterialPageRoute(builder: (_) => AddProductScreen(product: _product)),
    );

    if (!mounted || updatedProduct == null) return;

    setState(() {
      _product = updatedProduct;
    });

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text('Product updated successfully'),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        ),
      );
  }

  Future<void> _adjustStock() async {
    if (_product.id == null) {
      _showMessage('This product cannot be adjusted because it has no ID.');
      return;
    }

    final int? newStock = await showDialog<int>(
      context: context,
      barrierDismissible: !_savingAdjustment,
      builder: (dialogContext) {
        return _StockAdjustmentDialog(
          currentStock: _product.stockQuantity,
          productName: _product.name,
          onSave: (quantityDelta, note) async {
            if (_savingAdjustment) return;

            setState(() => _savingAdjustment = true);

            try {
              final int updatedStock = await _productRepository.adjustStock(
                productId: _product.id!,
                quantityDelta: quantityDelta,
                note: note,
              );

              if (!mounted) return;

              setState(() {
                _product = Product(
                  id: _product.id,
                  name: _product.name,
                  category: _product.category,
                  buyingPrice: _product.buyingPrice,
                  sellingPrice: _product.sellingPrice,
                  stockQuantity: updatedStock,
                );
                _savingAdjustment = false;
              });

              if (dialogContext.mounted) {
                Navigator.pop(dialogContext, updatedStock);
              }
            } catch (error) {
              if (mounted) {
                setState(() => _savingAdjustment = false);
              }

              if (dialogContext.mounted) {
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Could not adjust stock: ${_friendlyError(error)}',
                    ),
                    behavior: SnackBarBehavior.floating,
                    backgroundColor: _danger,
                  ),
                );
              }
            }
          },
        );
      },
    );

    if (!mounted || newStock == null) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('Stock updated successfully. New balance: $newStock'),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );
  }

  String _friendlyError(Object error) {
    final String message = error.toString();

    if (message.contains('Stock cannot be negative')) {
      return 'There are not enough units to remove.';
    }

    if (message.contains('Product not found')) {
      return 'The product could not be found. Refresh and try again.';
    }

    if (message.contains('Bad state')) {
      return 'The product is no longer available.';
    }

    return 'Please check the product and try again.';
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
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
      backgroundColor: _background,
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
              color: _textPrimary,
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
            valueColor: _primary,
          ),
          _InfoCard(
            icon: Icons.inventory_2_outlined,
            title: 'Current Stock',
            value: '${product.stockQuantity} units',
            valueColor: lowStock ? _warning : null,
          ),
          _InfoCard(
            icon: profit >= 0
                ? Icons.trending_up_rounded
                : Icons.trending_down_rounded,
            title: 'Profit Per Unit',
            value: _formatAmount(profit),
            valueColor: profit >= 0 ? _primary : _danger,
          ),
          _InfoCard(
            icon: Icons.account_balance_wallet_outlined,
            title: 'Stock Value',
            value: _formatAmount(stockValue),
          ),

          const SizedBox(height: 8),

          SizedBox(
            height: 52,
            child: FilledButton.icon(
              onPressed: _savingAdjustment ? null : _adjustStock,
              icon: const Icon(Icons.swap_vert_rounded),
              label: const Text(
                'Adjust Stock',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: _primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),

          const SizedBox(height: 8),

          const Text(
            'Record deliveries, damaged items, stock corrections, '
            'or other changes outside recorded sales.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11, height: 1.5, color: _textSecondary),
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
                  Icon(Icons.warning_amber_rounded, color: _warning),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'This product is low on stock. '
                      'Consider restocking soon.',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: _warning,
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
                      foregroundColor: _danger,
                      side: const BorderSide(color: _danger),
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

class _StockAdjustmentDialog extends StatefulWidget {
  final int currentStock;
  final String productName;
  final Future<void> Function(int quantityDelta, String note) onSave;

  const _StockAdjustmentDialog({
    required this.currentStock,
    required this.productName,
    required this.onSave,
  });

  @override
  State<_StockAdjustmentDialog> createState() => _StockAdjustmentDialogState();
}

class _StockAdjustmentDialogState extends State<_StockAdjustmentDialog> {
  static const Color _primary = Color(0xFF176B4D);
  static const Color _danger = Color(0xFFD64545);

  final TextEditingController _quantityController = TextEditingController(
    text: '1',
  );
  final TextEditingController _noteController = TextEditingController();

  bool _isReceiving = true;
  bool _isSaving = false;

  int get _quantity => int.tryParse(_quantityController.text.trim()) ?? 0;

  int get _delta => _isReceiving ? _quantity : -_quantity;

  int get _resultingStock => widget.currentStock + _delta;

  bool get _valid =>
      _quantity > 0 &&
      _noteController.text.trim().isNotEmpty &&
      _resultingStock >= 0;

  @override
  void dispose() {
    _quantityController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_valid || _isSaving) return;

    setState(() => _isSaving = true);

    await widget.onSave(_delta, _noteController.text.trim());

    // If the save fails, the parent shows the error and the dialog remains.
    if (mounted && _isSaving) {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool enoughStock = _resultingStock >= 0;

    return AlertDialog(
      title: const Text(
        'Adjust Stock',
        style: TextStyle(fontWeight: FontWeight.w800),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.productName,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: Color(0xFF66736D),
              ),
            ),
            const SizedBox(height: 8),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFE1F1EA),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Current balance: ${widget.currentStock} units',
                style: const TextStyle(
                  color: _primary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),

            const SizedBox(height: 18),

            const Text(
              'Adjustment type',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),

            Row(
              children: [
                Expanded(
                  child: _typeButton(
                    label: 'Receive',
                    icon: Icons.add_circle_outline,
                    selected: _isReceiving,
                    color: _primary,
                    onTap: () => setState(() => _isReceiving = true),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _typeButton(
                    label: 'Remove',
                    icon: Icons.remove_circle_outline,
                    selected: !_isReceiving,
                    color: _danger,
                    onTap: () => setState(() => _isReceiving = false),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            TextField(
              controller: _quantityController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Quantity (whole units)',
                hintText: 'e.g. 5',
                border: OutlineInputBorder(),
              ),
              onChanged: (_) => setState(() {}),
            ),

            const SizedBox(height: 14),

            TextField(
              controller: _noteController,
              maxLines: 2,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Reason for adjustment',
                hintText: 'e.g. New delivery, damaged stock',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              onChanged: (_) => setState(() {}),
            ),

            const SizedBox(height: 16),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: enoughStock
                    ? const Color(0xFFF0F5F2)
                    : const Color(0xFFFFEEEE),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'New stock balance',
                    style: TextStyle(fontSize: 12, color: Color(0xFF66736D)),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    enoughStock
                        ? '$_resultingStock units'
                        : 'Insufficient stock',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: enoughStock ? _primary : _danger,
                    ),
                  ),
                  if (!enoughStock)
                    const Text(
                      'You cannot remove more units than are available.',
                      style: TextStyle(color: _danger, fontSize: 11),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _valid && !_isSaving ? _submit : null,
          style: FilledButton.styleFrom(backgroundColor: _primary),
          child: _isSaving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Save Adjustment'),
        ),
      ],
    );
  }

  Widget _typeButton({
    required String label,
    required IconData icon,
    required bool selected,
    required Color color,
    required VoidCallback onTap,
  }) {
    return OutlinedButton.icon(
      onPressed: _isSaving ? null : onTap,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: selected ? Colors.white : color,
        backgroundColor: selected ? color : Colors.transparent,
        side: BorderSide(color: color),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
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
            child: Icon(icon, color: _ProductColors.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(color: Color(0xFF66736D), fontSize: 12),
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(
                color: valueColor ?? const Color(0xFF17221D),
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductColors {
  static const Color primary = Color(0xFF176B4D);
}
