import 'package:flutter/material.dart';

import '../models/sale.dart';
import '../repositories/sale_repository.dart';

const Color _primary = Color(0xFF176B4D);
const Color _primaryDark = Color(0xFF0F513A);
const Color _softGreen = Color(0xFFE7F3ED);
const Color _background = Color(0xFFF6F8F7);
const Color _textPrimary = Color(0xFF17221D);
const Color _textSecondary = Color(0xFF68756D);
const Color _border = Color(0xFFE1E9E4);
const Color _danger = Color(0xFFD64545);

class SaleDetailsScreen extends StatefulWidget {
  final Sale sale;
  final SaleRepository? saleRepository;

  const SaleDetailsScreen({super.key, required this.sale, this.saleRepository});

  @override
  State<SaleDetailsScreen> createState() => _SaleDetailsScreenState();
}

class _SaleDetailsScreenState extends State<SaleDetailsScreen> {
  late final SaleRepository _repository;
  Future<Map<String, Object?>?>? _summaryFuture;

  Sale get sale => widget.sale;

  @override
  void initState() {
    super.initState();
    _repository = widget.saleRepository ?? SaleRepository();
    _loadSummary();
  }

  void _loadSummary() {
    final id = sale.id;
    _summaryFuture = id == null ? null : _repository.getSaleReturnSummary(id);
  }

  void _refreshSummary() {
    if (!mounted) return;
    setState(_loadSummary);
  }

  Future<void> _showReturnDialog() async {
    final saleId = sale.id;
    if (saleId == null) return;

    final quantityController = TextEditingController();
    final restockedController = TextEditingController();
    final reasonController = TextEditingController();

    try {
      final result = await showDialog<Map<String, Object?>>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text('Return ${sale.productName}'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Original quantity: ${sale.quantity} units',
                  style: const TextStyle(color: _textSecondary),
                ),
                TextField(
                  controller: quantityController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Quantity being returned',
                  ),
                ),
                TextField(
                  controller: restockedController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Quantity suitable for resale',
                    helperText: 'Enter 0 if all returned goods are damaged.',
                  ),
                ),
                TextField(
                  controller: reasonController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Return reason (required)',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final quantity = int.tryParse(quantityController.text.trim());
                final restocked = int.tryParse(restockedController.text.trim());
                final reason = reasonController.text.trim();

                if (quantity == null ||
                    quantity <= 0 ||
                    restocked == null ||
                    restocked < 0 ||
                    restocked > quantity ||
                    reason.isEmpty) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    const SnackBar(
                      content: Text('Enter valid quantities and a reason.'),
                    ),
                  );
                  return;
                }

                Navigator.pop(dialogContext, {
                  'quantity': quantity,
                  'restocked': restocked,
                  'reason': reason,
                });
              },
              child: const Text('Record return'),
            ),
          ],
        ),
      );

      if (result == null) return;

      await _repository.recordReturn(
        saleId: saleId,
        quantity: result['quantity'] as int,
        restockedQuantity: result['restocked'] as int,
        reason: result['reason'] as String,
      );

      _refreshSummary();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Customer return recorded.')),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not record return: $error')),
        );
      }
    } finally {
      quantityController.dispose();
      restockedController.dispose();
      reasonController.dispose();
    }
  }

  Future<void> _showCancelDialog() async {
    final saleId = sale.id;
    if (saleId == null) return;

    final reasonController = TextEditingController();
    final isOrder = sale.orderSyncId != null;

    try {
      final reason = await showDialog<String>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(isOrder ? 'Cancel entire order?' : 'Cancel this sale?'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                isOrder
                    ? 'This sale belongs to a checkout order. '
                          'The entire order will be cancelled.'
                    : 'This sale will be cancelled and its stock restored.',
              ),
              const SizedBox(height: 12),
              TextField(
                controller: reasonController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Cancellation reason (required)',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Keep sale'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: _danger),
              onPressed: () {
                final value = reasonController.text.trim();
                if (value.isEmpty) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    const SnackBar(
                      content: Text('A cancellation reason is required.'),
                    ),
                  );
                  return;
                }
                Navigator.pop(dialogContext, value);
              },
              child: const Text('Confirm cancellation'),
            ),
          ],
        ),
      );

      if (reason == null) return;

      await _repository.cancelSale(saleId: saleId, reason: reason);
      _refreshSummary();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isOrder ? 'Entire order cancelled.' : 'Sale cancelled.',
            ),
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not cancel sale: $error')),
        );
      }
    } finally {
      reasonController.dispose();
    }
  }

  Widget _buildReturnActions() {
    return FutureBuilder<Map<String, Object?>?>(
      future: _summaryFuture,
      builder: (context, snapshot) {
        final summary = snapshot.data;
        final isCancelled = summary?['status'] == 'cancelled';
        final returned = (summary?['returned_quantity'] as num?)?.toInt() ?? 0;
        final remaining =
            (summary?['remaining_quantity'] as num?)?.toInt() ?? sale.quantity;
        final refund = (summary?['refund_amount'] as num?)?.toDouble() ?? 0;
        final returns = (summary?['returns'] as List?) ?? [];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _SectionHeading(
              title: 'Returns and Adjustments',
              subtitle: 'Return history and transaction actions',
            ),
            const SizedBox(height: 12),
            _InformationPanel(
              children: [
                _DetailRow(
                  icon: Icons.assignment_return_outlined,
                  label: 'Quantity returned',
                  value: '$returned units',
                ),
                _DetailRow(
                  icon: Icons.inventory_2_outlined,
                  label: 'Quantity remaining',
                  value: '$remaining units',
                ),
                _DetailRow(
                  icon: Icons.money_off_outlined,
                  label: 'Refund recorded',
                  value: _formatAmount(refund),
                  isLast: true,
                ),
                if (isCancelled)
                  const _DetailRow(
                    icon: Icons.cancel_outlined,
                    label: 'Sale status',
                    value: 'Cancelled',
                    isLast: true,
                  ),
                if (returns.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Return history',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: _textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        for (final item in returns)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Text(
                              '${item['quantity']} units · '
                              '${item['reason']} · '
                              'Refund: ${_formatAmount((item['refund_amount'] as num?)?.toDouble() ?? 0)}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: _textSecondary,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
              ],
            ),
            if (!isCancelled && remaining > 0) ...[
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _showReturnDialog,
                  icon: const Icon(Icons.assignment_return_outlined),
                  label: const Text('Record customer return'),
                  style: FilledButton.styleFrom(
                    backgroundColor: _primary,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                  ),
                ),
              ),
            ],
            if (!isCancelled && returned == 0) ...[
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _showCancelDialog,
                  icon: const Icon(Icons.cancel_outlined, color: _danger),
                  label: Text(
                    sale.orderSyncId != null
                        ? 'Cancel entire order'
                        : 'Cancel sale',
                    style: const TextStyle(color: _danger),
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildAdjustedFinancialCard() {
    return FutureBuilder<Map<String, Object?>?>(
      future: _summaryFuture,
      builder: (context, snapshot) {
        final summary = snapshot.data;
        final refund = (summary?['refund_amount'] as num?)?.toDouble() ?? 0;
        final restocked =
            (summary?['restocked_quantity'] as num?)?.toInt() ?? 0;

        final isCancelled = summary?['status'] == '''cancelled''';
        final netRevenue = isCancelled ? 0.0 : sale.totalAmount - refund;
        final adjustedCost = isCancelled
            ? 0.0
            : sale.buyingPrice * (sale.quantity - restocked);
        final adjustedProfit = isCancelled ? 0.0 : netRevenue - adjustedCost;

        return _buildFinancialCard(
          sale.sellingPrice - sale.buyingPrice,
          adjustedProfit >= 0,
          netRevenue: netRevenue,
          adjustedCost: adjustedCost,
          adjustedProfit: adjustedProfit,
        );
      },
    );
  }

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
          _buildReturnActions(),
          const SizedBox(height: 22),
          const _SectionHeading(
            title: 'Financial Breakdown',
            subtitle: 'A summary of cost, revenue and profit after returns',
          ),
          const SizedBox(height: 12),
          _buildAdjustedFinancialCard(),
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

  Widget _buildFinancialCard(
    double profitPerUnit,
    bool isProfitable, {
    double? netRevenue,
    double? adjustedCost,
    double? adjustedProfit,
  }) {
    final displayedRevenue = netRevenue ?? sale.totalAmount;
    final displayedCost = adjustedCost ?? sale.totalCost;
    final displayedProfit = adjustedProfit ?? sale.grossProfit;

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
          value: _formatAmount(displayedCost),
        ),
        _DetailRow(
          icon: Icons.payments_outlined,
          label: 'Sale total',
          value: _formatAmount(displayedRevenue),
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
                      _formatAmount(displayedProfit),
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
