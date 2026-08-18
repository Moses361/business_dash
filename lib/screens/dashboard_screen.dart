import 'package:flutter/material.dart';

import '../repositories/expense_repository.dart';
import '../repositories/product_repository.dart';
import '../repositories/sale_repository.dart';
import 'expenses_screen.dart';
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
  final ExpenseRepository _expenseRepository = ExpenseRepository();

  int _productCount = 0;
  int _lowStockCount = 0;

  double _todaySales = 0.0;
  double _todayExpenses = 0.0;

  bool _isLoading = true;
  String? _errorMessage;

  double get _todayProfit => _todaySales - _todayExpenses;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final results = await Future.wait([
        _productRepository.getProductCount(),
        _productRepository.getLowStockCount(),
        _saleRepository.getTodaySales(),
        _expenseRepository.getTodayExpenses(),
      ]);

      if (!mounted) return;

      setState(() {
        _productCount = results[0] as int;
        _lowStockCount = results[1] as int;
        _todaySales = results[2] as double;
        _todayExpenses = results[3] as double;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load dashboard data.';
      });
    }
  }

  Future<void> _openRecordSale(BuildContext context) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const RecordSaleScreen()),
    );

    if (!mounted) return;

    await _loadDashboardData();
  }

  Future<void> _openProducts(BuildContext context) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ProductsScreen()),
    );

    if (!mounted) return;

    await _loadDashboardData();
  }

  Future<void> _openExpenses(BuildContext context) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ExpensesScreen()),
    );

    if (!mounted) return;

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

  String _formatAmount(double amount) {
    return 'KSh ${amount.toStringAsFixed(2)}';
  }

  @override
  Widget build(BuildContext context) {
    final bool hasError = _errorMessage != null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Business Dashboard'),
        actions: [
          IconButton(
            onPressed: _isLoading ? null : _loadDashboardData,
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh dashboard',
          ),
        ],
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
                style: TextStyle(fontSize: 15, color: Colors.grey.shade700),
              ),

              const SizedBox(height: 24),

              if (hasError)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.shade100),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: Colors.red.shade700),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(color: Colors.red.shade800),
                        ),
                      ),
                    ],
                  ),
                ),

              const Text(
                'Today',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 12),

              _DashboardStatCard(
                title: "Today's Sales",
                value: _isLoading ? '...' : _formatAmount(_todaySales),
                icon: Icons.point_of_sale_outlined,
              ),

              const SizedBox(height: 12),

              _DashboardStatCard(
                title: "Today's Expenses",
                value: _isLoading ? '...' : _formatAmount(_todayExpenses),
                icon: Icons.receipt_long_outlined,
                iconBackgroundColor: Colors.red.shade50,
                iconColor: Colors.red.shade700,
              ),

              const SizedBox(height: 12),

              _DashboardStatCard(
                title: "Today's Profit",
                value: _isLoading ? '...' : _formatAmount(_todayProfit),
                icon: _todayProfit >= 0
                    ? Icons.trending_up_rounded
                    : Icons.trending_down_rounded,
                iconBackgroundColor: _todayProfit >= 0
                    ? Colors.green.shade50
                    : Colors.red.shade50,
                iconColor: _todayProfit >= 0
                    ? Colors.green.shade700
                    : Colors.red.shade700,
              ),

              const SizedBox(height: 28),

              const Text(
                'Business Overview',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 12),

              _DashboardStatCard(
                title: 'Products',
                value: _isLoading ? '...' : '$_productCount',
                icon: Icons.inventory_2_outlined,
              ),

              const SizedBox(height: 12),

              _DashboardStatCard(
                title: 'Low Stock',
                value: _isLoading ? '...' : '$_lowStockCount',
                icon: Icons.warning_amber_rounded,
                iconBackgroundColor: _lowStockCount > 0
                    ? Colors.orange.shade50
                    : Colors.green.shade50,
                iconColor: _lowStockCount > 0
                    ? Colors.orange.shade700
                    : Colors.green.shade700,
              ),

              const SizedBox(height: 28),

              const Text(
                'Quick Actions',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
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

              const SizedBox(height: 12),

              SizedBox(
                width: double.infinity,
                height: 54,
                child: OutlinedButton.icon(
                  onPressed: () => _openExpenses(context),
                  icon: const Icon(Icons.receipt_long_outlined),
                  label: const Text('Manage Expenses'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(54),
                  ),
                ),
              ),

              const SizedBox(height: 20),
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
  final Color? iconBackgroundColor;
  final Color? iconColor;

  const _DashboardStatCard({
    required this.title,
    required this.value,
    required this.icon,
    this.iconBackgroundColor,
    this.iconColor,
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
                color: iconBackgroundColor ?? Colors.green.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: iconColor ?? Colors.green.shade700,
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
                    style: TextStyle(color: Colors.grey.shade700, fontSize: 15),
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
