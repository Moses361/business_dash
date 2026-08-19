import 'package:flutter/material.dart';

import '../models/sale.dart';
import '../repositories/sale_repository.dart';
import 'record_sale_screen.dart';
import 'sale_details_screen.dart';

const Color primary = Color(0xFF2E7D32);
const Color textSecondary = Color(0xFF68756D);

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
      final results = await Future.wait([
        _repository.getSales(),
        _repository.getTotalSales(),
        _repository.getTodaySales(),
        _repository.getTotalProfit(),
        _repository.getTodayProfit(),
      ]);

      if (!mounted) return;

      setState(() {
        _sales = results[0] as List<Sale>;
        _totalSales = results[1] as double;
        _todaySales = results[2] as double;
        _totalProfit = results[3] as double;
        _todayProfit = results[4] as double;
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

  Future<void> _openSaleDetails(Sale sale) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => SaleDetailsScreen(sale: sale)),
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

    return '$day/$month/$year $hour:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8F7),
      appBar: AppBar(
        title: const Text(
          'Sales',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
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
        icon: const Icon(Icons.point_of_sale_rounded),
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
                  Icon(
                    Icons.error_outline,
                    size: 52,
                    color: Colors.red.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _errorMessage!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _loadSales,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Try Again'),
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
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 110),
      children: [
        _buildTodayCard(),

        const SizedBox(height: 16),

        _buildStats(),

        const SizedBox(height: 28),

        _buildSectionHeader(),

        const SizedBox(height: 12),

        if (_sales.isEmpty)
          _buildEmptyState()
        else
          ..._sales.map(
            (sale) => _buildSaleCard(sale, onTap: () => _openSaleDetails(sale)),
          ),
      ],
    );
  }

  Widget _buildTodayCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2E7D32), Color(0xFF1B5E20)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withValues(alpha: 0.18),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.point_of_sale_rounded, color: Colors.white, size: 22),
              SizedBox(width: 10),
              Text(
                "Today's Sales",
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          Text(
            _formatAmount(_todaySales),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 30,
              fontWeight: FontWeight.w800,
            ),
          ),

          const SizedBox(height: 8),

          Row(
            children: [
              const Icon(
                Icons.trending_up_rounded,
                color: Colors.white70,
                size: 18,
              ),
              const SizedBox(width: 6),
              Text(
                "Today's profit ${_formatAmount(_todayProfit)}",
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStats() {
    return Row(
      children: [
        Expanded(
          child: _SummaryCard(
            title: 'Total Sales',
            value: _formatAmount(_totalSales),
            icon: Icons.bar_chart_rounded,
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
    );
  }

  Widget _buildSectionHeader() {
    return Row(
      children: [
        const Expanded(
          child: Text(
            'Recent Sales',
            style: TextStyle(fontSize: 21, fontWeight: FontWeight.w700),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFE1E9E4)),
          ),
          child: Text(
            '${_sales.length} '
            '${_sales.length == 1 ? 'sale' : 'sales'}',
            style: const TextStyle(
              color: textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSaleCard(Sale sale, {VoidCallback? onTap}) {
    final double profitPerUnit = sale.sellingPrice - sale.buyingPrice;

    final double totalProfit = profitPerUnit * sale.quantity;

    final bool positive = totalProfit >= 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE5F3EC),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: const Icon(
                      Icons.receipt_long_rounded,
                      color: primary,
                      size: 23,
                    ),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          sale.productName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),

                        const SizedBox(height: 5),

                        Text(
                          _formatDate(sale.createdAt),
                          style: const TextStyle(
                            color: textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 8),

                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text(
                        'Sale total',
                        style: TextStyle(color: textSecondary, fontSize: 11),
                      ),

                      const SizedBox(height: 3),

                      Text(
                        _formatAmount(sale.totalAmount),
                        style: const TextStyle(
                          color: primary,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 16),

              const Divider(),

              const SizedBox(height: 14),

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
                      label: 'Selling Price',
                      value: _formatAmount(sale.sellingPrice),
                    ),
                  ),

                  Expanded(
                    child: _SaleInfo(
                      label: 'Profit',
                      value: _formatAmount(totalProfit),
                      valueColor: positive
                          ? Colors.green.shade700
                          : Colors.red.shade700,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              Row(
                children: [
                  Expanded(
                    child: Text(
                      positive ? 'Profitable sale' : 'Loss on sale',
                      style: TextStyle(
                        color: positive
                            ? Colors.green.shade700
                            : Colors.red.shade700,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),

                  Icon(
                    Icons.chevron_right_rounded,
                    color: Colors.grey.shade500,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
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
              'No sales recorded yet',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
            ),

            const SizedBox(height: 8),

            Text(
              'Record your first sale and it will appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),

            const SizedBox(height: 20),

            ElevatedButton.icon(
              onPressed: _openRecordSale,
              icon: const Icon(Icons.point_of_sale),
              label: const Text('Record Sale'),
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
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: const Color(0xFFE5F3EC),
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(icon, color: primary, size: 21),
            ),

            const SizedBox(height: 12),

            Text(
              title,
              style: const TextStyle(
                color: textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),

            const SizedBox(height: 5),

            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
  final Color? valueColor;

  const _SaleInfo({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: textSecondary, fontSize: 11)),

        const SizedBox(height: 5),

        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: valueColor,
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}
