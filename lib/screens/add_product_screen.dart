import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/product.dart';
import '../repositories/product_repository.dart';

class AddProductScreen extends StatefulWidget {
  final Product? product;

  const AddProductScreen({super.key, this.product});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _buyingPriceController = TextEditingController();
  final _sellingPriceController = TextEditingController();
  final _stockController = TextEditingController();

  final ProductRepository _repository = ProductRepository();

  static const Color primary = Color(0xFF176B4D);
  static const Color primaryDark = Color(0xFF0F513A);
  static const Color softGreen = Color(0xFFE1F1EA);
  static const Color background = Color(0xFFF6F8F7);
  static const Color textPrimary = Color(0xFF17221D);
  static const Color textSecondary = Color(0xFF66736D);
  static const Color danger = Color(0xFFD64545);

  String selectedCategory = 'Motorcycle Parts';
  bool _isSaving = false;

  bool get _isEditing => widget.product != null;

  double get _profitPreview {
    final buying = double.tryParse(_buyingPriceController.text.trim()) ?? 0;

    final selling = double.tryParse(_sellingPriceController.text.trim()) ?? 0;

    return selling - buying;
  }

  @override
  void initState() {
    super.initState();

    _buyingPriceController.addListener(_refreshPreview);
    _sellingPriceController.addListener(_refreshPreview);

    if (_isEditing) {
      final product = widget.product!;

      _nameController.text = product.name;
      _buyingPriceController.text = product.buyingPrice.toString();
      _sellingPriceController.text = product.sellingPrice.toString();
      _stockController.text = product.stockQuantity.toString();

      selectedCategory = product.category;
    }
  }

  @override
  void dispose() {
    _buyingPriceController.removeListener(_refreshPreview);
    _sellingPriceController.removeListener(_refreshPreview);

    _nameController.dispose();
    _buyingPriceController.dispose();
    _sellingPriceController.dispose();
    _stockController.dispose();

    super.dispose();
  }

  void _refreshPreview() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> saveProduct() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final product = Product(
        id: widget.product?.id,
        name: _nameController.text.trim(),
        category: selectedCategory,
        buyingPrice: double.parse(_buyingPriceController.text.trim()),
        sellingPrice: double.parse(_sellingPriceController.text.trim()),
        stockQuantity: int.parse(_stockController.text.trim()),
      );

      if (_isEditing) {
        await _repository.updateProduct(product);

        if (!mounted) return;

        Navigator.pop(context, product);
      } else {
        await _repository.insertProduct(product);

        if (!mounted) return;

        ScaffoldMessenger.of(context).hideCurrentSnackBar();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Product added successfully'),
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 2),
          ),
        );

        Navigator.pop(context);
      }
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not save product: $error'),
          backgroundColor: danger,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        title: Text(
          _isEditing ? 'Edit Product' : 'Add Product',
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: SafeArea(
        top: false,
        child: Form(
          key: _formKey,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            children: [
              _buildHeader(),

              const SizedBox(height: 18),

              _buildBasicInformation(),

              const SizedBox(height: 14),

              _buildPricingSection(),

              const SizedBox(height: 14),

              _buildStockSection(),

              const SizedBox(height: 14),

              _buildProfitPreview(),

              const SizedBox(height: 22),

              SizedBox(
                height: 54,
                child: FilledButton.icon(
                  onPressed: _isSaving ? null : saveProduct,
                  icon: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Icon(
                          _isEditing ? Icons.check_rounded : Icons.add_rounded,
                        ),
                  label: Text(
                    _isSaving
                        ? (_isEditing
                              ? 'Updating Product...'
                              : 'Saving Product...')
                        : (_isEditing ? 'Update Product' : 'Save Product'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: softGreen,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Icon(
              Icons.inventory_2_rounded,
              color: primary,
              size: 26,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isEditing ? 'Update your product' : 'Add a new product',
                  style: const TextStyle(
                    color: textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _isEditing
                      ? 'Keep pricing and stock information up to date.'
                      : 'Enter the information Veroon needs to track inventory.',
                  style: const TextStyle(
                    color: textSecondary,
                    fontSize: 12,
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

  Widget _buildBasicInformation() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionHeading(
              'Basic information',
              'Identify the product clearly.',
              Icons.info_outline_rounded,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _nameController,
              textCapitalization: TextCapitalization.words,
              enabled: !_isSaving,
              decoration: const InputDecoration(
                labelText: 'Product name',
                hintText: 'e.g. Brake Pads',
                prefixIcon: Icon(Icons.inventory_2_outlined),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a product name';
                }

                if (value.trim().length < 2) {
                  return 'Product name is too short';
                }

                return null;
              },
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              value: selectedCategory,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Category',
                prefixIcon: Icon(Icons.category_outlined),
              ),
              items: const [
                DropdownMenuItem(
                  value: 'Motorcycle Parts',
                  child: Text('Motorcycle Parts'),
                ),
                DropdownMenuItem(value: 'Agrovet', child: Text('Agrovet')),
                DropdownMenuItem(
                  value: 'Lubricants',
                  child: Text('Lubricants'),
                ),
                DropdownMenuItem(value: 'Other', child: Text('Other')),
              ],
              onChanged: _isSaving
                  ? null
                  : (value) {
                      if (value == null) return;

                      setState(() {
                        selectedCategory = value;
                      });
                    },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPricingSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionHeading(
              'Pricing',
              'Set the cost and selling price.',
              Icons.payments_outlined,
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _buyingPriceController,
                    enabled: !_isSaving,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                        RegExp(r'^\d*\.?\d{0,2}'),
                      ),
                    ],
                    decoration: const InputDecoration(
                      labelText: 'Buying price',
                      prefixText: 'KSh ',
                      prefixIcon: Icon(Icons.shopping_cart_outlined),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Required';
                      }

                      final price = double.tryParse(value.trim());

                      if (price == null || price < 0) {
                        return 'Invalid price';
                      }

                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextFormField(
                    controller: _sellingPriceController,
                    enabled: !_isSaving,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                        RegExp(r'^\d*\.?\d{0,2}'),
                      ),
                    ],
                    decoration: const InputDecoration(
                      labelText: 'Selling price',
                      prefixText: 'KSh ',
                      prefixIcon: Icon(Icons.sell_outlined),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Required';
                      }

                      final price = double.tryParse(value.trim());

                      if (price == null || price < 0) {
                        return 'Invalid price';
                      }

                      return null;
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStockSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionHeading(
              'Inventory',
              'Set the units currently available.',
              Icons.inventory_outlined,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _stockController,
              enabled: !_isSaving,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                labelText: 'Stock quantity',
                hintText: 'e.g. 15',
                suffixText: 'units',
                prefixIcon: Icon(Icons.layers_outlined),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter the stock quantity';
                }

                final stock = int.tryParse(value.trim());

                if (stock == null || stock < 0) {
                  return 'Enter a valid whole number';
                }

                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfitPreview() {
    final double profit = _profitPreview;
    final bool positive = profit >= 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: positive ? const Color(0xFFE5F3EC) : const Color(0xFFFCEAEA),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: positive ? const Color(0xFFCDE8D9) : const Color(0xFFF2CCCC),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: positive
                  ? const Color(0xFFD4ECDE)
                  : const Color(0xFFF5DADA),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              positive
                  ? Icons.trending_up_rounded
                  : Icons.trending_down_rounded,
              color: positive ? primary : danger,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Profit preview',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: textSecondary,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Expected profit per unit',
                  style: TextStyle(fontSize: 11, color: textSecondary),
                ),
              ],
            ),
          ),
          Text(
            'KSh ${profit.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: positive ? primary : danger,
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeading(String title, String subtitle, IconData icon) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: softGreen,
            borderRadius: BorderRadius.circular(11),
          ),
          child: Icon(icon, color: primary, size: 20),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 11, color: textSecondary),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
