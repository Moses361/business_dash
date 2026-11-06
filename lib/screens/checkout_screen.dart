import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/checkout_models.dart';
import '../models/product.dart';
import '../repositories/product_repository.dart';
import '../repositories/sale_repository.dart';

const Color _checkoutGreen = Color(0xFF176B4D);
const Color _checkoutBackground = Color(0xFFF6F8F7);
const Color _checkoutText = Color(0xFF17221D);
const Color _checkoutMuted = Color(0xFF66736D);

class CheckoutScreen extends StatefulWidget {
  final ProductRepository? productRepository;
  final SaleRepository? saleRepository;

  const CheckoutScreen({
    super.key,
    this.productRepository,
    this.saleRepository,
  });

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  late final ProductRepository _productRepository;
  late final SaleRepository _saleRepository;

  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _cashController = TextEditingController();
  final TextEditingController _mpesaController = TextEditingController();
  final TextEditingController _mpesaReferenceController =
      TextEditingController();

  List<Product> _products = [];
  final Map<int, int> _cart = {};

  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _productRepository = widget.productRepository ?? ProductRepository();
    _saleRepository = widget.saleRepository ?? SaleRepository();

    _searchController.addListener(_refresh);
    _cashController.addListener(_refresh);
    _mpesaController.addListener(_refresh);

    _loadProducts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _cashController.dispose();
    _mpesaController.dispose();
    _mpesaReferenceController.dispose();
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  double _parseAmount(String value) {
    return double.tryParse(value.trim()) ?? 0;
  }

  double get _total {
    double total = 0;

    for (final entry in _cart.entries) {
      final matches = _products.where((p) => p.id == entry.key);
      if (matches.isNotEmpty) {
        total += matches.first.sellingPrice * entry.value;
      }
    }

    return double.parse(total.toStringAsFixed(2));
  }

  double get _cash => _parseAmount(_cashController.text);
  double get _mpesa => _parseAmount(_mpesaController.text);
  double get _paid => double.parse((_cash + _mpesa).toStringAsFixed(2));
  double get _balance => double.parse((_total - _paid).toStringAsFixed(2));

  int get _itemCount => _cart.values.fold(0, (sum, quantity) => sum + quantity);

  List<Product> get _filteredProducts {
    final query = _searchController.text.trim().toLowerCase();

    return _products.where((product) {
      return query.isEmpty ||
          product.name.toLowerCase().contains(query) ||
          (product.brand ?? '').toLowerCase().contains(query) ||
          (product.strength ?? '').toLowerCase().contains(query) ||
          (product.size ?? '').toLowerCase().contains(query) ||
          (product.productType ?? '').toLowerCase().contains(query) ||
          product.category.toLowerCase().contains(query);
    }).toList();
  }

  Future<void> _loadProducts() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final products = await _productRepository.getProducts();
      if (!mounted) return;

      final availableIds = products.map((p) => p.id).toSet();

      setState(() {
        _products = products;
        _cart.removeWhere((id, _) => !availableIds.contains(id));
        _cart.updateAll((id, quantity) {
          final product = products.firstWhere((p) => p.id == id);
          return quantity > product.stockQuantity
              ? product.stockQuantity
              : quantity;
        });
        _cart.removeWhere((_, quantity) => quantity <= 0);
        _isLoading = false;
      });
    } catch (error) {
      debugPrint('Checkout product loading error: $error');
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage = 'Could not load products. Please try again.';
      });
    }
  }

  void _addProduct(Product product) {
    final id = product.id;
    if (id == null || product.stockQuantity <= 0) {
      _showMessage('This product is out of stock.', isError: true);
      return;
    }

    final currentQuantity = _cart[id] ?? 0;

    if (currentQuantity >= product.stockQuantity) {
      _showMessage('You have reached the available stock quantity.');
      return;
    }

    setState(() => _cart[id] = currentQuantity + 1);
  }

  void _changeQuantity(Product product, int change) {
    final id = product.id;
    if (id == null) return;

    final nextQuantity = (_cart[id] ?? 0) + change;

    if (nextQuantity <= 0) {
      setState(() => _cart.remove(id));
      return;
    }

    if (nextQuantity > product.stockQuantity) {
      _showMessage('Only ${product.stockQuantity} units are available.');
      return;
    }

    setState(() => _cart[id] = nextQuantity);
  }

  void _clearCart() {
    setState(() => _cart.clear());
  }

  Future<void> _submitCheckout() async {
    FocusScope.of(context).unfocus();

    if (_cart.isEmpty) {
      _showMessage('Add at least one product to the cart.', isError: true);
      return;
    }

    if (_cash < 0 || _mpesa < 0) {
      _showMessage('Payment amounts cannot be negative.', isError: true);
      return;
    }

    if ((_cash > 0 && !_cash.isFinite) || (_mpesa > 0 && !_mpesa.isFinite)) {
      _showMessage('Enter valid payment amounts.', isError: true);
      return;
    }

    if (_paid > _total + 0.001) {
      _showMessage(
        'Payment exceeds the order total. Please correct the amounts.',
        isError: true,
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Confirm checkout'),
        content: Text(
          'Order total: ${_money(_total)}\n'
          'Amount paid: ${_money(_paid)}\n'
          'Balance due: ${_money(_balance)}\n\n'
          'Confirm this order and update stock?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Review order'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Confirm order'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isSaving = true);

    try {
      final payments = <CheckoutPaymentInput>[];

      if (_cash > 0) {
        payments.add(
          CheckoutPaymentInput(
            method: CheckoutPaymentMethod.cash,
            amount: _cash,
          ),
        );
      }

      if (_mpesa > 0) {
        payments.add(
          CheckoutPaymentInput(
            method: CheckoutPaymentMethod.mpesa,
            amount: _mpesa,
            reference: _mpesaReferenceController.text.trim(),
          ),
        );
      }

      final result = await _saleRepository.checkout(
        items: _cart.entries
            .map(
              (entry) =>
                  CheckoutCartItem(productId: entry.key, quantity: entry.value),
            )
            .toList(),
        payments: payments,
      );

      if (!mounted) return;

      setState(() {
        _cart.clear();
        _cashController.clear();
        _mpesaController.clear();
        _mpesaReferenceController.clear();
      });

      await _loadProducts();
      if (!mounted) return;

      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => AlertDialog(
          icon: const Icon(
            Icons.check_circle_outline,
            color: _checkoutGreen,
            size: 42,
          ),
          title: const Text('Order saved'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Order total: ${_money(result.totalAmount)}'),
              Text('Amount paid: ${_money(result.amountPaid)}'),
              Text(
                'Balance due: ${_money(result.balanceDue)}',
                style: TextStyle(
                  color: result.balanceDue > 0
                      ? Colors.deepOrange
                      : _checkoutGreen,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Payment entries are recorded manually. '
                'This does not verify an M-Pesa transaction.',
                style: TextStyle(fontSize: 12, color: _checkoutMuted),
              ),
            ],
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Continue'),
            ),
          ],
        ),
      );
    } catch (error) {
      debugPrint('Checkout save error: $error');
      if (!mounted) return;

      _showMessage(
        'Could not complete checkout. ${_checkoutError(error)}',
        isError: true,
      );
      await _loadProducts();
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  String _checkoutError(Object error) {
    if (error is StateError) return error.message.toString();
    if (error is ArgumentError) return error.message.toString();
    return 'Please review stock and payment amounts, then try again.';
  }

  String _money(double amount) => 'KSh ${amount.toStringAsFixed(2)}';

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red.shade700 : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _checkoutBackground,
      appBar: AppBar(
        title: const Text('Checkout'),
        backgroundColor: _checkoutGreen,
        foregroundColor: Colors.white,
        actions: [
          if (_cart.isNotEmpty)
            IconButton(
              tooltip: 'Clear cart',
              onPressed: _isSaving ? null : _clearCart,
              icon: const Icon(Icons.delete_outline),
            ),
          IconButton(
            tooltip: 'Refresh products',
            onPressed: _isLoading || _isSaving ? null : _loadProducts,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? _errorView()
          : Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // Keep the cart immediately below search so staff can
                      // review the order without scrolling past the catalogue.
                      _buildProductSection(),
                      const SizedBox(height: 16),
                      _buildCartSection(),
                      const SizedBox(height: 20),
                      _buildProductResultsSection(),
                      const SizedBox(height: 20),
                      _buildPaymentSection(),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
                _buildBottomSummary(),
              ],
            ),
    );
  }

  Widget _errorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_outlined, size: 42),
            const SizedBox(height: 12),
            Text(_errorMessage!, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _loadProducts,
              icon: const Icon(Icons.refresh),
              label: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Find products',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: _checkoutText,
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _searchController,
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            hintText: 'Search name, brand, strength, size or category',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: _searchController.text.isEmpty
                ? null
                : IconButton(
                    tooltip: 'Clear search',
                    onPressed: _searchController.clear,
                    icon: const Icon(Icons.close),
                  ),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProductResultsSection() {
    final products = _filteredProducts;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Available products',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: _checkoutText,
                ),
              ),
            ),
            Text(
              '${products.length} found',
              style: const TextStyle(color: _checkoutMuted, fontSize: 12),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (products.isEmpty)
          _emptyCard(
            _products.isEmpty
                ? 'No products available yet. Add products before checkout.'
                : 'No products match your search.',
            Icons.inventory_2_outlined,
          )
        else
          ...products.map(_buildProductCard),
      ],
    );
  }

  String _variantSummary(Product product) {
    return [product.brand, product.strength, product.size, product.productType]
        .map((value) => value?.trim() ?? '')
        .where((value) => value.isNotEmpty)
        .join(' \u2022 ');
  }

  Widget _buildProductCard(Product product) {
    final id = product.id;
    final quantity = id == null ? 0 : (_cart[id] ?? 0);
    final outOfStock = product.stockQuantity <= 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE1F1EA),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.inventory_2_outlined,
                    color: _checkoutGreen,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: _checkoutText,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        product.category,
                        style: const TextStyle(
                          fontSize: 12,
                          color: _checkoutMuted,
                        ),
                      ),
                      if (_variantSummary(product).isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          _variantSummary(product),
                          style: const TextStyle(
                            fontSize: 12,
                            color: _checkoutText,
                          ),
                        ),
                      ],
                      const SizedBox(height: 4),
                      Text(
                        _money(product.sellingPrice),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _checkoutGreen,
                        ),
                      ),
                      Text(
                        outOfStock
                            ? 'Out of stock'
                            : '${product.stockQuantity} in stock',
                        style: TextStyle(
                          fontSize: 12,
                          color: outOfStock ? Colors.red : _checkoutMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: quantity == 0
                  ? FilledButton(
                      onPressed: outOfStock || _isSaving
                          ? null
                          : () => _addProduct(product),
                      style: FilledButton.styleFrom(
                        backgroundColor: _checkoutGreen,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 22,
                          vertical: 10,
                        ),
                      ),
                      child: const Text('Add to order'),
                    )
                  : Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      children: [
                        OutlinedButton(
                          onPressed: _isSaving
                              ? null
                              : () => _changeQuantity(product, -1),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 9,
                            ),
                            minimumSize: Size.zero,
                          ),
                          child: const Text('Remove'),
                        ),
                        Text(
                          '$quantity',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        FilledButton(
                          onPressed: _isSaving
                              ? null
                              : () => _changeQuantity(product, 1),
                          style: FilledButton.styleFrom(
                            backgroundColor: _checkoutGreen,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 9,
                            ),
                            minimumSize: Size.zero,
                          ),
                          child: const Text('Add'),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCartSection() {
    final cartProducts = _products
        .where((product) => product.id != null && _cart.containsKey(product.id))
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Order items',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: _checkoutText,
                ),
              ),
            ),
            Text(
              '$_itemCount item${_itemCount == 1 ? '' : 's'}',
              style: const TextStyle(color: _checkoutMuted),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (cartProducts.isEmpty)
          _emptyCard(
            'Your cart is empty. Add products above.',
            Icons.shopping_cart_outlined,
          )
        else
          Card(
            color: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(color: Colors.grey.shade200),
            ),
            child: Column(
              children: [
                for (int index = 0; index < cartProducts.length; index++) ...[
                  if (index > 0) const Divider(height: 1),
                  _buildCartItem(cartProducts[index]),
                ],
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildCartItem(Product product) {
    final id = product.id!;
    final quantity = _cart[id] ?? 0;
    final lineTotal = product.sellingPrice * quantity;

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            product.name,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          if (_variantSummary(product).isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              _variantSummary(product),
              style: const TextStyle(fontSize: 12, color: _checkoutMuted),
            ),
          ],
          const SizedBox(height: 4),
          Text(
            '${_money(product.sellingPrice)} × $quantity',
            style: const TextStyle(fontSize: 12, color: _checkoutMuted),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: Text(
                  _money(lineTotal),
                  style: const TextStyle(
                    color: _checkoutGreen,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
              OutlinedButton(
                onPressed: _isSaving
                    ? null
                    : () => _changeQuantity(product, -1),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  minimumSize: Size.zero,
                ),
                child: const Text('Remove'),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Text(
                  '$quantity',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              FilledButton(
                onPressed: _isSaving ? null : () => _changeQuantity(product, 1),
                style: FilledButton.styleFrom(
                  backgroundColor: _checkoutGreen,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  minimumSize: Size.zero,
                ),
                child: const Text('Add'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Payment',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: _checkoutText,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Enter the amounts received. You can split payment or leave a balance due.',
          style: TextStyle(color: _checkoutMuted),
        ),
        const SizedBox(height: 12),
        _paymentInput(
          label: 'Cash received (KSh)',
          controller: _cashController,
          icon: Icons.payments_outlined,
        ),
        const SizedBox(height: 10),
        _paymentInput(
          label: 'M-Pesa received (KSh)',
          controller: _mpesaController,
          icon: Icons.phone_android,
        ),
        if (_mpesa > 0) ...[
          const SizedBox(height: 10),
          TextField(
            controller: _mpesaReferenceController,
            decoration: InputDecoration(
              labelText: 'M-Pesa transaction reference (optional)',
              hintText: 'Enter reference if available',
              prefixIcon: const Icon(Icons.receipt_long_outlined),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ],
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            children: [
              _summaryRow('Order total', _money(_total)),
              const SizedBox(height: 8),
              _summaryRow('Amount paid', _money(_paid)),
              const Divider(height: 22),
              _summaryRow(
                'Balance due',
                _money(_balance < 0 ? 0 : _balance),
                emphasize: true,
                valueColor: _balance > 0 ? Colors.deepOrange : _checkoutGreen,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _paymentInput({
    required String label,
    required TextEditingController controller,
    required IconData icon,
  }) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
      ],
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  Widget _summaryRow(
    String label,
    String value, {
    bool emphasize = false,
    Color? valueColor,
  }) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: emphasize ? _checkoutText : _checkoutMuted,
              fontWeight: emphasize ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: valueColor ?? _checkoutText,
            fontWeight: emphasize ? FontWeight.bold : FontWeight.w600,
            fontSize: emphasize ? 17 : 14,
          ),
        ),
      ],
    );
  }

  Widget _emptyCard(String message, IconData icon) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Icon(icon, size: 30, color: _checkoutMuted),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: _checkoutMuted),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomSummary() {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$_itemCount item${_itemCount == 1 ? '' : 's'}',
                    style: const TextStyle(fontSize: 12, color: _checkoutMuted),
                  ),
                  Text(
                    _money(_total),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: _checkoutText,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            FilledButton.icon(
              onPressed: _isSaving || _cart.isEmpty ? null : _submitCheckout,
              icon: _isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.lock_outline),
              label: Text(_isSaving ? 'Saving…' : 'Checkout'),
              style: FilledButton.styleFrom(
                backgroundColor: _checkoutGreen,
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 15,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
