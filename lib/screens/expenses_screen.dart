import 'package:flutter/material.dart';

import '../models/expense.dart';
import '../repositories/expense_repository.dart';
import 'add_expense_screen.dart';
import 'expense_details_screen.dart';

const Color _expensePrimary = Color(0xFF176B4D);
const Color _expenseBackground = Color(0xFFF6F8F7);
const Color _expenseTextPrimary = Color(0xFF17221D);
const Color _expenseTextSecondary = Color(0xFF66736D);
const Color _expenseDanger = Color(0xFFD64545);

class ExpensesScreen extends StatefulWidget {
  final ExpenseRepository? expenseRepository;

  const ExpensesScreen({super.key, this.expenseRepository});

  @override
  State<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ExpensesScreen> {
  late final ExpenseRepository _expenseRepository;

  final GlobalKey _historyKey = GlobalKey();

  List<Expense> _expenses = [];
  double _totalExpenses = 0.0;

  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();

    _expenseRepository = widget.expenseRepository ?? ExpenseRepository();

    _loadExpenses();
  }

  Future<void> _loadExpenses() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final results = await Future.wait([
        _expenseRepository.getExpenses(),
        _expenseRepository.getTotalExpenses(),
      ]);

      if (!mounted) return;

      setState(() {
        _expenses = results[0] as List<Expense>;
        _totalExpenses = results[1] as double;
        _isLoading = false;
      });
    } catch (error) {
      debugPrint('Expenses loading error: $error');

      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load expenses.';
      });
    }
  }

  Future<void> _openAddExpense() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddExpenseScreen()),
    );

    if (!mounted) return;

    await _loadExpenses();
  }

  Future<void> _openExpenseDetails(Expense expense) async {
    final bool? result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => ExpenseDetailsScreen(expense: expense)),
    );

    if (!mounted || result != true) {
      return;
    }

    await _deleteExpense(expense);
  }

  void _scrollToHistory() {
    final BuildContext? targetContext = _historyKey.currentContext;

    if (targetContext == null) {
      return;
    }

    Scrollable.ensureVisible(
      targetContext,
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeOutCubic,
      alignment: 0.05,
    );
  }

  Future<void> _deleteExpense(Expense expense) async {
    if (expense.id == null) {
      return;
    }

    final bool? shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete Expense'),
          content: Text(
            'Are you sure you want to delete '
            '"${expense.title}"?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              style: FilledButton.styleFrom(backgroundColor: _expenseDanger),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true) {
      return;
    }

    try {
      await _expenseRepository.deleteExpense(expense.id!);

      if (!mounted) return;

      await _loadExpenses();

      if (!mounted) return;

      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${expense.title} deleted'),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
          persist: false,
          action: SnackBarAction(
            label: 'UNDO',
            onPressed: () async {
              try {
                await _expenseRepository.insertExpense(expense);

                if (!mounted) return;

                await _loadExpenses();
              } catch (_) {
                if (!mounted) return;

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Could not restore expense.'),
                    behavior: SnackBarBehavior.floating,
                    duration: Duration(seconds: 2),
                    persist: false,
                  ),
                );
              }
            },
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not delete expense: $error'),
          backgroundColor: _expenseDanger,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
          persist: false,
        ),
      );
    }
  }

  String _formatAmount(double amount) {
    return 'KSh ${amount.toStringAsFixed(2)}';
  }

  String _formatTime(DateTime dateTime) {
    final local = dateTime.toLocal();

    final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;

    final minute = local.minute.toString().padLeft(2, '0');

    final period = local.hour >= 12 ? 'PM' : 'AM';

    return '$hour:$minute $period';
  }

  String _formatDate(DateTime dateTime) {
    final now = DateTime.now();

    final today = DateTime(now.year, now.month, now.day);

    final expenseDate = DateTime(dateTime.year, dateTime.month, dateTime.day);

    final difference = today.difference(expenseDate).inDays;

    if (difference == 0) {
      return 'Today';
    }

    if (difference == 1) {
      return 'Yesterday';
    }

    final local = dateTime.toLocal();

    return '${local.day.toString().padLeft(2, '0')}/'
        '${local.month.toString().padLeft(2, '0')}/'
        '${local.year}';
  }

  String _formatTimestamp(DateTime dateTime) {
    return '${_formatDate(dateTime)} · '
        '${_formatTime(dateTime)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _expenseBackground,
      appBar: AppBar(
        title: const Text(
          'Expenses',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            onPressed: _isLoading ? null : _loadExpenses,
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh expenses',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'expenses_add_fab',
        onPressed: _openAddExpense,
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'Add Expense',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return RefreshIndicator(
        onRefresh: _loadExpenses,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            const SizedBox(height: 180),
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Icon(
                      Icons.error_outline_rounded,
                      size: 52,
                      color: _expenseDanger,
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
                      onPressed: _loadExpenses,
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Try Again'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadExpenses,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
        children: [
          _buildSummaryCard(),

          const SizedBox(height: 24),

          _buildHistoryHeader(),

          const SizedBox(height: 12),

          if (_expenses.isEmpty)
            _buildEmptyState()
          else
            ..._expenses.map(
              (expense) => _ExpenseTile(
                expense: expense,
                amount: _formatAmount(expense.amount),
                timestamp: _formatTimestamp(expense.createdAt),
                onTap: () => _openExpenseDetails(expense),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF8B3A3A), Color(0xFF5E2424)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
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
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.13),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Icon(
                  Icons.payments_outlined,
                  color: Colors.white,
                  size: 23,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total Expenses',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Money spent by the business',
                      style: TextStyle(color: Colors.white70, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            _formatAmount(_totalExpenses),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.receipt_long_outlined,
                      color: Colors.white70,
                      size: 16,
                    ),
                    const SizedBox(width: 7),
                    Text(
                      '${_expenses.length} '
                      '${_expenses.length == 1 ? 'expense' : 'expenses'}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              if (_expenses.isNotEmpty)
                TextButton.icon(
                  onPressed: _scrollToHistory,
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  icon: const Icon(Icons.history_rounded, size: 16),
                  label: const Text(
                    'View history',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryHeader() {
    return Row(
      key: _historyKey,
      children: [
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Expense history',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: _expenseTextPrimary,
                ),
              ),
              SizedBox(height: 3),
              Text(
                'Tap a record or view details.',
                style: TextStyle(fontSize: 11, color: _expenseTextSecondary),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFE1E9E4)),
          ),
          child: Text(
            '${_expenses.length}',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: _expensePrimary,
            ),
          ),
        ),
      ],
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
                color: const Color(0xFFF5F8F6),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(
                Icons.receipt_long_outlined,
                size: 34,
                color: _expenseTextSecondary,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'No expenses recorded yet',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 7),
            Text(
              'Record your first business expense '
              'to start tracking your spending.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 13,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 18),
          ],
        ),
      ),
    );
  }
}

class _ExpenseTile extends StatelessWidget {
  final Expense expense;
  final String amount;
  final String timestamp;
  final VoidCallback onTap;

  const _ExpenseTile({
    required this.expense,
    required this.amount,
    required this.timestamp,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
        child: Column(
          children: [
            InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFCEAEA),
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: const Icon(
                        Icons.receipt_long_rounded,
                        color: Color(0xFF8B3A3A),
                        size: 23,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            expense.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: _expenseTextPrimary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF5F8F6),
                                  borderRadius: BorderRadius.circular(7),
                                ),
                                child: Text(
                                  expense.category,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: _expenseTextSecondary,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 7),
                              Expanded(
                                child: Text(
                                  timestamp,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: Color(0xFF7A8580),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      amount,
                      style: const TextStyle(
                        color: _expenseDanger,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: onTap,
                style: TextButton.styleFrom(
                  foregroundColor: _expensePrimary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                icon: const Icon(Icons.visibility_outlined, size: 16),
                label: const Text(
                  'View details',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
