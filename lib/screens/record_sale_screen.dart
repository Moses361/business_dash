import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/product.dart';
import '../models/sale.dart';
import '../repositories/product_repository.dart';
import '../repositories/sale_repository.dart';
import '../widgets/veroon_header.dart';

class RecordSaleScreen extends StatefulWidget {
  final ProductRepository? productRepository;
  final SaleRepository? saleRepository;

  const RecordSaleScreen({
    super.key,
    this.productRepository,
    this.saleRepository,
  });

  @override
  State<RecordSaleScreen> createState() => _RecordSaleScreenState();
}

class _RecordSaleScreenState extends State<RecordSaleScreen> {
  late final ProductRepository _productRepository;
  late final SaleRepository _saleRepository;

  final TextEditingController _quantityController = TextEditingController();

  List<Product> _products = [];
  Product? _selectedProduct;

  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;

  int get _quantity => int.tryParse(_quantityController.text.trim()) ?? 0;

  double get _totalAmount {
    if (_selectedProduct == null || _quantity <= 0) {
      return 0;
    }

    return _selectedProduct!.sellingPrice * _quantity;
  }

  @override
  void initState() {
    super.initState();

    _productRepository = widget.productRepository ?? ProductRepository();
    _saleRepository = widget.saleRepository ?? SaleRepository();

    _loadProducts();

    _quantityController.addListener(_onQuantityChanged);
  }

  @override
  void dispose() {
    _quantityController.removeListener(_onQuantityChanged);
    _quantityController.dispose();
    super.dispose();
  }

  void _onQuantityChanged() {
    setState(() {});
  }

  Future<void> _loadProducts() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final products = await _productRepository.getProducts();

      if (!mounted) return;

      setState(() {
        _products = products;
        _isLoading = false;

        if (_selectedProduct != null) {
          final updatedProduct = products.where(
            (product) => product.id == _selectedProduct!.id,
          );

          _selectedProduct = updatedProduct.isNotEmpty
              ? updatedProduct.first
              : null;
        }
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load products.';
      });
    }
  }

  Future<void> _recordSale() async {
    FocusScope.of(context).unfocus();

    if (_selectedProduct == null) {
      _showMessage('Please select a product.');
      return;
    }

    if (_quantity <= 0) {
      _showMessage('Please enter a valid quantity.');
      return;
    }

    if (_quantity > _selectedProduct!.stockQuantity) {
      _showMessage(
        'Not enough stock. Only '
        '${_selectedProduct!.stockQuantity} available.',
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final product = _selectedProduct!;

      final sale = Sale(
        productId: product.id!,
        productName: product.name,
        quantity: _quantity,
        sellingPrice: product.sellingPrice,
        totalAmount: _totalAmount,
        createdAt: DateTime.now(),
      );

      await _saleRepository.recordSale(sale: sale);

      if (!mounted) return;

      _quantityController.clear();

      await _loadProducts();

      if (!mounted) return;

      setState(() {
        _selectedProduct = null;
        _isSaving = false;
      });

      _showMessage('Sale recorded successfully.', isError: false);
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _isSaving = false;
      });

      if (error is StateError) {
        _showMessage(
          'Sale could not be recorded. The product may no longer have '
          'enough stock.',
        );
      } else {
        _showMessage('Something went wrong while recording the sale.');
      }
    }
  }

  void _showMessage(String message, {bool isError = true}) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Record Sale')),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48),
              const SizedBox(height: 16),
              Text(_errorMessage!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadProducts,
                child: const Text('Try Again'),
              ),
            ],
          ),
        ),
      );
    }

    if (_products.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'No products available.\n'
            'Add a product before recording a sale.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const VeroonHeader(),

          const SizedBox(height: 24),

          const Text(
            'Record a Sale',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 8),

          const Text('Select a product and enter the quantity sold.'),

          const SizedBox(height: 24),

          DropdownButtonFormField<int>(
            initialValue: _selectedProduct?.id,
            decoration: const InputDecoration(
              labelText: 'Product',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.inventory_2_outlined),
            ),
            items: _products.map((product) {
              return DropdownMenuItem<int>(
                value: product.id,
                child: Text(
                  '${product.name} (${product.stockQuantity} in stock)',
                ),
              );
            }).toList(),
            onChanged: _isSaving
                ? null
                : (productId) {
                    if (productId == null) return;

                    final product = _products.firstWhere(
                      (item) => item.id == productId,
                    );

                    setState(() {
                      _selectedProduct = product;
                    });
                  },
          ),

          const SizedBox(height: 20),

          if (_selectedProduct != null) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _InfoRow(
                      label: 'Selling price',
                      value: _formatAmount(_selectedProduct!.sellingPrice),
                    ),
                    const SizedBox(height: 10),
                    _InfoRow(
                      label: 'Available stock',
                      value: '${_selectedProduct!.stockQuantity}',
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),
          ],

          TextFormField(
            controller: _quantityController,
            enabled: !_isSaving,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(
              labelText: 'Quantity',
              hintText: 'Enter quantity sold',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.shopping_cart_outlined),
            ),
          ),

          const SizedBox(height: 24),

          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const Text('Sale Total', style: TextStyle(fontSize: 16)),
                  const SizedBox(height: 8),
                  Text(
                    _formatAmount(_totalAmount),
                    style: const TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 28),

          SizedBox(
            height: 52,
            child: ElevatedButton.icon(
              onPressed: _isSaving ? null : _recordSale,
              icon: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.point_of_sale),
              label: Text(_isSaving ? 'Recording Sale...' : 'Record Sale'),
            ),
          ),
        ],
      ),
    );
  }

  String _formatAmount(double amount) {
    return 'KSh ${amount.toStringAsFixed(2)}';
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }
}
