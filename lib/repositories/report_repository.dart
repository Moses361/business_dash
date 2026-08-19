import 'package:sqflite/sqflite.dart';

import '../database/database_service.dart';

class ReportSummary {
  final double sales;
  final double costOfGoods;
  final double grossProfit;
  final double expenses;
  final double netProfit;
  final int transactions;
  final int itemsSold;

  const ReportSummary({
    required this.sales,
    required this.costOfGoods,
    required this.grossProfit,
    required this.expenses,
    required this.netProfit,
    required this.transactions,
    required this.itemsSold,
  });
}

class DailyReport {
  final DateTime date;
  final double sales;
  final double profit;
  final double expenses;

  const DailyReport({
    required this.date,
    required this.sales,
    required this.profit,
    required this.expenses,
  });

  double get netProfit => profit - expenses;
}

class CategoryReport {
  final String category;
  final double sales;
  final double profit;

  const CategoryReport({
    required this.category,
    required this.sales,
    required this.profit,
  });
}

class TopSellingProduct {
  final int? productId;
  final String productName;
  final int quantitySold;
  final double sales;
  final double profit;

  const TopSellingProduct({
    required this.productId,
    required this.productName,
    required this.quantitySold,
    required this.sales,
    required this.profit,
  });
}

class ReportRepository {
  final DatabaseService _databaseService;

  ReportRepository({DatabaseService? databaseService})
    : _databaseService = databaseService ?? DatabaseService();

  String _dateOnly(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }

  Future<ReportSummary> getSummary({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final Database database = await _databaseService.database;

    final String start = _dateOnly(startDate);
    final String end = _dateOnly(endDate.add(const Duration(days: 1)));

    final salesResult = await database.rawQuery(
      '''
      SELECT
        COALESCE(SUM(total_amount), 0) AS sales,
        COALESCE(SUM(buying_price * quantity), 0) AS cost,
        COALESCE(
          SUM((selling_price - buying_price) * quantity),
          0
        ) AS profit,
        COALESCE(SUM(quantity), 0) AS items,
        COUNT(*) AS transactions
      FROM ${DatabaseService.salesTable}
      WHERE substr(created_at, 1, 10) >= ?
        AND substr(created_at, 1, 10) < ?
      ''',
      [start, end],
    );

    final expensesResult = await database.rawQuery(
      '''
      SELECT COALESCE(SUM(amount), 0) AS expenses
      FROM ${DatabaseService.expensesTable}
      WHERE substr(created_at, 1, 10) >= ?
        AND substr(created_at, 1, 10) < ?
      ''',
      [start, end],
    );

    final Map<String, dynamic> row = salesResult.first;

    final double sales = (row['sales'] as num?)?.toDouble() ?? 0.0;

    final double costOfGoods = (row['cost'] as num?)?.toDouble() ?? 0.0;

    final double grossProfit = (row['profit'] as num?)?.toDouble() ?? 0.0;

    final double expenses =
        (expensesResult.first['expenses'] as num?)?.toDouble() ?? 0.0;

    final int transactions = (row['transactions'] as num?)?.toInt() ?? 0;

    final int itemsSold = (row['items'] as num?)?.toInt() ?? 0;

    return ReportSummary(
      sales: sales,
      costOfGoods: costOfGoods,
      grossProfit: grossProfit,
      expenses: expenses,
      netProfit: grossProfit - expenses,
      transactions: transactions,
      itemsSold: itemsSold,
    );
  }

  Future<List<DailyReport>> getDailyReports({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final Database database = await _databaseService.database;

    final String start = _dateOnly(startDate);
    final String end = _dateOnly(endDate.add(const Duration(days: 1)));

    final List<Map<String, dynamic>> salesRows = await database.rawQuery(
      '''
      SELECT
        substr(created_at, 1, 10) AS report_date,
        COALESCE(SUM(total_amount), 0) AS sales,
        COALESCE(
          SUM((selling_price - buying_price) * quantity),
          0
        ) AS profit
      FROM ${DatabaseService.salesTable}
      WHERE substr(created_at, 1, 10) >= ?
        AND substr(created_at, 1, 10) < ?
      GROUP BY substr(created_at, 1, 10)
      ORDER BY report_date ASC
      ''',
      [start, end],
    );

    final List<Map<String, dynamic>> expenseRows = await database.rawQuery(
      '''
      SELECT
        substr(created_at, 1, 10) AS report_date,
        COALESCE(SUM(amount), 0) AS expenses
      FROM ${DatabaseService.expensesTable}
      WHERE substr(created_at, 1, 10) >= ?
        AND substr(created_at, 1, 10) < ?
      GROUP BY substr(created_at, 1, 10)
      ORDER BY report_date ASC
      ''',
      [start, end],
    );

    final Map<String, double> sales = {};
    final Map<String, double> profits = {};
    final Map<String, double> expenses = {};

    for (final row in salesRows) {
      final String date = row['report_date'] as String;

      sales[date] = (row['sales'] as num?)?.toDouble() ?? 0.0;

      profits[date] = (row['profit'] as num?)?.toDouble() ?? 0.0;
    }

    for (final row in expenseRows) {
      final String date = row['report_date'] as String;

      expenses[date] = (row['expenses'] as num?)?.toDouble() ?? 0.0;
    }

    final Set<String> dates = {...sales.keys, ...expenses.keys};

    final List<DailyReport> reports = dates.map((date) {
      return DailyReport(
        date: DateTime.parse(date),
        sales: sales[date] ?? 0.0,
        profit: profits[date] ?? 0.0,
        expenses: expenses[date] ?? 0.0,
      );
    }).toList();

    reports.sort((a, b) => a.date.compareTo(b.date));

    return reports;
  }

  Future<List<CategoryReport>> getCategoryReports({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final Database database = await _databaseService.database;

    final String start = _dateOnly(startDate);
    final String end = _dateOnly(endDate.add(const Duration(days: 1)));

    final List<Map<String, dynamic>> rows = await database.rawQuery(
      '''
      SELECT
        COALESCE(p.category, 'Other') AS category,
        COALESCE(SUM(s.total_amount), 0) AS sales,
        COALESCE(
          SUM(
            (s.selling_price - s.buying_price) * s.quantity
          ),
          0
        ) AS profit
      FROM ${DatabaseService.salesTable} s
      LEFT JOIN ${DatabaseService.productsTable} p
        ON p.id = s.product_id
      WHERE substr(s.created_at, 1, 10) >= ?
        AND substr(s.created_at, 1, 10) < ?
      GROUP BY COALESCE(p.category, 'Other')
      ORDER BY sales DESC
      ''',
      [start, end],
    );

    return rows.map((row) {
      return CategoryReport(
        category: row['category'] as String,
        sales: (row['sales'] as num?)?.toDouble() ?? 0.0,
        profit: (row['profit'] as num?)?.toDouble() ?? 0.0,
      );
    }).toList();
  }

  Future<List<TopSellingProduct>> getTopSellingProducts({
    required DateTime startDate,
    required DateTime endDate,
    int limit = 10,
  }) async {
    final Database database = await _databaseService.database;

    final String start = _dateOnly(startDate);
    final String end = _dateOnly(endDate.add(const Duration(days: 1)));

    final List<Map<String, dynamic>> rows = await database.rawQuery(
      '''
      SELECT
        s.product_id AS product_id,
        COALESCE(p.name, 'Unknown Product') AS product_name,
        COALESCE(SUM(s.quantity), 0) AS quantity_sold,
        COALESCE(SUM(s.total_amount), 0) AS sales,
        COALESCE(
          SUM(
            (s.selling_price - s.buying_price) * s.quantity
          ),
          0
        ) AS profit
      FROM ${DatabaseService.salesTable} s
      LEFT JOIN ${DatabaseService.productsTable} p
        ON p.id = s.product_id
      WHERE substr(s.created_at, 1, 10) >= ?
        AND substr(s.created_at, 1, 10) < ?
      GROUP BY s.product_id, p.name
      ORDER BY quantity_sold DESC
      LIMIT ?
      ''',
      [start, end, limit],
    );

    return rows.map((row) {
      return TopSellingProduct(
        productId: (row['product_id'] as num?)?.toInt(),
        productName: row['product_name'] as String,
        quantitySold: (row['quantity_sold'] as num?)?.toInt() ?? 0,
        sales: (row['sales'] as num?)?.toDouble() ?? 0.0,
        profit: (row['profit'] as num?)?.toDouble() ?? 0.0,
      );
    }).toList();
  }
}
