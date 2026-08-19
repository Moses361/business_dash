import 'package:flutter/material.dart';

import '../repositories/report_repository.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final ReportRepository _repository = ReportRepository();

  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now();

  ReportSummary? _summary;
  List<DailyReport> _dailyReports = [];
  List<CategoryReport> _categoryReports = [];

  bool _isLoading = true;
  String? _errorMessage;

  static const Color primary = Color(0xFF176B4D);
  static const Color dark = Color(0xFF17221D);
  static const Color secondary = Color(0xFF66736D);
  static const Color softGreen = Color(0xFFE1F1EA);
  static const Color surface = Color(0xFFF6F8F7);

  @override
  void initState() {
    super.initState();

    final now = DateTime.now();
    _startDate = DateTime(now.year, now.month, now.day);
    _endDate = _startDate;

    _loadReports();
  }

  Future<void> _loadReports() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final results = await Future.wait([
        _repository.getSummary(startDate: _startDate, endDate: _endDate),
        _repository.getDailyReports(startDate: _startDate, endDate: _endDate),
        _repository.getCategoryReports(
          startDate: _startDate,
          endDate: _endDate,
        ),
      ]);

      if (!mounted) return;

      setState(() {
        _summary = results[0] as ReportSummary;
        _dailyReports = results[1] as List<DailyReport>;
        _categoryReports = results[2] as List<CategoryReport>;
        _isLoading = false;
      });
    } catch (error) {
      debugPrint('Reports loading error: $error');

      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load reports.';
      });
    }
  }

  void _setToday() {
    final now = DateTime.now();

    setState(() {
      _startDate = DateTime(now.year, now.month, now.day);
      _endDate = _startDate;
    });

    _loadReports();
  }

  void _setThisWeek() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final daysFromMonday = today.weekday - DateTime.monday;

    setState(() {
      _startDate = today.subtract(Duration(days: daysFromMonday));
      _endDate = today;
    });

    _loadReports();
  }

  void _setThisMonth() {
    final now = DateTime.now();

    setState(() {
      _startDate = DateTime(now.year, now.month, 1);
      _endDate = DateTime(now.year, now.month, now.day);
    });

    _loadReports();
  }

  Future<void> _selectCustomRange() async {
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
    );

    if (range == null) return;

    setState(() {
      _startDate = range.start;
      _endDate = range.end;
    });

    await _loadReports();
  }

  String _formatAmount(double amount) {
    return 'KSh ${amount.toStringAsFixed(2)}';
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatDay(DateTime date) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return '${days[date.weekday - 1]} ${date.day}/${date.month}';
  }

  @override
  Widget build(BuildContext context) {
    final summary =
        _summary ??
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
      backgroundColor: surface,
      appBar: AppBar(
        title: const Text(
          'Reports',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            onPressed: _isLoading ? null : _loadReports,
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh reports',
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadReports,
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 36),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 18),
                    _buildDateRangeCard(),
                    const SizedBox(height: 24),
                    if (_errorMessage != null) ...[
                      _buildError(),
                      const SizedBox(height: 20),
                    ],
                    _buildSectionTitle(
                      'Business performance',
                      'A quick view of your numbers for this period.',
                    ),
                    const SizedBox(height: 12),
                    _buildSummaryGrid(summary),
                    const SizedBox(height: 28),
                    _buildDailySection(),
                    const SizedBox(height: 28),
                    _buildCategorySection(),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF176B4D), Color(0xFF0F5139)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Business analytics',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 23,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Track revenue, profit and performance.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.78),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.analytics_rounded,
              color: Colors.white,
              size: 26,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.w800,
            color: dark,
          ),
        ),
        const SizedBox(height: 3),
        Text(subtitle, style: const TextStyle(fontSize: 12, color: secondary)),
      ],
    );
  }

  Widget _buildDateRangeCard() {
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: softGreen,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.date_range_rounded, color: primary),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Report period',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: 3),
                      Text(
                        'Choose the period to analyse',
                        style: TextStyle(fontSize: 12, color: secondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F8F6),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE1E9E4)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.calendar_month_outlined,
                    size: 18,
                    color: secondary,
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      '${_formatDate(_startDate)} - ${_formatDate(_endDate)}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: dark,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 7,
              runSpacing: 7,
              children: [
                _PeriodButton(label: 'Today', onPressed: _setToday),
                _PeriodButton(label: 'This Week', onPressed: _setThisWeek),
                _PeriodButton(label: 'This Month', onPressed: _setThisMonth),
                FilledButton.icon(
                  onPressed: _selectCustomRange,
                  icon: const Icon(Icons.tune_rounded, size: 17),
                  label: const Text('Custom'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(0, 42),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryGrid(ReportSummary summary) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 700 ? 4 : 2;

        final cards = [
          _SummaryCard(
            title: 'Sales',
            value: _isLoading ? '...' : _formatAmount(summary.sales),
            icon: Icons.point_of_sale_outlined,
          ),
          _SummaryCard(
            title: 'Cost of Goods',
            value: _isLoading ? '...' : _formatAmount(summary.costOfGoods),
            icon: Icons.shopping_cart_outlined,
            iconColor: Colors.orange.shade700,
            iconBackground: Colors.orange.shade50,
          ),
          _SummaryCard(
            title: 'Gross Profit',
            value: _isLoading ? '...' : _formatAmount(summary.grossProfit),
            icon: Icons.trending_up_rounded,
            iconColor: Colors.green.shade700,
            iconBackground: Colors.green.shade50,
          ),
          _SummaryCard(
            title: 'Expenses',
            value: _isLoading ? '...' : _formatAmount(summary.expenses),
            icon: Icons.receipt_long_outlined,
            iconColor: Colors.red.shade700,
            iconBackground: Colors.red.shade50,
          ),
          _SummaryCard(
            title: 'Net Profit',
            value: _isLoading ? '...' : _formatAmount(summary.netProfit),
            icon: summary.netProfit >= 0
                ? Icons.account_balance_wallet_outlined
                : Icons.trending_down_rounded,
            iconColor: summary.netProfit >= 0
                ? Colors.green.shade700
                : Colors.red.shade700,
            iconBackground: summary.netProfit >= 0
                ? Colors.green.shade50
                : Colors.red.shade50,
          ),
          _SummaryCard(
            title: 'Transactions',
            value: _isLoading ? '...' : '${summary.transactions}',
            icon: Icons.receipt_outlined,
          ),
          _SummaryCard(
            title: 'Items Sold',
            value: _isLoading ? '...' : '${summary.itemsSold}',
            icon: Icons.inventory_2_outlined,
          ),
        ];

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            mainAxisExtent: 116,
          ),
          itemCount: cards.length,
          itemBuilder: (context, index) => cards[index],
        );
      },
    );
  }

  Widget _buildDailySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(
          'Daily performance',
          'See how the business performed each day.',
        ),
        const SizedBox(height: 12),
        if (_isLoading)
          _buildLoadingCard()
        else if (_dailyReports.isEmpty)
          _buildEmptyCard('No sales or expenses recorded for this period.')
        else
          Card(
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: _dailyReports.map((report) {
                final positive = report.netProfit >= 0;

                return Column(
                  children: [
                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 5,
                      ),
                      leading: Container(
                        padding: const EdgeInsets.all(9),
                        decoration: BoxDecoration(
                          color: softGreen,
                          borderRadius: BorderRadius.circular(11),
                        ),
                        child: const Icon(
                          Icons.calendar_today_outlined,
                          size: 18,
                          color: primary,
                        ),
                      ),
                      title: Text(
                        _formatDay(report.date),
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                        ),
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          'Sales ${_formatAmount(report.sales)}  •  '
                          'Expenses ${_formatAmount(report.expenses)}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: secondary,
                          ),
                        ),
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            positive ? 'Net profit' : 'Net loss',
                            style: const TextStyle(
                              fontSize: 10,
                              color: secondary,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            _formatAmount(report.netProfit),
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 12,
                              color: positive
                                  ? Colors.green.shade700
                                  : Colors.red.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (report != _dailyReports.last) const Divider(height: 1),
                  ],
                );
              }).toList(),
            ),
          ),
      ],
    );
  }

  Widget _buildCategorySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(
          'Sales by category',
          'See which categories are driving revenue.',
        ),
        const SizedBox(height: 12),
        if (_isLoading)
          _buildLoadingCard()
        else if (_categoryReports.isEmpty)
          _buildEmptyCard('No category sales available for this period.')
        else
          Card(
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: _categoryReports.map((report) {
                return Column(
                  children: [
                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 5,
                      ),
                      leading: Container(
                        padding: const EdgeInsets.all(9),
                        decoration: BoxDecoration(
                          color: softGreen,
                          borderRadius: BorderRadius.circular(11),
                        ),
                        child: const Icon(
                          Icons.category_outlined,
                          size: 18,
                          color: primary,
                        ),
                      ),
                      title: Text(
                        report.category,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                        ),
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          'Profit ${_formatAmount(report.profit)}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: secondary,
                          ),
                        ),
                      ),
                      trailing: Text(
                        _formatAmount(report.sales),
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    if (report != _categoryReports.last)
                      const Divider(height: 1),
                  ],
                );
              }).toList(),
            ),
          ),
      ],
    );
  }

  Widget _buildLoadingCard() {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(28),
        child: Center(
          child: SizedBox(
            width: 25,
            height: 25,
            child: CircularProgressIndicator(strokeWidth: 2.5),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyCard(String message) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(26),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F8F6),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.analytics_outlined,
                color: secondary,
                size: 26,
              ),
            ),
            const SizedBox(height: 11),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: secondary, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.red.shade100),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red.shade700),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _errorMessage!,
              style: TextStyle(color: Colors.red.shade800, fontSize: 13),
            ),
          ),
          IconButton(
            onPressed: _loadReports,
            icon: const Icon(Icons.refresh_rounded),
            color: Colors.red.shade700,
          ),
        ],
      ),
    );
  }
}

class _PeriodButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;

  const _PeriodButton({required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, 42),
        padding: const EdgeInsets.symmetric(horizontal: 13),
        textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
      ),
      child: Text(label),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color? iconColor;
  final Color? iconBackground;

  const _SummaryCard({
    required this.title,
    required this.value,
    required this.icon,
    this.iconColor,
    this.iconBackground,
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
                color: iconBackground ?? const Color(0xFFE1F1EA),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                size: 19,
                color: iconColor ?? const Color(0xFF176B4D),
              ),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF66736D),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
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
