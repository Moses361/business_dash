import 'package:flutter/material.dart';

import '../models/sale.dart';

const Color _primary = Color(0xFF176B4D);
const Color _primaryDark = Color(0xFF0F513A);
const Color _softGreen = Color(0xFFE7F3ED);
const Color _background = Color(0xFFF6F8F7);
const Color _textPrimary = Color(0xFF17221D);
const Color _textSecondary = Color(0xFF68756D);
const Color _border = Color(0xFFE1E9E4);
const Color _danger = Color(0xFFD64545);

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
    final profitPerUnit = sale.sellingPrice - sale.buyingPrice;
    final isProfitable = sale.grossProfit >= 0;

    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        title: const Text(
          'Sale Details',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        backgroundColor: _background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
        children: [
          _buildHeroCard(),
          const SizedBox(height: 22),
          const _SectionHeading(
            title: 'Sale Information',
            subtitle: 'Items and timing for this transaction',
          ),
          const SizedBox(height: 12),
          _buildInformationCard(),
          const SizedBox(height: 22),
          const _SectionHeading(
            title: 'Financial Breakdown',
            subtitle: 'A summary of cost, revenue and profit',
          ),
          const SizedBox(height: 12),
          _buildFinancialCard(profitPerUnit, isProfitable),
        ],
      ),
    );
  }

  Widget _buildHeroCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_primary, _primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: _primary.withValues(alpha: 0.16),
            blurRadius: 20,
            offset: const Offset(0, 9),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.receipt_long_rounded,
                  color: Colors.white,
                  size: 25,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 11,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.13),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.18),
                  ),
                ),
                child: const Text(
                  'SALE RECORD',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text(
            'Sale Total',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            _formatAmount(sale.totalAmount),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 30,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.6,
            ),
          ),
          const SizedBox(height: 13),
          Text(
            sale.productName,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 7),
          Row(
            children: [
              const Icon(
                Icons.schedule_rounded,
                color: Colors.white70,
                size: 15,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  _formatDate(sale.createdAt),
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ),
            ],
          ),
          if (sale.id != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.only(top: 14),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: Colors.white.withValues(alpha: 0.18)),
                ),
              ),
              child: Row(
                children: [
                  const Text(
                    'SALE ID',
                    style: TextStyle(
                      color: Colors.white60,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '#${sale.id}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInformationCard() {
    return _InformationPanel(
      children: [
        _DetailRow(
          icon: Icons.inventory_2_outlined,
          label: 'Product',
          value: sale.productName,
        ),
        _DetailRow(
          icon: Icons.numbers_rounded,
          label: 'Quantity sold',
          value: '${sale.quantity} units',
        ),
        _DetailRow(
          icon: Icons.calendar_today_outlined,
          label: 'Date and time',
          value: _formatDate(sale.createdAt),
        ),
        if (sale.id != null)
          _DetailRow(
            icon: Icons.tag_rounded,
            label: 'Sale ID',
            value: '#${sale.id}',
            isLast: true,
          ),
      ],
    );
  }

  Widget _buildFinancialCard(double profitPerUnit, bool isProfitable) {
    return _InformationPanel(
      children: [
        _DetailRow(
          icon: Icons.shopping_bag_outlined,
          label: 'Buying price per unit',
          value: _formatAmount(sale.buyingPrice),
        ),
        _DetailRow(
          icon: Icons.sell_outlined,
          label: 'Selling price per unit',
          value: _formatAmount(sale.sellingPrice),
        ),
        _DetailRow(
          icon: Icons.inventory_outlined,
          label: 'Total cost',
          value: _formatAmount(sale.totalCost),
        ),
        _DetailRow(
          icon: Icons.payments_outlined,
          label: 'Sale total',
          value: _formatAmount(sale.totalAmount),
          isLast: true,
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isProfitable
                ? const Color(0xFFEAF5EE)
                : const Color(0xFFFFEEEE),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isProfitable
                  ? const Color(0xFFD5EBDD)
                  : const Color(0xFFF5D6D6),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    isProfitable
                        ? Icons.trending_up_rounded
                        : Icons.trending_down_rounded,
                    color: isProfitable ? _primary : _danger,
                    size: 21,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      isProfitable ? 'Gross Profit' : 'Gross Loss',
                      style: const TextStyle(
                        color: _textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Flexible(
                    child: Text(
                      _formatAmount(sale.grossProfit),
                      textAlign: TextAlign.end,
                      style: TextStyle(
                        color: isProfitable ? _primary : _danger,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Divider(
                height: 1,
                color: (isProfitable ? _primary : _danger).withValues(
                  alpha: 0.14,
                ),
              ),
              const SizedBox(height: 11),
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Profit per unit',
                      style: TextStyle(color: _textSecondary, fontSize: 12),
                    ),
                  ),
                  Text(
                    _formatAmount(profitPerUnit),
                    style: TextStyle(
                      color: profitPerUnit >= 0 ? _primary : _danger,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SectionHeading extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionHeading({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: _textPrimary,
            fontSize: 19,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          subtitle,
          style: const TextStyle(color: _textSecondary, fontSize: 11),
        ),
      ],
    );
  }
}

class _InformationPanel extends StatelessWidget {
  final List<Widget> children;

  const _InformationPanel({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF17221D).withValues(alpha: 0.025),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isLast;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: _softGreen,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(icon, size: 19, color: _primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: _textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Flexible(
                flex: 2,
                child: Text(
                  value,
                  textAlign: TextAlign.end,
                  style: const TextStyle(
                    color: _textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (!isLast) const Divider(height: 1, color: _border),
      ],
    );
  }
}
