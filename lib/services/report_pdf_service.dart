import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/expense.dart';
import '../repositories/report_repository.dart';

class ReportPdfService {
  static Future<List<int>> buildReport({
    required ReportSummary summary,
    required List<DailyReport> dailyReports,
    required List<CategoryReport> categoryReports,
    required List<Expense> expenses,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final pdf = pw.Document();

    final double grossMargin = summary.sales > 0
        ? (summary.grossProfit / summary.sales) * 100
        : 0;

    final bool isLoss = summary.netProfit < 0;

    final String period = '${_formatDate(startDate)} - ${_formatDate(endDate)}';

    final String resultText = isLoss
        ? 'Net loss: ${_formatAmount(summary.netProfit.abs())}'
        : 'Net profit: ${_formatAmount(summary.netProfit)}';

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) {
          return [
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'VEROON',
                      style: pw.TextStyle(
                        fontSize: 24,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColor.fromHex('#176B4D'),
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'Business Performance Report',
                      style: pw.TextStyle(
                        fontSize: 13,
                        color: PdfColor.fromHex('#66736D'),
                      ),
                    ),
                  ],
                ),
                pw.Text(
                  period,
                  style: pw.TextStyle(
                    fontSize: 11,
                    color: PdfColor.fromHex('#66736D'),
                  ),
                ),
              ],
            ),

            pw.SizedBox(height: 24),

            pw.Container(
              padding: const pw.EdgeInsets.all(18),
              decoration: pw.BoxDecoration(
                color: PdfColor.fromHex(isLoss ? '#FCEAEA' : '#E1F1EA'),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(12)),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    isLoss ? 'NET LOSS' : 'NET PROFIT',
                    style: pw.TextStyle(
                      fontSize: 11,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColor.fromHex(isLoss ? '#D64545' : '#176B4D'),
                    ),
                  ),
                  pw.SizedBox(height: 6),
                  pw.Text(
                    resultText,
                    style: pw.TextStyle(
                      fontSize: 22,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColor.fromHex('#17221D'),
                    ),
                  ),
                  pw.SizedBox(height: 6),
                  pw.Text(
                    isLoss
                        ? 'Sales did not fully cover stock costs and expenses for this period.'
                        : 'After stock costs and expenses, this is what the business kept.',
                    style: pw.TextStyle(
                      fontSize: 10,
                      color: PdfColor.fromHex('#66736D'),
                    ),
                  ),
                ],
              ),
            ),

            pw.SizedBox(height: 18),

            _sectionTitle('Business summary'),

            pw.SizedBox(height: 8),

            pw.Table(
              border: pw.TableBorder.all(color: PdfColor.fromHex('#E1E9E4')),
              children: [
                _summaryRow('Sales', summary.sales),
                _summaryRow('Cost of goods', summary.costOfGoods),
                _summaryRow('Gross profit', summary.grossProfit),
                _summaryRow('Gross margin', grossMargin, suffix: '%'),
                _summaryRow('Expenses', summary.expenses),
                _summaryRow(
                  isLoss ? 'Net loss' : 'Net profit',
                  summary.netProfit.abs(),
                ),
                _summaryRow('Transactions', summary.transactions),
                _summaryRow('Items sold', summary.itemsSold),
              ],
            ),

            pw.SizedBox(height: 22),

            _sectionTitle('Daily performance'),

            pw.SizedBox(height: 8),

            if (dailyReports.isEmpty)
              pw.Text(
                'No daily data for this period.',
                style: pw.TextStyle(
                  fontSize: 10,
                  color: PdfColor.fromHex('#66736D'),
                ),
              )
            else
              pw.Table.fromTextArray(
                headers: ['Date', 'Sales', 'Expenses', 'Net'],
                data: dailyReports.map((report) {
                  return [
                    _formatDate(report.date),
                    _formatAmount(report.sales),
                    _formatAmount(report.expenses),
                    _formatAmount(report.netProfit),
                  ];
                }).toList(),
                headerStyle: pw.TextStyle(
                  fontSize: 9,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white,
                ),
                headerDecoration: pw.BoxDecoration(
                  color: PdfColor.fromHex('#176B4D'),
                ),
                cellStyle: const pw.TextStyle(fontSize: 8),
                cellPadding: const pw.EdgeInsets.all(6),
              ),

            pw.SizedBox(height: 22),

            _sectionTitle('Sales by category'),

            pw.SizedBox(height: 8),

            if (categoryReports.isEmpty)
              pw.Text(
                'No category data for this period.',
                style: pw.TextStyle(
                  fontSize: 10,
                  color: PdfColor.fromHex('#66736D'),
                ),
              )
            else
              pw.Table.fromTextArray(
                headers: ['Category', 'Sales', 'Profit'],
                data: categoryReports.map((report) {
                  return [
                    report.category,
                    _formatAmount(report.sales),
                    _formatAmount(report.profit),
                  ];
                }).toList(),
                headerStyle: pw.TextStyle(
                  fontSize: 9,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white,
                ),
                headerDecoration: pw.BoxDecoration(
                  color: PdfColor.fromHex('#176B4D'),
                ),
                cellStyle: const pw.TextStyle(fontSize: 8),
                cellPadding: const pw.EdgeInsets.all(6),
              ),

            pw.SizedBox(height: 22),

            _sectionTitle('Expense breakdown'),

            pw.SizedBox(height: 8),

            if (expenses.isEmpty)
              pw.Text(
                'No expenses recorded for this period.',
                style: pw.TextStyle(
                  fontSize: 10,
                  color: PdfColor.fromHex('#66736D'),
                ),
              )
            else
              pw.Table.fromTextArray(
                headers: ['Date', 'Description', 'Category', 'Amount'],
                data: expenses.map((expense) {
                  return [
                    _formatDate(expense.createdAt),
                    expense.title,
                    expense.category,
                    _formatAmount(expense.amount),
                  ];
                }).toList(),
                headerStyle: pw.TextStyle(
                  fontSize: 9,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white,
                ),
                headerDecoration: pw.BoxDecoration(
                  color: PdfColor.fromHex('#8B3A3A'),
                ),
                cellStyle: const pw.TextStyle(fontSize: 8),
                cellPadding: const pw.EdgeInsets.all(6),
              ),

            pw.SizedBox(height: 24),

            pw.Divider(color: PdfColor.fromHex('#E1E9E4')),

            pw.SizedBox(height: 8),

            pw.Text(
              'Generated by Veroon',
              style: pw.TextStyle(
                fontSize: 8,
                color: PdfColor.fromHex('#66736D'),
              ),
            ),
          ];
        },
      ),
    );

    return pdf.save();
  }

  static pw.Widget _sectionTitle(String title) {
    return pw.Text(
      title,
      style: pw.TextStyle(
        fontSize: 15,
        fontWeight: pw.FontWeight.bold,
        color: PdfColor.fromHex('#17221D'),
      ),
    );
  }

  static pw.TableRow _summaryRow(
    String label,
    dynamic value, {
    String suffix = '',
  }) {
    final String formatted = value is num
        ? (suffix == '%'
              ? '${value.toStringAsFixed(1)}%'
              : _formatAmount(value.toDouble()))
        : '$value';

    return pw.TableRow(
      children: [
        pw.Padding(
          padding: const pw.EdgeInsets.all(7),
          child: pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: 9,
              color: PdfColor.fromHex('#66736D'),
            ),
          ),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.all(7),
          child: pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.Text(
              formatted,
              style: pw.TextStyle(
                fontSize: 9,
                fontWeight: pw.FontWeight.bold,
                color: PdfColor.fromHex('#17221D'),
              ),
            ),
          ),
        ),
      ],
    );
  }

  static String _formatAmount(double amount) {
    return 'KSh ${amount.toStringAsFixed(2)}';
  }

  static String _formatDate(DateTime date) {
    final local = date.toLocal();

    return '${local.day.toString().padLeft(2, '0')}/'
        '${local.month.toString().padLeft(2, '0')}/'
        '${local.year}';
  }
}
