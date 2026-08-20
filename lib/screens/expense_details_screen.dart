import 'package:flutter/material.dart';

import '../models/expense.dart';

const Color _expenseDetailBackground = Color(0xFFF6F8F7);
const Color _expenseDetailTextPrimary = Color(0xFF17221D);
const Color _expenseDetailTextSecondary = Color(0xFF66736D);
const Color _expenseDetailDanger = Color(0xFFD64545);

class ExpenseDetailsScreen extends StatelessWidget {
  final Expense expense;

  const ExpenseDetailsScreen({super.key, required this.expense});

  String _formatAmount(double amount) {
    return 'KSh ${amount.toStringAsFixed(2)}';
  }

  String _formatTime(DateTime date) {
    final local = date.toLocal();

    final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;

    final minute = local.minute.toString().padLeft(2, '0');

    final period = local.hour >= 12 ? 'PM' : 'AM';

    return '$hour:$minute $period';
  }

  String _formatFullDate(DateTime date) {
    final local = date.toLocal();

    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

    return '${local.day} '
        '${months[local.month - 1]} '
        '${local.year}';
  }

  String _formatDateTime(DateTime date) {
    return '${_formatFullDate(date)} '
        'at ${_formatTime(date)}';
  }

  Future<void> _confirmDelete(BuildContext context) async {
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
              style: FilledButton.styleFrom(
                backgroundColor: _expenseDetailDanger,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true || !context.mounted) {
      return;
    }

    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _expenseDetailBackground,
      appBar: AppBar(
        title: const Text(
          'Expense Details',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        children: [
          _buildHero(),
          const SizedBox(height: 20),
          const Text(
            'Expense information',
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w800,
              color: _expenseDetailTextPrimary,
            ),
          ),
          const SizedBox(height: 12),
          _buildInformationCard(),
          const SizedBox(height: 22),
          OutlinedButton.icon(
            onPressed: () => _confirmDelete(context),
            icon: const Icon(Icons.delete_outline_rounded),
            label: const Text('Delete Expense'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(50),
              foregroundColor: _expenseDetailDanger,
              side: const BorderSide(color: _expenseDetailDanger),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHero() {
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
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.13),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.receipt_long_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const Spacer(),
              if (expense.id != null)
                Text(
                  '#${expense.id}',
                  style: const TextStyle(
                    color: Colors.white60,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 18),
          const Text(
            'Expense amount',
            style: TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 4),
          Text(
            _formatAmount(expense.amount),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 31,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            expense.title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 5),
          Row(
            children: [
              const Icon(
                Icons.category_outlined,
                color: Colors.white60,
                size: 15,
              ),
              const SizedBox(width: 5),
              Text(
                expense.category,
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInformationCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            _DetailRow(
              icon: Icons.description_outlined,
              label: 'Description',
              value: expense.title,
            ),
            const Divider(height: 24),
            _DetailRow(
              icon: Icons.category_outlined,
              label: 'Category',
              value: expense.category,
            ),
            const Divider(height: 24),
            _DetailRow(
              icon: Icons.payments_outlined,
              label: 'Amount',
              value: _formatAmount(expense.amount),
              valueColor: _expenseDetailDanger,
            ),
            const Divider(height: 24),
            _DetailRow(
              icon: Icons.calendar_today_outlined,
              label: 'Date',
              value: _formatFullDate(expense.createdAt),
            ),
            const Divider(height: 24),
            _DetailRow(
              icon: Icons.schedule_outlined,
              label: 'Time',
              value: _formatTime(expense.createdAt),
            ),
            const Divider(height: 24),
            _DetailRow(
              icon: Icons.event_note_outlined,
              label: 'Recorded',
              value: _formatDateTime(expense.createdAt),
            ),
            if (expense.id != null) ...[
              const Divider(height: 24),
              _DetailRow(
                icon: Icons.tag_outlined,
                label: 'Expense ID',
                value: '#${expense.id}',
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: const Color(0xFFFCEAEA),
            borderRadius: BorderRadius.circular(11),
          ),
          child: const Icon(
            Icons.receipt_long_outlined,
            size: 20,
            color: Color(0xFF8B3A3A),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: _expenseDetailTextSecondary,
              fontSize: 12,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: TextStyle(
              color: valueColor ?? _expenseDetailTextPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}
