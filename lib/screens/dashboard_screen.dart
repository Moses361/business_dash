import 'package:flutter/material.dart';

import '../repositories/product_repository.dart';
import '../repositories/sale_repository.dart';
import 'products_screen.dart';
import 'record_sale_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final ProductRepository _productRepository = ProductRepository();
  final SaleRepository _saleRepository = SaleRepository();

  int _productCount = 0;
  int _lowStockCount = 0;
  double _todaySales = 0.0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      final int productCount = await _productRepository.getProductCount();
      final int lowStockCount = await _productRepository.getLowStockCount();
      final double todaySales = await _saleRepository.getTodaySales();

      print('========================================');
      print('VEROON DASHBOARD');
      print('Products: $productCount');
      print('Low stock: $lowStockCount');
      print('Today sales: $todaySales');
      print('========================================');

      if (!mounted) return;

      setState(() {
        _productCount = productCount;
        _lowStockCount = lowStockCount;
        _todaySales = todaySales;
        _isLoading = false;
      });
    } catch (error) {
      print('========================================');
      print('VEROON DASHBOARD ERROR');
      print(error);
      print('========================================');

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _openRecordSale(BuildContext context) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const RecordSaleScreen(),
      ),
    );
    await _loadDashboardData();
  }

  Future<void> _openProducts(BuildContext context) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const ProductsScreen(),
      ),
    );
    await _loadDashboardData();
  }

  String _getGreeting() {
    final int hour = DateTime.now().hour;

    if (hour < 12) {
      return 'Good morning';
    }
    if (hour < 17) {
      return 'Good afternoon';
    }
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Business Dashboard'),
      ),
      body: RefreshIndicator(
        onRefresh: _loadDashboardData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${_getGreeting()}, Veron Wasonga 👋',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Here is your business overview for today.',
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 28),
              _DashboardStatCard(
                title: 'Products',
                value: _isLoading ? '...' : '$_productCount',
                icon: Icons.inventory_2_outlined,
              ),
              const SizedBox(height: 12),
              _DashboardStatCard(
                title: "Today's Sales",
                value: _isLoading
                    ? '...'
                    : 'KSh ${_todaySales.toStringAsFixed(2)}',
                icon: Icons.point_of_sale_outlined,
              ),
              const SizedBox(height: 12),
              _DashboardStatCard(
                title: 'Low Stock',
                value: _isLoading ? '...' : '$_lowStockCount',
                icon: Icons.warning_amber_rounded,
              ),
              const SizedBox(height: 28),
              const Text(
                'Quick Actions',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 54,
                      child: ElevatedButton.icon(
                        onPressed: () => _openRecordSale(context),
                        icon: const Icon(Icons.point_of_sale),
                        label: const Text('Record Sale'),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _openProducts(context),
                      icon: const Icon(Icons.inventory_2_outlined),
                      label: const Text('Products'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(54),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashboardStatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _DashboardStatCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: Colors.green.shade700,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
