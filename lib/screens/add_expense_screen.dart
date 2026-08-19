import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/expense.dart';
import '../repositories/expense_repository.dart';

class AddExpenseScreen extends StatefulWidget {
  final ExpenseRepository? expenseRepository;

  const AddExpenseScreen({super.key, this.expenseRepository});

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  late final ExpenseRepository _expenseRepository;

  final TextEditingController _titleController = TextEditingController();

  final TextEditingController _amountController = TextEditingController();

  String _selectedCategory = 'Other';

  bool _isSaving = false;

  static const Color primary = Color(0xFF176B4D);
  static const Color softGreen = Color(0xFFE1F1EA);
  static const Color background = Color(0xFFF6F8F7);
  static const Color textPrimary = Color(0xFF17221D);
  static const Color textSecondary = Color(0xFF66736D);
  static const Color danger = Color(0xFFD64545);

  static const List<String> _categories = [
    'Transport',
    'Rent',
    'Electricity',
    'Airtime',
    'Supplies',
    'Salary',
    'Maintenance',
    'Other',
  ];

  @override
  void initState() {
    super.initState();

    _expenseRepository = widget.expenseRepository ?? ExpenseRepository();

    _amountController.addListener(_refreshPreview);
  }

  @override
  void dispose() {
    _amountController.removeListener(_refreshPreview);
    _titleController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  void _refreshPreview() {
    if (mounted) {
      setState(() {});
    }
  }

  double get _amount {
    return double.tryParse(_amountController.text.trim()) ?? 0;
  }

  Future<void> _saveExpense() async {
    FocusScope.of(context).unfocus();

    final String title = _titleController.text.trim();

    if (title.isEmpty) {
      _showMessage('Please enter an expense description.');
      return;
    }

    if (_amount <= 0) {
      _showMessage('Please enter a valid amount.');
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final expense = Expense(
        title: title,
        amount: _amount,
        category: _selectedCategory,
        createdAt: DateTime.now(),
      );

      await _expenseRepository.insertExpense(expense);

      if (!mounted) return;

      _titleController.clear();
      _amountController.clear();

      setState(() {
        _selectedCategory = 'Other';
        _isSaving = false;
      });

      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Expense recorded successfully.'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: primary,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _isSaving = false;
      });

      _showMessage('Something went wrong while saving the expense.');
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF202824),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        title: const Text(
          'Add Expense',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),

              const SizedBox(height: 18),

              _buildExpenseForm(),

              const SizedBox(height: 14),

              _buildAmountPreview(),

              const SizedBox(height: 22),

              SizedBox(
                width: double.infinity,
                height: 54,
                child: FilledButton.icon(
                  onPressed: _isSaving ? null : _saveExpense,
                  icon: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.check_rounded),
                  label: Text(_isSaving ? 'Saving Expense...' : 'Save Expense'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFFCEAEA),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(
              Icons.receipt_long_rounded,
              color: Colors.red.shade700,
              size: 26,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Record an expense',
                  style: TextStyle(
                    color: textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Track money spent by the business.',
                  style: TextStyle(color: textSecondary, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpenseForm() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Expense information',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Add the details of this expense.',
              style: TextStyle(fontSize: 11, color: textSecondary),
            ),
            const SizedBox(height: 14),

            TextField(
              controller: _titleController,
              enabled: !_isSaving,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Description',
                hintText: 'e.g. Transport to supplier',
                prefixIcon: Icon(Icons.description_outlined),
              ),
            ),

            const SizedBox(height: 14),

            TextField(
              controller: _amountController,
              enabled: !_isSaving,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
              ],
              decoration: const InputDecoration(
                labelText: 'Amount',
                hintText: 'Enter amount',
                prefixText: 'KSh ',
                prefixIcon: Icon(Icons.payments_outlined),
              ),
            ),

            const SizedBox(height: 14),

            DropdownButtonFormField<String>(
              value: _selectedCategory,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Category',
                prefixIcon: Icon(Icons.category_outlined),
              ),
              items: _categories.map((category) {
                return DropdownMenuItem<String>(
                  value: category,
                  child: Text(category),
                );
              }).toList(),
              onChanged: _isSaving
                  ? null
                  : (value) {
                      if (value == null) {
                        return;
                      }

                      setState(() {
                        _selectedCategory = value;
                      });
                    },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAmountPreview() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: const Color(0xFFE1E9E4)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: softGreen,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.account_balance_wallet_outlined,
              color: primary,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Expense total',
                  style: TextStyle(
                    fontSize: 12,
                    color: textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Amount that will be recorded',
                  style: TextStyle(fontSize: 11, color: textSecondary),
                ),
              ],
            ),
          ),
          Text(
            'KSh ${_amount.toStringAsFixed(2)}',
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: danger,
            ),
          ),
        ],
      ),
    );
  }
}
