import 'package:flutter/material.dart';

import '../models/sale.dart';
import '../repositories/sale_repository.dart';
import 'record_sale_screen.dart';

class SalesScreen extends StatefulWidget {
  const SalesScreen({super.key});

  @override
  State<SalesScreen> createState() => _SalesScreenState();
}

class _SalesScreenState extends State<SalesScreen> {
  final SaleRepository _repository = SaleRepository();

  List<Sale> _sales = [];
  double _totalSales = 0.0;
  double _todaySales = 0.0;
  double _totalProfit = 0.0;
  double _todayProfit = 0.0;

  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadSales();
  }

  Future<void> _loadSales() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final List<Sale> sales = await _repository.getSales();
      final double totalSales = await _repository.getTotalSales();
      final double todaySales = await _repository.getTodaySales();
      final double totalProfit = await _repository.getTotalProfit();
      final double todayProfit = await _repository.getTodayProfit();

      if (!mounted) return;

      setState(() {
        _sales = sales;
        _totalSales = totalSales;
        _todaySales = todaySales;
        _totalProfit = totalProfit;
        _todayProfit = todayProfit;
        _isLoading = false;
      });
    } catch (error) {
      debugPrint('Sales loading error: $error');

      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load sales.';
      });
    }
  }

  Future<void> _openRecordSale() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const RecordSaleScreen()),
    );

    if (!mounted) return;
    await _loadSales();
  }

  String _formatAmount(double amount) {
    return 'KSh ${amount.toStringAsFixed(2)}';
  }

  String _formatDate(DateTime date) {
    final DateTime localDate = date.toLocal();

    final String day = localDate.day.toString().padLeft(2, '0');
    final String month = localDate.month.toString().padLeft(2, '0');
    final String year = localDate.year.toString();

    final int hour = localDate.hour % 12 == 0 ? 12 : localDate.hour % 12;
    final String minute = localDate.minute.toString().padLeft(2, '0');
    final String period = localDate.hour >= 12 ? 'PM' : 'AM';

    return '$day/$month/$year $hour:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sales'),
        actions: [
          IconButton(
            onPressed: _isLoading ? null : _loadSales,
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh sales',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openRecordSale,
        icon: const Icon(Icons.point_of_sale),
        label: const Text('Record Sale'),
      ),
      body: RefreshIndicator(onRefresh: _loadSales, child: _buildBody()),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 180),
          Center(
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
                    onPressed: _loadSales,
                    child: const Text('Try Again'),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      children: [
        _buildSummary(),
        const SizedBox(height: 28),
        Row(
          children: [
            const Expanded(
              child: Text(
                'Individual Sales',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            Text(
              '${_sales.length} sale${_sales.length == 1 ? '' : 's'}',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_sales.isEmpty)
          _buildEmptyState()
        else
          ..._sales.map(_buildSaleCard),
        const SizedBox(height: 100),
      ],
    );
  }

  Widget _buildSummary() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _SummaryCard(
                title: "Today's Sales",
                value: _formatAmount(_todaySales),
                icon: Icons.today_outlined,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _SummaryCard(
                title: "Today's Profit",
                value: _formatAmount(_todayProfit),
                icon: Icons.trending_up_rounded,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _SummaryCard(
                title: 'Total Sales',
                value: _formatAmount(_totalSales),
                icon: Icons.bar_chart_outlined,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _SummaryCard(
                title: 'Total Profit',
                value: _formatAmount(_totalProfit),
                icon: Icons.account_balance_wallet_outlined,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 56,
              color: Colors.grey.shade500,
            ),
            const SizedBox(height: 16),
            const Text(
              'No individual sales yet.',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              'Record a sale and it will appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSaleCard(Sale sale) {
    final double profitPerUnit = sale.sellingPrice - sale.buyingPrice;
    final double totalProfit = profitPerUnit * sale.quantity;

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.receipt_long_rounded,
                    color: Colors.green.shade700,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        sale.productName,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        _formatDate(sale.createdAt),
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Sale Total',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _formatAmount(sale.totalAmount),
                      style: TextStyle(
                        color: Colors.green.shade700,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _SaleInfo(
                    label: 'Quantity',
                    value: '${sale.quantity}',
                  ),
                ),
                Expanded(
                  child: _SaleInfo(
                    label: 'Buying Price',
                    value: _formatAmount(sale.buyingPrice),
                  ),
                ),
                Expanded(
                  child: _SaleInfo(
                    label: 'Selling Price',
                    value: _formatAmount(sale.sellingPrice),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.trending_up_rounded,
                    color: Colors.green.shade700,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Profit',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  Text(
                    _formatAmount(totalProfit),
                    style: TextStyle(
                      color: Colors.green.shade700,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Text(
              '(${_formatAmount(sale.sellingPrice)} - ${_formatAmount(sale.buyingPrice)}) × ${sale.quantity} = ${_formatAmount(totalProfit)}',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _SummaryCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: Colors.green.shade700),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}

class _SaleInfo extends StatelessWidget {
  final String label;
  final String value;

  const _SaleInfo({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
        ),
        const SizedBox(height: 5),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
      ],
    );
  }
}
