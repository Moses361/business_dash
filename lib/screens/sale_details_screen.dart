import 'package:flutter/material.dart';

import '../models/sale.dart';

class SaleDetailsScreen extends StatelessWidget {
  final Sale sale;

  const SaleDetailsScreen({super.key, required this.sale});

  String _formatAmount(double amount) {
    return 'KSh ${amount.toStringAsFixed(2)}';
  }

  String _formatDate(DateTime date) {
    final localDate = date.toLocal();

    final day = localDate.day.toString().padLeft(2, '0');
    final month = localDate.month.toString().padLeft(2, '0');
    final year = localDate.year.toString();

    final hour = localDate.hour % 12 == 0 ? 12 : localDate.hour % 12;
    final minute = localDate.minute.toString().padLeft(2, '0');
    final period = localDate.hour >= 12 ? 'PM' : 'AM';

    return '$day/$month/$year at $hour:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
    final double profitPerUnit = sale.sellingPrice - sale.buyingPrice;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8F7),
      appBar: AppBar(
        title: const Text(
          'Sale Details',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildHeroCard(),

          const SizedBox(height: 20),

          const Text(
            'Sale Information',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 12),

          _buildInformationCard(),

          const SizedBox(height: 20),

          const Text(
            'Financial Breakdown',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 12),

          _buildFinancialCard(profitPerUnit),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildHeroCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2E7D32), Color(0xFF1B5E20)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.receipt_long_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),

          const SizedBox(height: 20),

          const Text(
            'Sale Total',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),

          const SizedBox(height: 4),

          Text(
            _formatAmount(sale.totalAmount),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 34,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            sale.productName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 4),

          Text(
            _formatDate(sale.createdAt),
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildInformationCard() {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            _DetailRow(
              icon: Icons.inventory_2_outlined,
              label: 'Product',
              value: sale.productName,
            ),
            const Divider(height: 24),
            _DetailRow(
              icon: Icons.numbers_rounded,
              label: 'Quantity',
              value: '${sale.quantity}',
            ),
            const Divider(height: 24),
            _DetailRow(
              icon: Icons.calendar_today_outlined,
              label: 'Date',
              value: _formatDate(sale.createdAt),
            ),
            if (sale.id != null) ...[
              const Divider(height: 24),
              _DetailRow(
                icon: Icons.tag_outlined,
                label: 'Sale ID',
                value: '#${sale.id}',
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFinancialCard(double profitPerUnit) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            _DetailRow(
              icon: Icons.shopping_cart_outlined,
              label: 'Buying Price',
              value: _formatAmount(sale.buyingPrice),
            ),
            const Divider(height: 24),
            _DetailRow(
              icon: Icons.point_of_sale_outlined,
              label: 'Selling Price',
              value: _formatAmount(sale.sellingPrice),
            ),
            const Divider(height: 24),
            _DetailRow(
              icon: Icons.inventory_outlined,
              label: 'Total Cost',
              value: _formatAmount(sale.totalCost),
            ),
            const Divider(height: 24),
            _DetailRow(
              icon: Icons.payments_outlined,
              label: 'Sale Total',
              value: _formatAmount(sale.totalAmount),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: sale.grossProfit >= 0
                    ? Colors.green.shade50
                    : Colors.red.shade50,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        sale.grossProfit >= 0
                            ? Icons.trending_up_rounded
                            : Icons.trending_down_rounded,
                        color: sale.grossProfit >= 0
                            ? Colors.green.shade700
                            : Colors.red.shade700,
                      ),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Gross Profit',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                      Text(
                        _formatAmount(sale.grossProfit),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: sale.grossProfit >= 0
                              ? Colors.green.shade700
                              : Colors.red.shade700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Profit per unit: ${_formatAmount(profitPerUnit)}',
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
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

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 20, color: Colors.green.shade700),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
          ),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
        ),
      ],
    );
  }
}
