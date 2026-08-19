import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/product.dart';
import '../models/sale.dart';
import '../repositories/product_repository.dart';
import '../repositories/sale_repository.dart';

const Color _primary = Color(0xFF176B4D);
const Color _primaryDark = Color(0xFF0F513A);
const Color _softGreen = Color(0xFFE1F1EA);
const Color _background = Color(0xFFF6F8F7);
const Color _textPrimary = Color(0xFF17221D);
const Color _textSecondary = Color(0xFF66736D);
const Color _danger = Color(0xFFD64545);
const Color _warning = Color(0xFFD58A18);

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

  double get _expectedProfit {
    if (_selectedProduct == null || _quantity <= 0) {
      return 0;
    }

    final profitPerUnit =
        _selectedProduct!.sellingPrice - _selectedProduct!.buyingPrice;

    return profitPerUnit * _quantity;
  }

  @override
  void initState() {
    super.initState();

    _productRepository = widget.productRepository ?? ProductRepository();

    _saleRepository = widget.saleRepository ?? SaleRepository();

    _quantityController.addListener(_onQuantityChanged);

    _loadProducts();
  }

  @override
  void dispose() {
    _quantityController.removeListener(_onQuantityChanged);
    _quantityController.dispose();
    super.dispose();
  }

  void _onQuantityChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _loadProducts() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final products = await _productRepository.getProducts();

      if (!mounted) return;

      setState(() {
        _products = products;
        _isLoading = false;

        if (_selectedProduct != null) {
          final matching = products.where(
            (product) => product.id == _selectedProduct!.id,
          );

          _selectedProduct = matching.isNotEmpty ? matching.first : null;
        }
      });
    } catch (error) {
      debugPrint('Record sale loading error: $error');

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
      _showMessage('Please select a product.', isError: true);
      return;
    }

    if (_quantity <= 0) {
      _showMessage('Please enter a valid quantity.', isError: true);
      return;
    }

    if (_quantity > _selectedProduct!.stockQuantity) {
      _showMessage(
        'Not enough stock. Only '
        '${_selectedProduct!.stockQuantity} available.',
        isError: true,
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
        buyingPrice: product.buyingPrice,
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
          'Sale could not be recorded. '
          'The product may no longer have enough stock.',
          isError: true,
        );
      } else {
        _showMessage(
          'Something went wrong while recording the sale.',
          isError: true,
        );
      }
    }
  }

  void _showMessage(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: isError ? const Color(0xFF202824) : _primary,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _changeQuantity(int amount) {
    if (_isSaving) return;

    final current = _quantity;
    final next = (current + amount).clamp(0, 999999);

    _quantityController.text = next == 0 ? '' : '$next';

    _quantityController.selection = TextSelection.fromPosition(
      TextPosition(offset: _quantityController.text.length),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        title: const Text(
          'Record Sale',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return _buildErrorState();
    }

    if (_products.isEmpty) {
      return _buildEmptyState();
    }

    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildIntro(),
            const SizedBox(height: 18),
            _buildProductSelector(),
            if (_selectedProduct != null) ...[
              const SizedBox(height: 14),
              _buildProductSummary(),
              const SizedBox(height: 18),
              _buildQuantitySection(),
              const SizedBox(height: 18),
              _buildSaleSummary(),
              const SizedBox(height: 18),
              _buildRecordButton(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildIntro() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _softGreen,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.point_of_sale_rounded,
              color: _primary,
              size: 25,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'New sale',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: _textPrimary,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Select a product and enter the quantity sold.',
                  style: TextStyle(
                    fontSize: 12,
                    color: _textSecondary,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductSelector() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Product',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: _textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Choose the product being sold.',
              style: TextStyle(fontSize: 11, color: _textSecondary),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<int>(
              value: _selectedProduct?.id,
              isExpanded: true,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.inventory_2_outlined),
                labelText: 'Select product',
              ),
              items: _products.map((product) {
                final unavailable = product.stockQuantity <= 0;

                return DropdownMenuItem<int>(
                  value: product.id,
                  enabled: !unavailable,
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          product.name,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: unavailable
                                ? Colors.grey.shade400
                                : _textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        unavailable ? 'Out' : '${product.stockQuantity} left',
                        style: TextStyle(
                          color: unavailable ? _danger : _primary,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
              onChanged: _isSaving
                  ? null
                  : (productId) {
                      if (productId == null) {
                        return;
                      }

                      final product = _products.firstWhere(
                        (item) => item.id == productId,
                      );

                      setState(() {
                        _selectedProduct = product;

                        if (_quantity > product.stockQuantity) {
                          _quantityController.clear();
                        }
                      });
                    },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductSummary() {
    final product = _selectedProduct!;

    final unitProfit = product.sellingPrice - product.buyingPrice;

    final lowStock = product.stockQuantity <= 5;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: _softGreen,
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: const Icon(
                    Icons.inventory_2_rounded,
                    color: _primary,
                    size: 23,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        product.category,
                        style: const TextStyle(
                          fontSize: 11,
                          color: _textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: lowStock ? const Color(0xFFFFF3DD) : _softGreen,
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Text(
                    '${product.stockQuantity} in stock',
                    style: TextStyle(
                      color: lowStock ? _warning : _primary,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _Metric(
                    label: 'Buying',
                    value: _formatAmount(product.buyingPrice),
                  ),
                ),
                Expanded(
                  child: _Metric(
                    label: 'Selling',
                    value: _formatAmount(product.sellingPrice),
                    valueColor: _primary,
                  ),
                ),
                Expanded(
                  child: _Metric(
                    label: 'Profit / unit',
                    value: _formatAmount(unitProfit),
                    valueColor: unitProfit >= 0 ? _primary : _danger,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuantitySection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Quantity',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: _textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'How many units are being sold?',
              style: TextStyle(fontSize: 11, color: _textSecondary),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                _QuantityButton(
                  icon: Icons.remove_rounded,
                  onPressed: _quantity > 0 ? () => _changeQuantity(-1) : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _quantityController,
                    enabled: !_isSaving,
                    textAlign: TextAlign.center,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: _textPrimary,
                    ),
                    decoration: const InputDecoration(
                      hintText: '0',
                      contentPadding: EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                _QuantityButton(
                  icon: Icons.add_rounded,
                  onPressed:
                      _selectedProduct != null &&
                          _quantity < _selectedProduct!.stockQuantity
                      ? () => _changeQuantity(1)
                      : null,
                ),
              ],
            ),
            if (_selectedProduct != null)
              const Padding(
                padding: EdgeInsets.only(top: 10),
                child: Text(
                  'Quantity cannot exceed available stock.',
                  style: TextStyle(fontSize: 11, color: _textSecondary),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSaleSummary() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            const Row(
              children: [
                Icon(Icons.receipt_long_rounded, color: _primary, size: 20),
                SizedBox(width: 8),
                Text(
                  'Sale summary',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _SummaryRow(label: 'Quantity', value: '$_quantity'),
            const SizedBox(height: 10),
            _SummaryRow(
              label: 'Selling price / unit',
              value: _selectedProduct == null
                  ? 'KSh 0.00'
                  : _formatAmount(_selectedProduct!.sellingPrice),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Divider(),
            ),
            _SummaryRow(
              label: 'Sale total',
              value: _formatAmount(_totalAmount),
              large: true,
            ),
            const SizedBox(height: 10),
            _SummaryRow(
              label: 'Expected profit',
              value: _formatAmount(_expectedProfit),
              valueColor: _expectedProfit >= 0 ? _primary : _danger,
              large: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecordButton() {
    final canRecord =
        !_isSaving &&
        _selectedProduct != null &&
        _quantity > 0 &&
        _quantity <= _selectedProduct!.stockQuantity;

    return SizedBox(
      width: double.infinity,
      height: 54,
      child: FilledButton.icon(
        onPressed: canRecord ? _recordSale : null,
        icon: _isSaving
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.point_of_sale_rounded),
        label: Text(_isSaving ? 'Recording Sale...' : 'Record Sale'),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: _softGreen,
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(
                Icons.inventory_2_outlined,
                size: 38,
                color: _primary,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'No products available',
              style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              'Add a product before recording a sale.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(
                Icons.error_outline_rounded,
                size: 40,
                color: Colors.red.shade700,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _loadProducts,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  String _formatAmount(double amount) {
    return 'KSh ${amount.toStringAsFixed(2)}';
  }
}

class _Metric extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _Metric({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 10,
            color: _textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 12,
            color: valueColor ?? _textPrimary,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final bool large;

  const _SummaryRow({
    required this.label,
    required this.value,
    this.valueColor,
    this.large = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: _textSecondary,
              fontSize: large ? 13 : 12,
              fontWeight: large ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: valueColor ?? _textPrimary,
            fontSize: large ? 16 : 13,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _QuantityButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;

  const _QuantityButton({required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: onPressed == null ? const Color(0xFFE9EEEB) : _softGreen,
      borderRadius: BorderRadius.circular(13),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(13),
        child: SizedBox(
          width: 48,
          height: 48,
          child: Icon(icon, color: onPressed == null ? Colors.grey : _primary),
        ),
      ),
    );
  }
}
