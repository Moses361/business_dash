import 'package:flutter/material.dart';

import '../repositories/sale_repository.dart';

class OrderDetailsScreen extends StatefulWidget {
  final String orderSyncId;
  final SaleRepository? saleRepository;

  const OrderDetailsScreen({
    super.key,
    required this.orderSyncId,
    this.saleRepository,
  });

  @override
  State<OrderDetailsScreen> createState() => _OrderDetailsScreenState();
}

class _OrderDetailsScreenState extends State<OrderDetailsScreen> {
  late final SaleRepository _repository;
  late Future<Map<String, Object?>?> _orderFuture;

  static const Color _green = Color(0xFF176B4D);

  @override
  void initState() {
    super.initState();
    _repository = widget.saleRepository ?? SaleRepository();
    _orderFuture = _repository.getOrderDetails(widget.orderSyncId);
  }

  double _amount(Object? value) {
    return value is num ? value.toDouble() : 0;
  }

  int _quantity(Object? value) {
    return value is num ? value.toInt() : 0;
  }

  String _money(double value) => 'KSh ${value.toStringAsFixed(2)}';

  String _date(Object? value) {
    if (value == null) return 'Date unavailable';

    final parsed = DateTime.tryParse(value.toString());
    if (parsed == null) return value.toString();

    return parsed.toLocal().toString().replaceFirst('T', ' ').split('.').first;
  }

  void _refreshOrder() {
    if (!mounted) return;
    setState(() {
      _orderFuture = _repository.getOrderDetails(widget.orderSyncId);
    });
  }

  Future<void> _showReturnDialog(Map<String, Object?> sale) async {
    final saleId = (sale['id'] as num?)?.toInt();
    if (saleId == null) return;

    final quantityController = TextEditingController();
    final restockedController = TextEditingController();
    final reasonController = TextEditingController();

    try {
      final result = await showDialog<Map<String, Object?>>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text('Return ${sale['product_name'] ?? 'product'}'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
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
                    helperText: 'Enter 0 for entirely damaged goods.',
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
                      content: Text(
                        'Enter valid quantities and a return reason.',
                      ),
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

      _refreshOrder();

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

  Future<void> _showCancelDialog(List<Map<String, Object?>> sales) async {
    if (sales.isEmpty) return;

    final saleId = (sales.first['id'] as num?)?.toInt();
    if (saleId == null) return;

    final reasonController = TextEditingController();

    try {
      final reason = await showDialog<String>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Cancel entire order?'),
          content: TextField(
            controller: reasonController,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Cancellation reason (required)',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Keep order'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
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

      _refreshOrder();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Order cancelled successfully.')),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not cancel order: $error')),
        );
      }
    } finally {
      reasonController.dispose();
    }
  }

  Widget _buildSaleLine(Map<String, Object?> sale, bool isCancelled) {
    final saleId = (sale['id'] as num?)?.toInt();
    final originalQuantity = _quantity(sale['quantity']);

    if (saleId == null) {
      return ListTile(
        title: Text(sale['product_name']?.toString() ?? 'Product'),
        subtitle: Text('$originalQuantity units'),
        trailing: Text(_money(_amount(sale['total_amount']))),
      );
    }

    return FutureBuilder<Map<String, Object?>>(
      future: _repository.getSaleReturnSummary(saleId),
      builder: (context, snapshot) {
        final summary = snapshot.data;
        final returned = _quantity(summary?['returned_quantity']);
        final remaining = summary == null
            ? originalQuantity
            : _quantity(summary['remaining_quantity']);
        final returns = (summary?['returns'] as List?) ?? [];

        final returnHistory = returns
            .map((item) {
              final row = Map<String, Object?>.from(item as Map);
              return '${row['quantity']} returned · '
                  '${row['reason'] ?? 'No reason'}';
            })
            .join('\n');

        return ListTile(
          title: Text(
            sale['product_name']?.toString() ?? 'Product',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$originalQuantity sold · $returned returned · '
                '$remaining remaining',
              ),
              if (returnHistory.isNotEmpty)
                Text(
                  returnHistory,
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
            ],
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _money(_amount(sale['total_amount'])),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              if (!isCancelled && remaining > 0)
                IconButton(
                  tooltip: 'Record return',
                  onPressed: () => _showReturnDialog(sale),
                  icon: const Icon(
                    Icons.assignment_return_outlined,
                    color: _green,
                  ),
                ),
            ],
          ),
          isThreeLine: returnHistory.isNotEmpty,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Order summary'),
        backgroundColor: _green,
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<Map<String, Object?>?>(
        future: _orderFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text('Could not load order details: ${snapshot.error}'),
              ),
            );
          }

          final details = snapshot.data;
          if (details == null) {
            return const Center(child: Text('Order could not be found.'));
          }

          final order = Map<String, Object?>.from(details['order'] as Map);
          final sales = (details['sales'] as List)
              .map((row) => Map<String, Object?>.from(row as Map))
              .toList();
          final payments = (details['payments'] as List)
              .map((row) => Map<String, Object?>.from(row as Map))
              .toList();

          final total = _amount(order['total_amount']);
          final paid = payments.fold<double>(
            0,
            (sum, payment) => sum + _amount(payment['amount']),
          );
          final balance = (total - paid).clamp(0.0, double.infinity);
          final status = order['status']?.toString() ?? 'completed';
          final isCancelled = status == 'cancelled';
          final isPaid = !isCancelled && balance < 0.01;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            isCancelled
                                ? Icons.cancel_outlined
                                : Icons.check_circle_outline,
                            color: isCancelled ? Colors.red : _green,
                            size: 32,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              isCancelled
                                  ? 'Order cancelled'
                                  : isPaid
                                  ? 'Payment complete'
                                  : 'Payment outstanding',
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'TRANSACTION ID',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 5),
                      SelectableText(
                        widget.orderSyncId,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 14),
                      _detailRow('Date and time', _date(order['created_at'])),
                      _detailRow('Order status', status.toUpperCase()),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Products purchased',
                style: Theme.of(context).textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Card(
                child: sales.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.all(16),
                        child: Text('No product lines found.'),
                      )
                    : Column(
                        children: [
                          for (var i = 0; i < sales.length; i++) ...[
                            _buildSaleLine(sales[i], isCancelled),
                            if (i < sales.length - 1) const Divider(height: 1),
                          ],
                        ],
                      ),
              ),
              if (!isCancelled && sales.isNotEmpty) ...[
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () => _showCancelDialog(sales),
                  icon: const Icon(Icons.cancel_outlined, color: Colors.red),
                  label: const Text(
                    'Cancel entire order',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              ],

              const SizedBox(height: 16),
              Text(
                'Payment breakdown',
                style: Theme.of(context).textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Card(
                child: payments.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.all(16),
                        child: Text('No payment entries found.'),
                      )
                    : Column(
                        children: [
                          for (var i = 0; i < payments.length; i++) ...[
                            ListTile(
                              leading: Icon(
                                payments[i]['payment_method'] == 'mpesa'
                                    ? Icons.phone_android
                                    : Icons.payments_outlined,
                              ),
                              title: Text(
                                payments[i]['payment_method']
                                        ?.toString()
                                        .toUpperCase() ??
                                    'PAYMENT',
                              ),
                              subtitle: payments[i]['reference'] == null
                                  ? null
                                  : Text(
                                      'Reference: ${payments[i]['reference']}',
                                    ),
                              trailing: Text(
                                _money(_amount(payments[i]['amount'])),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            if (i < payments.length - 1)
                              const Divider(height: 1),
                          ],
                        ],
                      ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    children: [
                      _detailRow('Order total', _money(total)),
                      const SizedBox(height: 10),
                      _detailRow('Total paid', _money(paid)),
                      const Divider(height: 24),
                      _detailRow(
                        'Balance due',
                        _money(balance),
                        valueColor: balance > 0 ? Colors.red : _green,
                        bold: true,
                      ),
                      const SizedBox(height: 8),
                      _detailRow(
                        'Payment status',
                        isCancelled
                            ? 'CANCELLED'
                            : isPaid
                            ? 'PAID IN FULL'
                            : 'PARTIALLY PAID',
                        valueColor: isPaid ? _green : Colors.red,
                        bold: true,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Payment entries are recorded manually. An M-Pesa reference '
                'does not mean the transaction has been independently '
                'verified.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 24),
            ],
          );
        },
      ),
    );
  }

  Widget _detailRow(
    String label,
    String value, {
    Color? valueColor,
    bool bold = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(label, style: const TextStyle(color: Colors.grey)),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: TextStyle(
              color: valueColor,
              fontWeight: bold ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
