import 'package:flutter/material.dart';

import '../repositories/product_repository.dart';
import '../repositories/report_repository.dart';
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
  final ReportRepository _reportRepository = ReportRepository();

  int _productCount = 0;
  int _lowStockCount = 0;

  ReportSummary? _todaySummary;

  bool _isLoading = true;
  String? _errorMessage;

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
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      final results = await Future.wait([
        _productRepository.getProductCount(),
        _productRepository.getLowStockCount(),
        _reportRepository.getSummary(
          startDate: today,
          endDate: today,
        ),
      ]);

      if (!mounted) return;

      setState(() {
        _productCount = results[0] as int;
        _lowStockCount = results[1] as int;
        _todaySummary = results[2] as ReportSummary;
        _isLoading = false;
      });
    } catch (error) {
      debugPrint('Dashboard loading error: $error');

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
      MaterialPageRoute(
        builder: (_) => const RecordSaleScreen(),
      ),
    );

    if (!mounted) return;

    await _loadDashboardData();
  }

  Future<void> _openProducts(BuildContext context) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const ProductsScreen(),
      ),
    );

    if (!mounted) return;

    await _loadDashboardData();
  }

  Future<void> _openExpenses(BuildContext context) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const ExpensesScreen(),
      ),
    );

    if (!mounted) return;

    await _loadDashboardData();
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;

    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  String _formatAmount(double amount) {
    return 'KSh ${amount.toStringAsFixed(2)}';
  }

  @override
  Widget build(BuildContext context) {
    final summary =
        _todaySummary ??
        const ReportSummary(
          sales: 0,
          costOfGoods: 0,
          grossProfit: 0,
          expenses: 0,
          netProfit: 0,
          transactions: 0,
          itemsSold: 0,
        );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            onPressed: _isLoading
                ? null
                : _loadDashboardData,
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh dashboard',
          ),
        ],
      ),

      body: RefreshIndicator(
        onRefresh: _loadDashboardData,

        child: SingleChildScrollView(
          physics:
              const AlwaysScrollableScrollPhysics(),

          padding: const EdgeInsets.fromLTRB(
            16,
            4,
            16,
            32,
          ),

          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              _buildWelcome(),

              const SizedBox(height: 20),

              if (_errorMessage != null) ...[
                _buildError(),
                const SizedBox(height: 16),
              ],

              _buildProfitHero(summary),

              const SizedBox(height: 14),

              _buildKpiGrid(summary),

              const SizedBox(height: 24),

              _buildBusinessOverview(summary),

              const SizedBox(height: 24),

              _buildQuickActions(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWelcome() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                '${_getGreeting()}, Veron 👋',
                style: const TextStyle(
                  fontSize: 23,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF17221D),
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                'Here is how your business is doing today.',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),

        Container(
          padding: const EdgeInsets.all(11),
          decoration: BoxDecoration(
            color: const Color(0xFFE1F1EA),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(
            Icons.storefront_rounded,
            color: Color(0xFF176B4D),
            size: 24,
          ),
        ),
      ],
    );
  }

  Widget _buildProfitHero(
    ReportSummary summary,
  ) {
    final positive = summary.netProfit >= 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),

      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: positive
              ? const [
                  Color(0xFF176B4D),
                  Color(0xFF0F513A),
                ]
              : const [
                  Color(0xFFB83B3B),
                  Color(0xFF8E2929),
                ],
        ),

        borderRadius: BorderRadius.circular(22),

        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),

      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  "TODAY'S NET PROFIT",
                  style: TextStyle(
                    color: Colors.white.withOpacity(.72),
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.1,
                  ),
                ),
              ),

              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(.12),
                  borderRadius:
                      BorderRadius.circular(10),
                ),
                child: Icon(
                  positive
                      ? Icons.trending_up_rounded
                      : Icons.trending_down_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          Text(
            _isLoading
                ? '...'
                : _formatAmount(summary.netProfit),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),

          const SizedBox(height: 6),

          Text(
            positive
                ? 'Your business is profitable today'
                : 'Your business needs attention today',
            style: TextStyle(
              color: Colors.white.withOpacity(.78),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKpiGrid(
    ReportSummary summary,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return GridView(
          shrinkWrap: true,
          physics:
              const NeverScrollableScrollPhysics(),

          gridDelegate:
              SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount:
                constraints.maxWidth >= 600
                    ? 3
                    : 2,

            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            mainAxisExtent: 100,
          ),

          children: [
            _KpiCard(
              title: 'Sales',
              value: _isLoading
                  ? '...'
                  : _formatAmount(summary.sales),
              icon: Icons.point_of_sale_rounded,
            ),

            _KpiCard(
              title: 'Gross Profit',
              value: _isLoading
                  ? '...'
                  : _formatAmount(summary.grossProfit),
              icon: Icons.trending_up_rounded,
              iconColor:
                  const Color(0xFF1B8A5A),
              iconBackground:
                  const Color(0xFFE4F4EC),
            ),

            _KpiCard(
              title: 'Expenses',
              value: _isLoading
                  ? '...'
                  : _formatAmount(summary.expenses),
              icon: Icons.receipt_long_rounded,
              iconColor:
                  const Color(0xFFD64545),
              iconBackground:
                  const Color(0xFFFCEAEA),
            ),
          ],
        );
      },
    );
  }

  Widget _buildBusinessOverview(
    ReportSummary summary,
  ) {
    final lowStock = _lowStockCount > 0;

    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        const Text(
          'Business overview',
          style: TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.w800,
            color: Color(0xFF17221D),
          ),
        ),

        const SizedBox(height: 4),

        Text(
          'A quick snapshot of your operations.',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),

        const SizedBox(height: 12),

        Row(
          children: [
            Expanded(
              child: _OverviewTile(
                title: 'Products',
                value: _isLoading
                    ? '...'
                    : '$_productCount',
                subtitle: 'in inventory',
                icon: Icons.inventory_2_rounded,
              ),
            ),

            const SizedBox(width: 10),

            Expanded(
              child: _OverviewTile(
                title: 'Low stock',
                value: _isLoading
                    ? '...'
                    : '$_lowStockCount',
                subtitle: lowStock
                    ? 'needs attention'
                    : 'all good',
                icon: Icons.warning_amber_rounded,
                iconColor: lowStock
                    ? const Color(0xFFD58A18)
                    : const Color(0xFF1B8A5A),
                iconBackground: lowStock
                    ? const Color(0xFFFFF3DD)
                    : const Color(0xFFE4F4EC),
              ),
            ),
          ],
        ),

        const SizedBox(height: 10),

        Row(
          children: [
            Expanded(
              child: _OverviewTile(
                title: 'Transactions',
                value: _isLoading
                    ? '...'
                    : '${summary.transactions}',
                subtitle: 'today',
                icon: Icons.receipt_long_rounded,
              ),
            ),

            const SizedBox(width: 10),

            Expanded(
              child: _OverviewTile(
                title: 'Items sold',
                value: _isLoading
                    ? '...'
                    : '${summary.itemsSold}',
                subtitle: 'today',
                icon: Icons.shopping_bag_rounded,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick actions',
          style: TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.w800,
            color: Color(0xFF17221D),
          ),
        ),

        const SizedBox(height: 12),

        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton.icon(
            onPressed: () =>
                _openRecordSale(context),
            icon: const Icon(
              Icons.point_of_sale_rounded,
            ),
            label: const Text('Record Sale'),
          ),
        ),

        const SizedBox(height: 10),

        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () =>
                    _openProducts(context),
                icon: const Icon(
                  Icons.inventory_2_outlined,
                ),
                label: const Text('Products'),
                style: OutlinedButton.styleFrom(
                  minimumSize:
                      const Size.fromHeight(50),
                ),
              ),
            ),

            const SizedBox(width: 10),

            Expanded(
              child: OutlinedButton.icon(
                onPressed: () =>
                    _openExpenses(context),
                icon: const Icon(
                  Icons.receipt_long_outlined,
                ),
                label: const Text('Expenses'),
                style: OutlinedButton.styleFrom(
                  minimumSize:
                      const Size.fromHeight(50),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildError() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),

      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius:
            BorderRadius.circular(14),
        border: Border.all(
          color: Colors.red.shade100,
        ),
      ),

      child: Row(
        children: [
          Icon(
            Icons.error_outline,
            color: Colors.red.shade700,
          ),
          const SizedBox(width: 10),

          Expanded(
            child: Text(
              _errorMessage!,
              style: TextStyle(
                color: Colors.red.shade800,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _KpiCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color iconColor;
  final Color iconBackground;

  const _KpiCard({
    required this.title,
    required this.value,
    required this.icon,
    this.iconColor = const Color(0xFF176B4D),
    this.iconBackground =
        const Color(0xFFE1F1EA),
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),

        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),

              decoration: BoxDecoration(
                color: iconBackground,
                borderRadius:
                    BorderRadius.circular(10),
              ),

              child: Icon(
                icon,
                size: 19,
                color: iconColor,
              ),
            ),

            const SizedBox(width: 9),

            Expanded(
              child: Column(
                mainAxisAlignment:
                    MainAxisAlignment.center,
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF66736D),
                    ),
                  ),

                  const SizedBox(height: 4),

                  Text(
                    value,
                    maxLines: 1,
                    overflow:
                        TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF17221D),
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

class _OverviewTile extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final Color iconBackground;

  const _OverviewTile({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    this.iconColor =
        const Color(0xFF176B4D),
    this.iconBackground =
        const Color(0xFFE1F1EA),
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(13),

        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),

              decoration: BoxDecoration(
                color: iconBackground,
                borderRadius:
                    BorderRadius.circular(10),
              ),

              child: Icon(
                icon,
                color: iconColor,
                size: 19,
              ),
            ),

            const SizedBox(width: 9),

            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow:
                        TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF66736D),
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  const SizedBox(height: 2),

                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF17221D),
                    ),
                  ),

                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow:
                        TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 10,
                      color: Color(0xFF9AA59F),
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
