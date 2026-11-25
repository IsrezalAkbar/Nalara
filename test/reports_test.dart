import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nalara/analytics.dart';
import 'package:nalara/exports.dart';
import 'package:nalara/transactions.dart';
import 'package:nalara/screens/reports_screen.dart';

void main() {
  test('Analytics use a half-open date range and historical cost', () {
    final start = DateTime(2026, 10, 1);
    final end = DateTime(2026, 10, 3);
    SaleTransaction sale(String id, DateTime date) => SaleTransaction(
      id: id,
      date: date,
      method: 'Tunai',
      items: [
        const TransactionItem('Produk', 100, 2, productId: 'p', cost: 30),
      ],
      discount: 10,
    );
    final report = SalesAnalytics(
      [
        sale('1', start),
        sale('2', end.subtract(const Duration(seconds: 1))),
        sale('3', end),
      ],
      start,
      end,
    );
    expect(report.revenue, 380);
    expect(report.cost, 120);
    expect(report.profit, 260);
    expect(report.dailyRevenue, [190, 190]);
    expect(report.ranking.single.value, 4);
  });
  test('CSV escapes quotes and spreadsheet formulas', () {
    expect(csvCell('a"b'), '"a""b"');
    expect(csvCell('=1+1').contains("'=1+1"), isTrue);
  });
  testWidgets('Empty report has no invented revenue or ingredient stock', (
    tester,
  ) async {
    TransactionHistory.instance.replace([]);
    await tester.pumpWidget(const MaterialApp(home: ReportsScreen()));
    expect(find.text('Belum ada transaksi pada periode ini.'), findsOneWidget);
    expect(find.text('Gula Aren'), findsNothing);
    expect(find.textContaining('Estimasi demo'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
