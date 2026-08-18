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
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  double get _amount {
    return double.tryParse(_amountController.text.trim()) ?? 0;
  }

  Future<void> _saveExpense() async {
    FocusScope.of(context).unfocus();

    final title = _titleController.text.trim();

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

      _showMessage('Expense recorded successfully.', isError: false);
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _isSaving = false;
      });

      _showMessage('Something went wrong while saving the expense.');
    }
  }

  void _showMessage(String message, {bool isError = true}) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Expense')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(
              Icons.receipt_long_rounded,
              size: 64,
              color: Colors.green,
            ),

            const SizedBox(height: 20),

            const Text(
              'Record an Expense',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 8),

            Text(
              'Keep track of money spent by the business.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade700),
            ),

            const SizedBox(height: 32),

            TextFormField(
              controller: _titleController,
              enabled: !_isSaving,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Description',
                hintText: 'e.g. Transport to supplier',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.description_outlined),
              ),
            ),

            const SizedBox(height: 20),

            TextFormField(
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
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.payments_outlined),
              ),
            ),

            const SizedBox(height: 20),

            DropdownButtonFormField<String>(
              initialValue: _selectedCategory,
              decoration: const InputDecoration(
                labelText: 'Category',
                border: OutlineInputBorder(),
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
                      if (value == null) return;

                      setState(() {
                        _selectedCategory = value;
                      });
                    },
            ),

            const SizedBox(height: 32),

            SizedBox(
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _isSaving ? null : _saveExpense,
                icon: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save_outlined),
                label: Text(_isSaving ? 'Saving Expense...' : 'Save Expense'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
