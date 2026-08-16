import 'package:flutter/material.dart';

import '../models/sale.dart';
import '../repositories/sale_repository.dart';

class SalesScreen extends StatefulWidget {
  const SalesScreen({super.key});

  @override
  State<SalesScreen> createState() => _SalesScreenState();
}

class _SalesScreenState extends State<SalesScreen> {
  final SaleRepository _saleRepository = SaleRepository();

  List<Sale> _sales = [];
  double _totalSales = 0.0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSales();
  }

  Future<void> _loadSales() async {
    setState(() {
      _isLoading = true;
    });

    final sales = await _saleRepository.getSales();
    final totalSales = await _saleRepository.getTotalSales();

    if (!mounted) {
      return;
    }

    setState(() {
      _sales = sales;
      _totalSales = totalSales;
      _isLoading = false;
    });
  }

  String _formatAmount(double amount) {
    return 'KSh ${amount.toStringAsFixed(2)}';
  }

  String _formatDateTime(DateTime dateTime) {
    final hour = dateTime.hour == 0
        ? 12
        : dateTime.hour > 12
        ? dateTime.hour - 12
        : dateTime.hour;

    final minute = dateTime.minute.toString().padLeft(2, '0');
    final period = dateTime.hour >= 12 ? 'PM' : 'AM';

    return 'Today • $hour:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8F7),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Sales',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        actions: [
          IconButton(
            onPressed: _loadSales,
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh sales',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadSales,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF146B4A), Color(0xFF0B4D36)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.green.withValues(alpha: 0.2),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(
                              Icons.trending_up_rounded,
                              color: Colors.white,
                              size: 22,
                            ),
                            SizedBox(width: 8),
                            Text(
                              "Total Sales",
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _formatAmount(_totalSales),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _sales.isEmpty
                              ? 'No sales recorded yet.'
                              : '${_sales.length} transaction${_sales.length == 1 ? '' : 's'} recorded.',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Recent transactions',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (_sales.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: Colors.black.withValues(alpha: 0.06),
                        ),
                      ),
                      child: const Column(
                        children: [
                          Icon(
                            Icons.receipt_long_outlined,
                            size: 48,
                            color: Colors.grey,
                          ),
                          SizedBox(height: 12),
                          Text(
                            'No sales recorded yet',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          SizedBox(height: 6),
                          Text(
                            'Recorded sales will appear here.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    )
                  else
                    ..._sales.map(
                      (sale) => _SaleTransactionTile(
                        title: sale.productName,
                        subtitle:
                            '${sale.quantity} × ${_formatAmount(sale.sellingPrice)} • '
                            '${_formatDateTime(sale.createdAt)}',
                        amount: _formatAmount(sale.totalAmount),
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}

class _SaleTransactionTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final String amount;

  const _SaleTransactionTile({
    required this.title,
    required this.subtitle,
    required this.amount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.receipt_long_rounded,
              color: Colors.green,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            amount,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: Colors.green,
            ),
          ),
        ],
      ),
    );
  }
}
