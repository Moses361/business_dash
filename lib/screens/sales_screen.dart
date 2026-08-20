import 'package:flutter/material.dart';

import '../models/sale.dart';
import '../repositories/sale_repository.dart';
import 'record_sale_screen.dart';
import 'reports_screen.dart';
import 'sale_details_screen.dart';

const Color _salesPrimary = Color(0xFF176B4D);
const Color _salesSoftGreen = Color(0xFFE1F1EA);
const Color _salesBackground = Color(0xFFF6F8F7);
const Color _salesTextPrimary = Color(0xFF17221D);
const Color _salesTextSecondary = Color(0xFF68756D);
const Color _salesBorder = Color(0xFFE1E9E4);
const Color _salesDanger = Color(0xFFD64545);

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
      MaterialPageRoute(builder: (_) => const RecordSaleScreen()),
    );

    if (!mounted) return;

    await _loadSales();
  }

  Future<void> _openSaleDetails(Sale sale) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => SaleDetailsScreen(sale: sale)),
    );
  }

  Future<void> _openReports() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ReportsScreen()),
    );

    if (!mounted) return;

    await _loadSales();
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
      backgroundColor: _salesBackground,
      appBar: AppBar(
        title: const Text(
          'Sales',
          style: TextStyle(fontWeight: FontWeight.w800),
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
        label: const Text(
          'Record Sale',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
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
                    Icons.error_outline_rounded,
                    size: 52,
                    color: _salesDanger,
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
                  FilledButton.icon(
                    onPressed: _loadSales,
                    icon: const Icon(Icons.refresh_rounded),
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
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
      children: [
        _buildTodayCard(),

        const SizedBox(height: 14),

        _buildStats(),

        const SizedBox(height: 24),

        _buildSectionHeader(),

        const SizedBox(height: 12),

        if (_sales.isEmpty)
          _buildEmptyState()
        else
          ..._sales.map((sale) => _buildSaleCard(sale)),
      ],
    );
  }

  Widget _buildTodayCard() {
    return _TappableContainer(
      onTap: () {},
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF176B4D), Color(0xFF0F513A)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: _salesPrimary.withValues(alpha: 0.18),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    "TODAY'S SALES",
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.point_of_sale_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
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
                  size: 17,
                ),
                const SizedBox(width: 6),
                Text(
                  "Today's profit "
                  '${_formatAmount(_todayProfit)}',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ],
        ),
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
            onTap: () {},
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _SummaryCard(
            title: 'Total Profit',
            value: _formatAmount(_totalProfit),
            icon: Icons.account_balance_wallet_outlined,
            onTap: _openReports,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader() {
    return Row(
      children: [
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Recent sales',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: _salesTextPrimary,
                ),
              ),
              SizedBox(height: 3),
              Text(
                'Tap a sale to view its details.',
                style: TextStyle(fontSize: 11, color: _salesTextSecondary),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _salesBorder),
          ),
          child: Text(
            '${_sales.length}',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: _salesPrimary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSaleCard(Sale sale) {
    final double totalProfit = sale.grossProfit;

    final bool positive = totalProfit >= 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _openSaleDetails(sale),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: _salesSoftGreen,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Icon(
                  Icons.receipt_long_rounded,
                  color: _salesPrimary,
                  size: 22,
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
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: _salesTextPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${sale.quantity} units • '
                      '${_formatDate(sale.createdAt)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        color: _salesTextSecondary,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Row(
                      children: [
                        Text(
                          'Profit ',
                          style: const TextStyle(
                            fontSize: 10,
                            color: _salesTextSecondary,
                          ),
                        ),
                        Text(
                          _formatAmount(totalProfit),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: positive ? _salesPrimary : _salesDanger,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 10),

              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _formatAmount(sale.totalAmount),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: _salesPrimary,
                    ),
                  ),
                  const SizedBox(height: 5),
                  const Icon(
                    Icons.chevron_right_rounded,
                    size: 19,
                    color: Color(0xFF9AA59F),
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
        padding: const EdgeInsets.all(30),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(17),
              decoration: BoxDecoration(
                color: _salesSoftGreen,
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(
                Icons.receipt_long_outlined,
                size: 34,
                color: _salesPrimary,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'No sales recorded yet',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 7),
            Text(
              'Record your first sale and it will appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

class _TappableContainer extends StatelessWidget {
  final Widget child;
  final VoidCallback onTap;

  const _TappableContainer({required this.child, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: child,
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final VoidCallback onTap;

  const _SummaryCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _salesSoftGreen,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(icon, color: _salesPrimary, size: 21),
              ),
              const SizedBox(height: 11),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        color: _salesTextSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    size: 17,
                    color: Color(0xFF9AA59F),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: _salesTextPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
