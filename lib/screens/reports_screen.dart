import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

import '../models/expense.dart';
import '../repositories/expense_repository.dart';
import '../repositories/report_repository.dart';
import '../services/report_pdf_service.dart';
import 'expenses_screen.dart';
import 'sales_screen.dart';

const Color _reportPrimary = Color(0xFF176B4D);
const Color _reportSoftGreen = Color(0xFFE1F1EA);
const Color _reportBackground = Color(0xFFF6F8F7);
const Color _reportTextPrimary = Color(0xFF17221D);
const Color _reportTextSecondary = Color(0xFF66736D);
const Color _reportDanger = Color(0xFFD64545);
const Color _reportWarning = Color(0xFFD58A18);
const Color _reportBorder = Color(0xFFE1E9E4);

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final ReportRepository _repository = ReportRepository();

  final ExpenseRepository _expenseRepository = ExpenseRepository();

  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now();

  ReportSummary? _summary;
  List<DailyReport> _dailyReports = [];
  List<CategoryReport> _categoryReports = [];
  List<Expense> _periodExpenses = [];

  bool _isLoading = true;
  bool _isPrinting = false;
  String? _errorMessage;

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
      final endExclusive = _endDate.add(const Duration(days: 1));

      final results = await Future.wait([
        _repository.getSummary(startDate: _startDate, endDate: endExclusive),
        _repository.getDailyReports(
          startDate: _startDate,
          endDate: endExclusive,
        ),
        _repository.getCategoryReports(
          startDate: _startDate,
          endDate: endExclusive,
        ),
        _expenseRepository.getExpenses(),
      ]);

      final allExpenses = results[3] as List<Expense>;

      final periodExpenses = allExpenses.where((expense) {
        return !expense.createdAt.isBefore(_startDate) &&
            expense.createdAt.isBefore(endExclusive);
      }).toList();

      if (!mounted) return;

      setState(() {
        _summary = results[0] as ReportSummary;
        _dailyReports = results[1] as List<DailyReport>;
        _categoryReports = results[2] as List<CategoryReport>;
        _periodExpenses = periodExpenses;
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

  Future<void> _printReport() async {
    if (_summary == null || _isPrinting) {
      return;
    }

    setState(() {
      _isPrinting = true;
    });

    try {
      final List<int> pdfBytes = await ReportPdfService.buildReport(
        summary: _summary!,
        dailyReports: _dailyReports,
        categoryReports: _categoryReports,
        expenses: _periodExpenses,
        startDate: _startDate,
        endDate: _endDate,
      );

      final Uint8List documentBytes = Uint8List.fromList(pdfBytes);

      await Printing.layoutPdf(
        onLayout: (_) async => documentBytes,
        name: 'Veroon Business Report ${_formatDate(_startDate)}',
      );
    } catch (error) {
      debugPrint('PDF report error: $error');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not create the PDF report.'),
          backgroundColor: _reportDanger,
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 3),
          persist: false,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isPrinting = false;
        });
      }
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
    final DateTimeRange? range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
    );

    if (range == null) {
      return;
    }

    setState(() {
      _startDate = DateTime(
        range.start.year,
        range.start.month,
        range.start.day,
      );

      _endDate = DateTime(range.end.year, range.end.month, range.end.day);
    });

    await _loadReports();
  }

  Future<void> _openSales() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SalesScreen()),
    );

    if (!mounted) return;

    await _loadReports();
  }

  Future<void> _openExpenses() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ExpensesScreen()),
    );

    if (!mounted) return;

    await _loadReports();
  }

  void _showNetProfitExplanation(ReportSummary summary) {
    final positive = summary.netProfit >= 0;

    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      backgroundColor: Colors.white,
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  positive
                      ? 'How your profit is calculated'
                      : 'Why you made a loss',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: _reportTextPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  positive
                      ? 'Your net profit is what remains after subtracting the cost of goods and expenses from sales.'
                      : 'Your sales were not enough to cover the cost of goods and business expenses during this period.',
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.5,
                    color: _reportTextSecondary,
                  ),
                ),
                const SizedBox(height: 18),
                _ExplanationRow(
                  label: 'Sales',
                  value: _formatAmount(summary.sales),
                ),
                _ExplanationRow(
                  label: 'Cost of goods',
                  value: _formatAmount(summary.costOfGoods),
                ),
                _ExplanationRow(
                  label: 'Expenses',
                  value: _formatAmount(summary.expenses),
                ),
                const Divider(height: 22),
                _ExplanationRow(
                  label: positive ? 'Net profit' : 'Net loss',
                  value: _formatAmount(summary.netProfit.abs()),
                  valueColor: positive ? _reportPrimary : _reportDanger,
                  bold: true,
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () {
                      Navigator.pop(sheetContext);
                    },
                    child: const Text('Got it'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatAmount(double amount) {
    return 'KSh ${amount.toStringAsFixed(2)}';
  }

  String _formatDate(DateTime date) {
    return '${date.day}/'
        '${date.month}/'
        '${date.year}';
  }

  String _formatDay(DateTime date) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return '${days[date.weekday - 1]} '
        '${date.day}/${date.month}';
  }

  double _grossMargin(ReportSummary summary) {
    if (summary.sales <= 0) {
      return 0;
    }

    return (summary.grossProfit / summary.sales) * 100;
  }

  String _businessInsight(ReportSummary summary) {
    if (summary.sales <= 0 && summary.expenses <= 0) {
      return 'No business activity has been recorded for this period yet.';
    }

    if (summary.netProfit < 0) {
      if (summary.expenses > summary.grossProfit.abs()) {
        return 'Your expenses are putting heavy pressure on the business result. Review the largest expenses for this period.';
      }

      if (summary.costOfGoods > summary.sales) {
        return 'Your stock cost is higher than your sales for this period. Review pricing, margins and fast-moving products.';
      }

      return 'The business finished this period at a loss. Review sales, stock costs and expenses to find the main pressure point.';
    }

    if (_grossMargin(summary) >= 30) {
      return 'Good sign: your product margin is healthy. Keep watching expenses so they do not eat into your profit.';
    }

    if (_grossMargin(summary) > 0) {
      return 'Your products are generating profit, but the margin is fairly tight. Review pricing and buying costs where possible.';
    }

    if (summary.expenses > 0) {
      return 'Sales are being recorded, but expenses are reducing what the business keeps.';
    }

    return 'Your business is profitable for this period. Keep monitoring your sales and stock costs.';
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

    final isLoss = summary.netProfit < 0;

    final margin = _grossMargin(summary);

    return Scaffold(
      backgroundColor: _reportBackground,
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
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadReports,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            _buildHeader(),
            const SizedBox(height: 16),
            _buildDateRangeCard(),
            const SizedBox(height: 14),
            _buildPrintButton(),
            const SizedBox(height: 18),
            if (_errorMessage != null) ...[
              _buildError(),
              const SizedBox(height: 18),
            ],
            _buildBusinessResultCard(summary, isLoss, margin),
            const SizedBox(height: 16),
            _buildInsightCard(summary),
            const SizedBox(height: 24),
            _buildSectionTitle(
              'Your numbers',
              'Tap a card to explore the related records.',
            ),
            const SizedBox(height: 12),
            _buildSummaryGrid(summary),
            const SizedBox(height: 26),
            _buildDailySection(),
            const SizedBox(height: 26),
            _buildCategorySection(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Business reports',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: _reportTextPrimary,
                  letterSpacing: -0.4,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Understand what your business made, spent and kept.',
                style: TextStyle(fontSize: 13, color: _reportTextSecondary),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.all(11),
          decoration: BoxDecoration(
            color: _reportSoftGreen,
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(
            Icons.analytics_rounded,
            color: _reportPrimary,
            size: 23,
          ),
        ),
      ],
    );
  }

  Widget _buildDateRangeCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: _reportSoftGreen,
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: const Icon(
                    Icons.date_range_rounded,
                    color: _reportPrimary,
                    size: 20,
                  ),
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
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Choose the period you want to analyse.',
                        style: TextStyle(
                          fontSize: 11,
                          color: _reportTextSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F8F6),
                borderRadius: BorderRadius.circular(11),
                border: Border.all(color: _reportBorder),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.calendar_month_outlined,
                    size: 18,
                    color: _reportTextSecondary,
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      '${_formatDate(_startDate)} - '
                      '${_formatDate(_endDate)}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: _reportTextPrimary,
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

  Widget _buildPrintButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: OutlinedButton.icon(
        onPressed: _isLoading || _summary == null || _isPrinting
            ? null
            : _printReport,
        icon: _isPrinting
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.print_outlined),
        label: Text(
          _isPrinting ? 'Preparing PDF...' : 'Print / Share PDF Report',
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: _reportPrimary,
          side: const BorderSide(color: _reportPrimary),
          textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  Widget _buildBusinessResultCard(
    ReportSummary summary,
    bool isLoss,
    double margin,
  ) {
    final result = summary.netProfit.abs();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isLoss
              ? const [Color(0xFF8F3030), Color(0xFF682121)]
              : const [Color(0xFF176B4D), Color(0xFF0F513A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.13),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(
                  isLoss
                      ? Icons.trending_down_rounded
                      : Icons.trending_up_rounded,
                  color: Colors.white,
                  size: 21,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                isLoss ? 'NET LOSS' : 'NET PROFIT',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            isLoss ? 'You made a net loss of' : 'You made a net profit of',
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 4),
          Text(
            _isLoading ? '...' : _formatAmount(result),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            isLoss
                ? 'Sales did not fully cover your stock costs and expenses during this period.'
                : 'After stock costs and expenses, this is what the business kept.',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _ResultMiniMetric(
                  label: 'Sales',
                  value: _formatAmount(summary.sales),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ResultMiniMetric(
                  label: 'Stock cost',
                  value: _formatAmount(summary.costOfGoods),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ResultMiniMetric(
                  label: 'Expenses',
                  value: _formatAmount(summary.expenses),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.11),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.percent_rounded,
                  color: Colors.white70,
                  size: 17,
                ),
                const SizedBox(width: 7),
                const Expanded(
                  child: Text(
                    'Gross margin',
                    style: TextStyle(color: Colors.white70, fontSize: 11),
                  ),
                ),
                Text(
                  '${margin.toStringAsFixed(1)}%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: TextButton.icon(
              onPressed: () => _showNetProfitExplanation(summary),
              style: TextButton.styleFrom(
                foregroundColor: isLoss
                    ? const Color(0xFFFFD8D8)
                    : const Color(0xFFC9F2DF),
                backgroundColor: Colors.white.withValues(alpha: 0.10),
              ),
              icon: const Icon(Icons.help_outline_rounded, size: 17),
              label: const Text('Understand this result'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInsightCard(ReportSummary summary) {
    final loss = summary.netProfit < 0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: loss ? const Color(0xFFFFF3DD) : _reportSoftGreen,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                loss
                    ? Icons.lightbulb_outline_rounded
                    : Icons.verified_outlined,
                color: loss ? _reportWarning : _reportPrimary,
                size: 21,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Business insight',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: _reportTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    _businessInsight(summary),
                    style: const TextStyle(
                      fontSize: 12,
                      height: 1.45,
                      color: _reportTextSecondary,
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

  Widget _buildSectionTitle(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.w800,
            color: _reportTextPrimary,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          subtitle,
          style: const TextStyle(fontSize: 12, color: _reportTextSecondary),
        ),
      ],
    );
  }

  Widget _buildSummaryGrid(ReportSummary summary) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 700 ? 4 : 2;

        final cards = [
          _ReportCard(
            title: 'Sales',
            value: _formatAmount(summary.sales),
            icon: Icons.point_of_sale_outlined,
            onTap: _openSales,
          ),
          _ReportCard(
            title: 'Cost of Goods',
            value: _formatAmount(summary.costOfGoods),
            icon: Icons.shopping_cart_outlined,
            iconColor: _reportWarning,
            iconBackground: const Color(0xFFFFF3DD),
            onTap: _openSales,
          ),
          _ReportCard(
            title: 'Gross Profit',
            value: _formatAmount(summary.grossProfit),
            icon: Icons.trending_up_rounded,
            onTap: _openSales,
          ),
          _ReportCard(
            title: 'Expenses',
            value: _formatAmount(summary.expenses),
            icon: Icons.receipt_long_outlined,
            iconColor: _reportDanger,
            iconBackground: const Color(0xFFFCEAEA),
            onTap: _openExpenses,
          ),
          _ReportCard(
            title: 'Net Profit',
            value: _formatAmount(summary.netProfit),
            icon: summary.netProfit >= 0
                ? Icons.account_balance_wallet_outlined
                : Icons.trending_down_rounded,
            iconColor: summary.netProfit >= 0 ? _reportPrimary : _reportDanger,
            iconBackground: summary.netProfit >= 0
                ? _reportSoftGreen
                : const Color(0xFFFCEAEA),
            onTap: _openSales,
          ),
          _ReportCard(
            title: 'Transactions',
            value: '${summary.transactions}',
            icon: Icons.receipt_outlined,
            onTap: _openSales,
          ),
          _ReportCard(
            title: 'Items Sold',
            value: '${summary.itemsSold}',
            icon: Icons.inventory_2_outlined,
            onTap: _openSales,
          ),
        ];

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            mainAxisExtent: 118,
          ),
          itemCount: cards.length,
          itemBuilder: (_, index) => cards[index],
        );
      },
    );
  }

  Widget _buildDailySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Daily performance', 'See what happened each day.'),
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

                return InkWell(
                  onTap: _openSales,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(9),
                          decoration: BoxDecoration(
                            color: _reportSoftGreen,
                            borderRadius: BorderRadius.circular(11),
                          ),
                          child: const Icon(
                            Icons.calendar_today_outlined,
                            size: 18,
                            color: _reportPrimary,
                          ),
                        ),
                        const SizedBox(width: 11),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _formatDay(report.date),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Sales ${_formatAmount(report.sales)}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: _reportTextSecondary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Expenses ${_formatAmount(report.expenses)}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: _reportTextSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              positive ? 'Profit' : 'Loss',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: positive
                                    ? _reportPrimary
                                    : _reportDanger,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              _formatAmount(report.netProfit.abs()),
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 13,
                                color: positive
                                    ? _reportPrimary
                                    : _reportDanger,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 5),
                        const Icon(
                          Icons.chevron_right_rounded,
                          color: Color(0xFF9AA59F),
                        ),
                      ],
                    ),
                  ),
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
          'See which categories are driving your sales.',
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
                return InkWell(
                  onTap: _openSales,
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 3,
                    ),
                    leading: Container(
                      padding: const EdgeInsets.all(9),
                      decoration: BoxDecoration(
                        color: _reportSoftGreen,
                        borderRadius: BorderRadius.circular(11),
                      ),
                      child: const Icon(
                        Icons.category_outlined,
                        size: 18,
                        color: _reportPrimary,
                      ),
                    ),
                    title: Text(
                      report.category,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                    subtitle: Text(
                      'Profit ${_formatAmount(report.profit)}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: _reportTextSecondary,
                      ),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _formatAmount(report.sales),
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.chevron_right_rounded,
                          size: 18,
                          color: Color(0xFF9AA59F),
                        ),
                      ],
                    ),
                  ),
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
        padding: EdgeInsets.all(26),
        child: Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2.5),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyCard(String message) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F8F6),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.analytics_outlined,
                color: _reportTextSecondary,
                size: 25,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: _reportTextSecondary, fontSize: 13),
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
          Icon(Icons.error_outline, color: _reportDanger),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _errorMessage!,
              style: TextStyle(color: Colors.red.shade800, fontSize: 13),
            ),
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

class _ReportCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color iconColor;
  final Color iconBackground;
  final VoidCallback onTap;

  const _ReportCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.onTap,
    this.iconColor = _reportPrimary,
    this.iconBackground = _reportSoftGreen,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: iconBackground,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, size: 18, color: iconColor),
                  ),
                  const Spacer(),
                  const Icon(
                    Icons.chevron_right_rounded,
                    size: 17,
                    color: Color(0xFF9AA59F),
                  ),
                ],
              ),
              const Spacer(),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 11,
                  color: _reportTextSecondary,
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
                  color: _reportTextPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ResultMiniMetric extends StatelessWidget {
  final String label;
  final String value;

  const _ResultMiniMetric({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 9),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _ExplanationRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final bool bold;

  const _ExplanationRow({
    required this.label,
    required this.value,
    this.valueColor,
    this.bold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: bold ? FontWeight.w800 : FontWeight.w500,
                color: _reportTextSecondary,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: bold ? FontWeight.w800 : FontWeight.w700,
              color: valueColor ?? _reportTextPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
