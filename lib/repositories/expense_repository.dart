import 'package:sqflite/sqflite.dart';

import '../database/database_service.dart';
import '../models/expense.dart';

class ExpenseRepository {
  final DatabaseService _databaseService;

  ExpenseRepository({DatabaseService? databaseService})
    : _databaseService = databaseService ?? DatabaseService();

  Future<int> insertExpense(Expense expense) async {
    if (expense.amount <= 0) {
      throw ArgumentError('Expense amount must be greater than zero');
    }

    if (expense.title.trim().isEmpty) {
      throw ArgumentError('Expense title is required');
    }

    if (expense.category.trim().isEmpty) {
      throw ArgumentError('Expense category is required');
    }

    final Database database = await _databaseService.database;

    return database.insert(DatabaseService.expensesTable, {
      'title': expense.title.trim(),
      'amount': expense.amount,
      'category': expense.category.trim(),
      'created_at': expense.createdAt.toIso8601String(),
    });
  }

  Future<int> deleteExpense(int id) async {
    final Database database = await _databaseService.database;

    return database.delete(
      DatabaseService.expensesTable,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<Expense>> getExpenses() async {
    final Database database = await _databaseService.database;

    final rows = await database.query(
      DatabaseService.expensesTable,
      orderBy: 'created_at DESC, id DESC',
    );

    return rows.map(_expenseFromRow).toList();
  }

  Future<List<Expense>> getExpensesBetween(DateTime start, DateTime end) async {
    final Database database = await _databaseService.database;

    final rows = await database.query(
      DatabaseService.expensesTable,
      where: 'created_at >= ? AND created_at < ?',
      whereArgs: [start.toIso8601String(), end.toIso8601String()],
      orderBy: 'created_at ASC, id ASC',
    );

    return rows.map(_expenseFromRow).toList();
  }

  Future<double> getTotalExpenses() async {
    final Database database = await _databaseService.database;

    final result = await database.rawQuery('''
      SELECT COALESCE(SUM(amount), 0) AS total
      FROM ${DatabaseService.expensesTable}
    ''');

    return _doubleValue(result, 'total');
  }

  Future<double> getExpensesBetweenTotal(DateTime start, DateTime end) async {
    final Database database = await _databaseService.database;

    final result = await database.rawQuery(
      '''
      SELECT COALESCE(SUM(amount), 0) AS total
      FROM ${DatabaseService.expensesTable}
      WHERE created_at >= ? AND created_at < ?
      ''',
      [start.toIso8601String(), end.toIso8601String()],
    );

    return _doubleValue(result, 'total');
  }

  Future<double> getTodayExpenses() async {
    final now = DateTime.now();

    final start = DateTime(now.year, now.month, now.day);

    final end = start.add(const Duration(days: 1));

    return getExpensesBetweenTotal(start, end);
  }

  Future<double> getThisMonthExpenses() async {
    final now = DateTime.now();

    final start = DateTime(now.year, now.month, 1);

    final end = DateTime(now.year, now.month + 1, 1);

    return getExpensesBetweenTotal(start, end);
  }

  Future<int> getExpenseCount() async {
    final Database database = await _databaseService.database;

    final result = await database.rawQuery('''
      SELECT COUNT(*) AS count
      FROM ${DatabaseService.expensesTable}
    ''');

    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<int> getExpenseCountBetween(DateTime start, DateTime end) async {
    final Database database = await _databaseService.database;

    final result = await database.rawQuery(
      '''
      SELECT COUNT(*) AS count
      FROM ${DatabaseService.expensesTable}
      WHERE created_at >= ? AND created_at < ?
      ''',
      [start.toIso8601String(), end.toIso8601String()],
    );

    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<int> getTodayExpenseCount() async {
    final now = DateTime.now();

    final start = DateTime(now.year, now.month, now.day);

    final end = start.add(const Duration(days: 1));

    return getExpenseCountBetween(start, end);
  }

  Future<List<Map<String, dynamic>>> getExpensesByCategory({
    DateTime? start,
    DateTime? end,
  }) async {
    final Database database = await _databaseService.database;

    final whereParts = <String>[];
    final whereArgs = <dynamic>[];

    if (start != null) {
      whereParts.add('created_at >= ?');
      whereArgs.add(start.toIso8601String());
    }

    if (end != null) {
      whereParts.add('created_at < ?');
      whereArgs.add(end.toIso8601String());
    }

    final whereClause = whereParts.isEmpty
        ? ''
        : 'WHERE ${whereParts.join(' AND ')}';

    return database.rawQuery('''
      SELECT
        category,
        COUNT(*) AS count,
        COALESCE(SUM(amount), 0) AS total
      FROM ${DatabaseService.expensesTable}
      $whereClause
      GROUP BY category
      ORDER BY total DESC
      ''', whereArgs);
  }

  Future<List<Map<String, dynamic>>> getDailyExpenses(
    DateTime start,
    DateTime end,
  ) async {
    final Database database = await _databaseService.database;

    return database.rawQuery(
      '''
      SELECT
        substr(created_at, 1, 10) AS date,
        COALESCE(SUM(amount), 0) AS total,
        COUNT(*) AS count
      FROM ${DatabaseService.expensesTable}
      WHERE created_at >= ? AND created_at < ?
      GROUP BY substr(created_at, 1, 10)
      ORDER BY date ASC
      ''',
      [start.toIso8601String(), end.toIso8601String()],
    );
  }

  Expense _expenseFromRow(Map<String, dynamic> row) {
    return Expense(
      id: row['id'] as int,
      title: row['title'] as String,
      amount: (row['amount'] as num).toDouble(),
      category: row['category'] as String,
      createdAt: DateTime.parse(row['created_at'] as String),
    );
  }

  double _doubleValue(List<Map<String, dynamic>> result, String column) {
    if (result.isEmpty) {
      return 0.0;
    }

    return (result.first[column] as num?)?.toDouble() ?? 0.0;
  }
}
