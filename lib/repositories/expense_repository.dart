import 'package:sqflite/sqflite.dart';

import '../database/database_service.dart';
import '../models/expense.dart';

class ExpenseRepository {
  final DatabaseService _databaseService;

  ExpenseRepository({DatabaseService? databaseService})
    : _databaseService = databaseService ?? DatabaseService();

  Future<int> insertExpense(Expense expense) async {
    final Database database = await _databaseService.database;

    return database.insert(DatabaseService.expensesTable, {
      'title': expense.title,
      'amount': expense.amount,
      'category': expense.category,
      'created_at': expense.createdAt.toIso8601String(),
    });
  }

  Future<List<Expense>> getExpenses() async {
    final Database database = await _databaseService.database;

    final rows = await database.query(
      DatabaseService.expensesTable,
      orderBy: 'id DESC',
    );

    return rows.map((row) {
      return Expense(
        id: row['id'] as int,
        title: row['title'] as String,
        amount: (row['amount'] as num).toDouble(),
        category: row['category'] as String,
        createdAt: DateTime.parse(row['created_at'] as String),
      );
    }).toList();
  }

  Future<double> getTotalExpenses() async {
    final Database database = await _databaseService.database;

    final result = await database.rawQuery('''
      SELECT COALESCE(SUM(amount), 0) AS total
      FROM ${DatabaseService.expensesTable}
    ''');

    final total = result.first['total'];

    return (total as num?)?.toDouble() ?? 0.0;
  }

  Future<double> getTodayExpenses() async {
    final Database database = await _databaseService.database;

    final today = DateTime.now().toIso8601String().substring(0, 10);

    final result = await database.rawQuery(
      '''
      SELECT COALESCE(SUM(amount), 0) AS total
      FROM ${DatabaseService.expensesTable}
      WHERE substr(created_at, 1, 10) = ?
      ''',
      [today],
    );

    final total = result.first['total'];

    return (total as num?)?.toDouble() ?? 0.0;
  }

  Future<double> getThisMonthExpenses() async {
    final Database database = await _databaseService.database;

    final now = DateTime.now();

    final monthStart =
        '${now.year.toString().padLeft(4, '0')}-'
        '${now.month.toString().padLeft(2, '0')}-01';

    final nextMonth = DateTime(now.year, now.month + 1, 1);

    final nextMonthStart =
        '${nextMonth.year.toString().padLeft(4, '0')}-'
        '${nextMonth.month.toString().padLeft(2, '0')}-01';

    final result = await database.rawQuery(
      '''
      SELECT COALESCE(SUM(amount), 0) AS total
      FROM ${DatabaseService.expensesTable}
      WHERE substr(created_at, 1, 10) >= ?
        AND substr(created_at, 1, 10) < ?
      ''',
      [monthStart, nextMonthStart],
    );

    final total = result.first['total'];

    return (total as num?)?.toDouble() ?? 0.0;
  }

  Future<int> getExpenseCount() async {
    final Database database = await _databaseService.database;

    final result = await database.rawQuery('''
      SELECT COUNT(*) AS count
      FROM ${DatabaseService.expensesTable}
    ''');

    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<int> getTodayExpenseCount() async {
    final Database database = await _databaseService.database;

    final today = DateTime.now().toIso8601String().substring(0, 10);

    final result = await database.rawQuery(
      '''
      SELECT COUNT(*) AS count
      FROM ${DatabaseService.expensesTable}
      WHERE substr(created_at, 1, 10) = ?
      ''',
      [today],
    );

    return Sqflite.firstIntValue(result) ?? 0;
  }
}
