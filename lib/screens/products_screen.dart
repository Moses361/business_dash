import 'package:flutter/material.dart';

import '../models/product.dart';
import '../repositories/product_repository.dart';
import '../widgets/product_card.dart';
import 'add_product_screen.dart';
import 'product_details_screen.dart';

const Color _productsPrimary = Color(0xFF176B4D);
const Color _productsSoftGreen = Color(0xFFE1F1EA);
const Color _productsBackground = Color(0xFFF6F8F7);
const Color _productsTextPrimary = Color(0xFF17221D);
const Color _productsTextSecondary = Color(0xFF66736D);
const Color _productsWarning = Color(0xFFD58A18);
const Color _productsDanger = Color(0xFFD64545);

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  final ProductRepository _repository = ProductRepository();

  final TextEditingController _searchController = TextEditingController();

  List<Product> _products = [];
  List<Product> _filteredProducts = [];

  bool _isLoading = true;
  bool _showLowStockOnly = false;

  @override
  void initState() {
    super.initState();

    _searchController.addListener(_filterProducts);
    _loadProducts();
  }

  @override
  void dispose() {
    _searchController.removeListener(_filterProducts);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadProducts() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      final List<Product> products = await _repository.getProducts();

      if (!mounted) return;

      setState(() {
        _products = products;
        _filteredProducts = _filterList(products);
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not load products: $error'),
          backgroundColor: _productsDanger,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  List<Product> _filterList(List<Product> products) {
    final String query = _searchController.text.trim().toLowerCase();

    Iterable<Product> result = products;

    if (_showLowStockOnly) {
      result = result.where((product) => product.stockQuantity <= 5);
    }

    if (query.isEmpty) {
      return List<Product>.from(result);
    }

    return result.where((product) {
      return product.name.toLowerCase().contains(query) ||
          product.category.toLowerCase().contains(query);
    }).toList();
  }

  void _filterProducts() {
    if (!mounted) return;

    setState(() {
      _filteredProducts = _filterList(_products);
    });
  }

  void _toggleLowStock() {
    setState(() {
      _showLowStockOnly = !_showLowStockOnly;
      _filteredProducts = _filterList(_products);
    });
  }

  Future<void> _openAddProduct() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddProductScreen()),
    );

    if (!mounted) return;

    await _loadProducts();
  }

  Future<void> _openProduct(Product product) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ProductDetailsScreen(product: product)),
    );

    if (!mounted) return;

    await _loadProducts();
  }

  Future<void> _editProduct(Product product) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AddProductScreen(product: product)),
    );

    if (!mounted) return;

    await _loadProducts();
  }

  Future<void> _deleteProduct(Product product) async {
    if (product.id == null) return;

    final bool? shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete Product'),
          content: Text(
            'Are you sure you want to delete '
            '"${product.name}"?',
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
              style: FilledButton.styleFrom(backgroundColor: _productsDanger),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true) return;

    try {
      await _repository.deleteProduct(product.id!);

      if (!mounted) return;

      await _loadProducts();

      if (!mounted) return;

      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${product.name} deleted'),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
          action: SnackBarAction(
            label: 'UNDO',
            onPressed: () async {
              try {
                await _repository.insertProduct(product);

                if (!mounted) return;

                await _loadProducts();

                if (!mounted) return;

                ScaffoldMessenger.of(context).hideCurrentSnackBar();

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Product restored'),
                    behavior: SnackBarBehavior.floating,
                    duration: Duration(seconds: 2),
                  ),
                );
              } catch (error) {
                if (!mounted) return;

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Could not restore product.'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not delete product: $error'),
          backgroundColor: _productsDanger,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final int totalStock = _products.fold<int>(
      0,
      (total, product) => total + product.stockQuantity,
    );

    final int lowStockCount = _products
        .where((product) => product.stockQuantity <= 5)
        .length;

    return Scaffold(
      backgroundColor: _productsBackground,
      appBar: AppBar(
        title: const Text(
          'Products',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            onPressed: _openAddProduct,
            icon: const Icon(Icons.add_rounded),
            tooltip: 'Add product',
          ),
          IconButton(
            onPressed: _isLoading ? null : _loadProducts,
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh products',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddProduct,
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'Add Product',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadProducts,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 18),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInventorySummary(totalStock, lowStockCount),
                    const SizedBox(height: 16),
                    _buildSearchBox(),
                    const SizedBox(height: 10),
                    _buildFilterRow(lowStockCount),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Inventory',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  color: _productsTextPrimary,
                                ),
                              ),
                              SizedBox(height: 3),
                              Text(
                                'Tap a product to view its details.',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: _productsTextSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFE1E9E4)),
                          ),
                          child: Text(
                            '${_filteredProducts.length}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: _productsPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            _buildProductSliver(),
          ],
        ),
      ),
    );
  }

  Widget _buildInventorySummary(int totalStock, int lowStockCount) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Inventory overview',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: _productsTextPrimary,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _SummaryTile(
                title: 'Products',
                value: '${_products.length}',
                icon: Icons.inventory_2_rounded,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _SummaryTile(
                title: 'Units',
                value: '$totalStock',
                icon: Icons.layers_rounded,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _SummaryTile(
                title: 'Low stock',
                value: '$lowStockCount',
                icon: Icons.warning_amber_rounded,
                warning: lowStockCount > 0,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSearchBox() {
    return TextField(
      controller: _searchController,
      textInputAction: TextInputAction.search,
      decoration: const InputDecoration(
        hintText: 'Search by product or category',
        prefixIcon: Icon(Icons.search_rounded),
      ),
    );
  }

  Widget _buildFilterRow(int lowStockCount) {
    return Row(
      children: [
        ChoiceChip(
          label: const Text('All products'),
          selected: !_showLowStockOnly,
          onSelected: (_) {
            if (_showLowStockOnly) {
              _toggleLowStock();
            }
          },
        ),
        const SizedBox(width: 8),
        ChoiceChip(
          label: Text('Low stock $lowStockCount'),
          selected: _showLowStockOnly,
          onSelected: (_) {
            if (!_showLowStockOnly) {
              _toggleLowStock();
            }
          },
        ),
        const Spacer(),
        if (_searchController.text.isNotEmpty)
          Text(
            '${_filteredProducts.length} found',
            style: const TextStyle(
              fontSize: 11,
              color: _productsTextSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
      ],
    );
  }

  Widget _buildProductSliver() {
    if (_isLoading) {
      return const SliverFillRemaining(
        hasScrollBody: false,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_products.isEmpty) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: _buildEmptyState(),
      );
    }

    if (_filteredProducts.isEmpty) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: _buildNoSearchResults(),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 110),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          final Product product = _filteredProducts[index];

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: ProductCard(
              name: product.name,
              category: product.category,
              stock: product.stockQuantity,
              buyingPrice: product.buyingPrice,
              sellingPrice: product.sellingPrice,
              onTap: () => _openProduct(product),
              onEdit: () => _editProduct(product),
              onDelete: () => _deleteProduct(product),
            ),
          );
        }, childCount: _filteredProducts.length),
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
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _productsSoftGreen,
                borderRadius: BorderRadius.circular(22),
              ),
              child: const Icon(
                Icons.inventory_2_rounded,
                size: 42,
                color: _productsPrimary,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'No products yet',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 7),
            Text(
              'Add your first product '
              'to start tracking inventory.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
            const SizedBox(height: 18),
            ElevatedButton.icon(
              onPressed: _openAddProduct,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add Product'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoSearchResults() {
    final bool lowStockFilter = _showLowStockOnly;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              lowStockFilter
                  ? Icons.inventory_outlined
                  : Icons.search_off_rounded,
              size: 50,
              color: const Color(0xFF9AA59F),
            ),
            const SizedBox(height: 14),
            Text(
              lowStockFilter ? 'No low-stock products' : 'No products found',
              style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 7),
            Text(
              lowStockFilter
                  ? 'Everything currently has healthy stock levels.'
                  : 'Try another product name or category.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () {
                setState(() {
                  _showLowStockOnly = false;
                  _searchController.clear();
                  _filteredProducts = _filterList(_products);
                });
              },
              icon: const Icon(Icons.clear_rounded),
              label: const Text('Clear Filters'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryTile extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final bool warning;

  const _SummaryTile({
    required this.title,
    required this.value,
    required this.icon,
    this.warning = false,
  });

  @override
  Widget build(BuildContext context) {
    final Color iconColor = warning ? _productsWarning : _productsPrimary;

    final Color background = warning
        ? const Color(0xFFFFF3DD)
        : _productsSoftGreen;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: background,
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(icon, size: 17, color: iconColor),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: _productsTextPrimary,
              ),
            ),
            const SizedBox(height: 1),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 10,
                color: _productsTextSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
