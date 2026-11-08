import 'package:flutter/material.dart';

import '../models/sale.dart';
import '../repositories/sale_repository.dart';
import 'checkout_screen.dart';
import 'reports_screen.dart';
import 'sale_details_screen.dart';
import 'order_details_screen.dart';

const Color _salesPrimary = Color(0xFF176B4D);
const Color _salesSoftGreen = Color(0xFFE1F1EA);
const Color _salesBackground = Color(0xFFF6F8F7);
const Color _salesTextPrimary = Color(0xFF17221D);
const Color _salesTextSecondary = Color(0xFF68756D);
const Color _salesBorder = Color(0xFFE1E9E4);
const Color _salesDanger = Color(0xFFD64545);

enum _SalesPeriod { all, today, thisMonth }

class _SaleGroup {
  final List<Sale> sales = [];

  double get totalAmount =>
      sales.fold(0.0, (sum, sale) => sum + sale.totalAmount);
  double get totalProfit =>
      sales.fold(0.0, (sum, sale) => sum + sale.grossProfit);
  int get totalQuantity => sales.fold(0, (sum, sale) => sum + sale.quantity);
  DateTime get createdAt => sales.first.createdAt;
}

class SalesScreen extends StatefulWidget {
  const SalesScreen({super.key});

  @override
  State<SalesScreen> createState() => _SalesScreenState();
}

class _SalesScreenState extends State<SalesScreen> {
  final SaleRepository _repository = SaleRepository();
  final TextEditingController _searchController = TextEditingController();

  List<Sale> _sales = [];

  double _totalSales = 0.0;
  double _todaySales = 0.0;
  double _totalProfit = 0.0;
  double _todayProfit = 0.0;

  bool _isLoading = true;
  String? _errorMessage;
  String _searchQuery = '';
  _SalesPeriod _selectedPeriod = _SalesPeriod.all;

  List<_SaleGroup> get _visibleSaleGroups {
    final now = DateTime.now();
    final query = _searchQuery.trim().toLowerCase();
    final grouped = <String, _SaleGroup>{};

    for (final sale in _sales) {
      final syncId = sale.orderSyncId;
      final key = syncId != null && syncId.trim().isNotEmpty
          ? "order:" + syncId
          : "sale:" + sale.id.toString();
      grouped.putIfAbsent(key, () => _SaleGroup()).sales.add(sale);
    }

    return grouped.values.where((group) {
      final date = group.createdAt.toLocal();
      final matchesSearch =
          query.isEmpty ||
          group.sales.any(
            (sale) => sale.productName.toLowerCase().contains(query),
          );
      final matchesPeriod = switch (_selectedPeriod) {
        _SalesPeriod.all => true,
        _SalesPeriod.today => DateUtils.isSameDay(date, now),
        _SalesPeriod.thisMonth =>
          date.year == now.year && date.month == now.month,
      };
      return matchesSearch && matchesPeriod;
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    _loadSales();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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

  Future<void> _openNewSale() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CheckoutScreen()),
    );

    if (!mounted) return;
    await _loadSales();
  }

  Future<void> _openSaleGroup(_SaleGroup group) async {
    final orderSyncId = group.sales.first.orderSyncId;

    if (orderSyncId != null && orderSyncId.trim().isNotEmpty) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => OrderDetailsScreen(
            orderSyncId: orderSyncId,
            saleRepository: _repository,
          ),
        ),
      );
      return;
    }

    await _openSaleDetails(group.sales.first);
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
          const SizedBox(width: 4),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openNewSale,
        icon: const Icon(Icons.point_of_sale_rounded),
        label: const Text(
          'New sale',
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
                  const Icon(
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
        const SizedBox(height: 26),
        _buildSectionHeader(),
        const SizedBox(height: 14),
        _buildSearchField(),
        const SizedBox(height: 12),
        _buildPeriodFilters(),
        const SizedBox(height: 14),
        if (_visibleSaleGroups.isEmpty)
          _buildEmptyState()
        else
          ..._visibleSaleGroups.map(_buildSaleCard),
      ],
    );
  }

  Widget _buildTodayCard() {
    return Container(
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
                "Today's profit ${_formatAmount(_todayProfit)}",
                style: const TextStyle(color: Colors.white70, fontSize: 12),
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
                'Sales history',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: _salesTextPrimary,
                ),
              ),
              SizedBox(height: 3),
              Text(
                'Search transactions and open a sale for details.',
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
            '${_visibleSaleGroups.length} transactions',
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

  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      onChanged: (value) => setState(() => _searchQuery = value),
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: 'Search by product name',
        prefixIcon: const Icon(Icons.search_rounded),
        suffixIcon: _searchQuery.isEmpty
            ? null
            : IconButton(
                tooltip: 'Clear search',
                onPressed: () {
                  _searchController.clear();
                  setState(() => _searchQuery = '');
                },
                icon: const Icon(Icons.close_rounded),
              ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(vertical: 15),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: _salesBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: _salesBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: _salesPrimary, width: 1.5),
        ),
      ),
    );
  }

  Widget _buildPeriodFilters() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _periodChip('All sales', _SalesPeriod.all),
          const SizedBox(width: 8),
          _periodChip('Today', _SalesPeriod.today),
          const SizedBox(width: 8),
          _periodChip('This month', _SalesPeriod.thisMonth),
        ],
      ),
    );
  }

  Widget _periodChip(String label, _SalesPeriod period) {
    final selected = _selectedPeriod == period;

    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => setState(() => _selectedPeriod = period),
      showCheckmark: false,
      labelStyle: TextStyle(
        color: selected ? Colors.white : _salesTextSecondary,
        fontSize: 12,
        fontWeight: FontWeight.w700,
      ),
      selectedColor: _salesPrimary,
      backgroundColor: Colors.white,
      side: BorderSide(color: selected ? _salesPrimary : _salesBorder),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
    );
  }

  Widget _buildSaleCard(_SaleGroup group) {
    final positive = group.totalProfit >= 0;
    final transactionId = group.sales.first.orderSyncId;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _openSaleGroup(group),
        child: Padding(
          padding: const EdgeInsets.all(16),
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
                      'Sale transaction',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: _salesTextPrimary,
                      ),
                    ),
                    const SizedBox(height: 5),
                    if (transactionId != null &&
                        transactionId.trim().isNotEmpty) ...[
                      const Text(
                        'TRANSACTION ID',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: _salesTextSecondary,
                          letterSpacing: 0.5,
                        ),
                      ),
                      SelectableText(
                        transactionId,
                        style: const TextStyle(
                          fontSize: 10,
                          color: _salesTextSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                    ],
                    Text(
                      '${group.sales.length} product(s) • ${group.totalQuantity} units',
                      style: const TextStyle(
                        fontSize: 11,
                        color: _salesTextSecondary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _formatDate(group.createdAt),
                      style: const TextStyle(
                        fontSize: 11,
                        color: _salesTextSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Profit ${_formatAmount(group.totalProfit)}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: positive ? _salesPrimary : _salesDanger,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _formatAmount(group.totalAmount),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: _salesPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 15,
                    color: _salesTextSecondary,
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
    final hasFilters =
        _searchQuery.trim().isNotEmpty || _selectedPeriod != _SalesPeriod.all;

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
              child: Icon(
                hasFilters
                    ? Icons.search_off_rounded
                    : Icons.receipt_long_outlined,
                size: 34,
                color: _salesPrimary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              hasFilters ? 'No matching sales' : 'No sales recorded yet',
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 7),
            Text(
              hasFilters
                  ? 'Try another product name or choose a different date filter.'
                  : 'Record your first sale and it will appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
            if (hasFilters) ...[
              const SizedBox(height: 14),
              TextButton.icon(
                onPressed: () {
                  _searchController.clear();
                  setState(() {
                    _searchQuery = '';
                    _selectedPeriod = _SalesPeriod.all;
                  });
                },
                icon: const Icon(Icons.filter_alt_off_rounded),
                label: const Text('Clear filters'),
              ),
            ],
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
  final VoidCallback? onTap;

  const _SummaryCard({
    required this.title,
    required this.value,
    required this.icon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final content = Padding(
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
              if (onTap != null)
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
    );

    return Card(
      clipBehavior: Clip.antiAlias,
      child: onTap == null ? content : InkWell(onTap: onTap, child: content),
    );
  }
}
