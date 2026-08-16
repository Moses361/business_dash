import 'package:flutter/material.dart';

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

  String selectedCategory = 'Motorcycle Parts';
  bool _isSaving = false;

  bool get _isEditing => widget.product != null;

  @override
  void initState() {
    super.initState();

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
    _nameController.dispose();
    _buyingPriceController.dispose();
    _sellingPriceController.dispose();
    _stockController.dispose();
    super.dispose();
  }

  Future<void> saveProduct() async {
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
        if (!mounted) {
          return;
        }

        Navigator.pop(context, product);
      } else {
        final id = await _repository.insertProduct(product);

        if (!mounted) {
          return;
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Product saved successfully (ID: $id)')),
        );

        Navigator.pop(context);
      }
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not save product: $error'),
          backgroundColor: Colors.red,
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
      appBar: AppBar(title: Text(_isEditing ? 'Edit Product' : 'Add Product')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              _isEditing ? 'Update Product Details' : 'Product Information',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 8),

            Text(
              _isEditing
                  ? 'Update the selected product details.'
                  : 'Enter the details of your new product.',
              style: TextStyle(color: Colors.grey.shade600),
            ),

            const SizedBox(height: 24),

            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Product name',
                hintText: 'e.g. Brake Pads',
                prefixIcon: Icon(Icons.inventory_2_outlined),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a product name';
                }

                return null;
              },
            ),

            const SizedBox(height: 16),

            DropdownButtonFormField<String>(
              initialValue: selectedCategory,
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
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    selectedCategory = value;
                  });
                }
              },
            ),

            const SizedBox(height: 16),

            TextFormField(
              controller: _buyingPriceController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Buying price',
                prefixText: 'KSh ',
                prefixIcon: Icon(Icons.shopping_cart_outlined),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter the buying price';
                }

                final price = double.tryParse(value.trim());

                if (price == null || price < 0) {
                  return 'Enter a valid price';
                }

                return null;
              },
            ),

            const SizedBox(height: 16),

            TextFormField(
              controller: _sellingPriceController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Selling price',
                prefixText: 'KSh ',
                prefixIcon: Icon(Icons.sell_outlined),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter the selling price';
                }

                final price = double.tryParse(value.trim());

                if (price == null || price < 0) {
                  return 'Enter a valid price';
                }

                return null;
              },
            ),

            const SizedBox(height: 16),

            TextFormField(
              controller: _stockController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Stock quantity',
                hintText: 'e.g. 15',
                prefixIcon: Icon(Icons.inventory_outlined),
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

            const SizedBox(height: 32),

            SizedBox(
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _isSaving ? null : saveProduct,
                icon: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save_outlined),
                label: Text(
                  _isSaving
                      ? (_isEditing ? 'Updating...' : 'Saving...')
                      : (_isEditing ? 'Update Product' : 'Save Product'),
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
