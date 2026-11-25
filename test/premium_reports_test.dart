import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nalara/analytics.dart';
import 'package:nalara/products.dart';
import 'package:nalara/report_metrics.dart';
import 'package:nalara/screens/reports_screen.dart';
import 'package:nalara/session.dart';
import 'package:nalara/transactions.dart';
import 'package:nalara/widgets/premium_report_pages.dart';
import 'package:nalara/widgets/report_chart.dart';
import 'package:nalara/widgets/stock_history_sheet.dart';

void main() {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final product = Product(
    id: 'coffee',
    name: 'Kopi Susu',
    price: 20000,
    cost: 8000,
    stock: 5,
    minimumStock: 10,
  );
  SaleTransaction sale(String id, DateTime date, int quantity) =>
      SaleTransaction(
        id: id,
        date: date,
        method: 'Tunai',
        items: [
          TransactionItem(
            product.name,
            product.price,
            quantity,
            productId: product.id,
            cost: product.cost,
          ),
        ],
      );

  setUp(() {
    StoreSession.instance.premium.value = true;
    ProductCatalog.instance.replace([product]);
    TransactionHistory.instance.replace([
      sale('today', today, 3),
      sale('yesterday', today.subtract(const Duration(days: 1)), 2),
      sale('previous', today.subtract(const Duration(days: 8)), 8),
    ]);
  });
  tearDown(() {
    StoreSession.instance.premium.value = false;
    ProductCatalog.instance.replace([]);
    TransactionHistory.instance.replace([]);
  });

  test('Product profit preserves discount totals and distinguishes duplicate names', () {
    final report = SalesAnalytics(
      [
        SaleTransaction(
          id: 'discount',
          date: today,
          method: 'Tunai',
          discount: 7,
          items: const [
            TransactionItem('Produk', 100, 2, productId: 'a', cost: 40),
            TransactionItem('Produk', 100, 1, productId: 'b', cost: 30),
            TransactionItem('Produk', 100, 1, productId: 'c', cost: 150),
          ],
        ),
      ],
      today,
      today.add(const Duration(days: 1)),
    );
    final products = productPerformance(report);
    expect(products.length, 3);
    expect(
      products.fold<int>(0, (amount, p) => amount + p.revenue),
      report.revenue,
    );
    expect(
      products.fold<int>(0, (amount, p) => amount + p.profit),
      report.profit,
    );
    expect(products.first.quantity, 2);
    expect(products.singleWhere((p) => p.id == 'c').profit, lessThan(0));
  });

  test('Large discounts never give a small product negative revenue', () {
    final report = SalesAnalytics(
      [
        SaleTransaction(
          id: 'discount',
          date: today,
          method: 'Tunai',
          discount: 9,
          items: [
            for (var i = 0; i < 10; i++)
              TransactionItem('Produk $i', 1, 1, productId: '$i'),
          ],
        ),
      ],
      today,
      today.add(const Duration(days: 1)),
    );
    final products = productPerformance(report);
    expect(products.every((p) => p.revenue >= 0 && p.revenue <= 1), isTrue);
    expect(
      products.fold<int>(0, (amount, p) => amount + p.revenue),
      report.revenue,
    );
  });

  testWidgets('Profit uses calendar month and applies a custom range', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: ReportsScreen(view: ReportView.profit)),
    );
    expect(find.text('LABA KOTOR BULAN INI'), findsOneWidget);
    expect(
      tester.widget<ReportChart>(find.byType(ReportChart)).values.length,
      today.day,
    );
    await tester.tap(find.text('Custom'));
    await tester.pumpAndSettle();
    final picker = find.byType(DateRangePickerDialog);
    expect(picker, findsOneWidget);
    Navigator.of(tester.element(picker)).pop(
      DateTimeRange(start: today.subtract(const Duration(days: 2)), end: today),
    );
    await tester.pumpAndSettle();
    expect(find.text('LABA KOTOR BULAN INI'), findsNothing);
    expect(find.text('LABA KOTOR PERIODE INI'), findsOneWidget);
    expect(
      tester.widget<ReportChart>(find.byType(ReportChart)).values.length,
      3,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Empty reports and deleted product details remain usable with large text',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(320, 640);
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      ProductCatalog.instance.replace([]);
      TransactionHistory.instance.replace([]);
      for (final view in ReportView.values.where(
        (v) => v != ReportView.overview,
      )) {
        await tester.pumpWidget(
          MaterialApp(
            home: ReportsScreen(
              key: ValueKey(view),
              view: view,
              productId: 'deleted',
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: '$view with empty data');
      }
      final addStock = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Tambah Stok'),
      );
      expect(addStock.onPressed, isNull);
    },
  );

  testWidgets('Sales period changes the summary and chart together', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: ReportsScreen(view: ReportView.sales)),
    );
    expect(find.text('Rp100.000'), findsOneWidget);
    expect(
      tester.widget<ReportChart>(find.byType(ReportChart)).values.length,
      7,
    );
    await tester.tap(find.text('Hari Ini'));
    await tester.pumpAndSettle();
    expect(
      find.text('Rp60.000'),
      findsNWidgets(2),
    ); // Revenue and average transaction.
    expect(tester.widget<ReportChart>(find.byType(ReportChart)).values, [
      60000.0,
    ]);
    await tester.tap(find.text('30 Hari'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<ReportChart>(find.byType(ReportChart)).values.length,
      30,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Insights open the selected stock detail and return to insights',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: ReportsScreen(view: ReportView.insights)),
      );
      await tester.tap(find.text('Lihat Stok'));
      await tester.pumpAndSettle();
      expect(find.text('Detail Insight'), findsOneWidget);
      expect(find.text('Kopi Susu'), findsOneWidget);
      expect(find.text('Proyeksi Stok (7 Hari)'), findsOneWidget);
      await tester.tap(find.text('Tambah Stok'));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsOneWidget);
      await tester.tap(find.text('Tambah'));
      await tester.pumpAndSettle();
      expect(find.text('Masukkan jumlah lebih dari nol.'), findsOneWidget);
      await tester.tap(find.text('Batal'));
      await tester.pumpAndSettle();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.byTooltip('Kembali'));
      await tester.pumpAndSettle();
      expect(find.text('Insight Bisnis'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Every premium report handles small screens and enlarged text', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    for (final size in [const Size(360, 800), const Size(640, 320)]) {
      tester.view.physicalSize = size;
      for (final scale in [1.0, 2.0]) {
        tester.platformDispatcher.textScaleFactorTestValue = scale;
        for (final view in ReportView.values.where(
          (v) => v != ReportView.overview,
        )) {
          await tester.pumpWidget(
            MaterialApp(
              home: ReportsScreen(
                key: ValueKey('$size-$scale-$view'),
                view: view,
                productId: product.id,
              ),
            ),
          );
          await tester.pumpAndSettle();
          expect(
            tester.takeException(),
            isNull,
            reason: '$view at $size, text $scale',
          );
          await tester.drag(
            find.byType(SingleChildScrollView).first,
            const Offset(0, -2400),
          );
          await tester.pumpAndSettle();
          expect(
            tester.takeException(),
            isNull,
            reason: '$view scrolled at $size, text $scale',
          );
        }
      }
    }
  });

  testWidgets('Expired premium replaces report with package access screen', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: ReportsScreen(view: ReportView.profit)),
    );
    expect(find.byType(PremiumReportPage), findsOneWidget);
    StoreSession.instance.premium.value = false;
    await tester.pumpAndSettle();
    expect(find.byType(PremiumReportPage), findsNothing);
    expect(find.text('Lihat Paket'), findsOneWidget);
  });

  testWidgets('Report picker switches views without stacking report routes', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: ReportsScreen()));
    for (final view in [
      ReportView.insights,
      ReportView.sales,
      ReportView.profit,
      ReportView.overview,
    ]) {
      await tester.tap(find.byTooltip('Pilih laporan'));
      await tester.pumpAndSettle();
      final option = find.byKey(ValueKey('report-option-${view.name}'));
      await tester.ensureVisible(option);
      await tester.tap(option);
      await tester.pumpAndSettle();
      expect(find.byKey(ValueKey('report-option-${view.name}')), findsNothing);
      expect(find.byType(ReportsScreen), findsOneWidget);
      expect(
        Navigator.of(tester.element(find.byType(ReportsScreen))).canPop(),
        isFalse,
      );
      if (view != ReportView.overview) {
        expect(
          tester.widget<PremiumReportPage>(find.byType(PremiumReportPage)).view,
          view,
        );
      } else {
        expect(find.byType(PremiumReportPage), findsNothing);
      }
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets(
    'Report picker remains scrollable and Basic keeps its access gate',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(640, 320);
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      StoreSession.instance.premium.value = false;
      await tester.pumpWidget(const MaterialApp(home: ReportsScreen()));
      await tester.tap(find.byTooltip('Pilih laporan'));
      await tester.pumpAndSettle();
      final insight = find.byKey(const ValueKey('report-option-insights'));
      await tester.ensureVisible(insight);
      await tester.tap(insight);
      await tester.pumpAndSettle();
      expect(find.text('Lihat Paket'), findsOneWidget);
      expect(find.byType(PremiumReportPage), findsNothing);
      await tester.tap(find.byTooltip('Pilih laporan'));
      await tester.pumpAndSettle();
      final overview = find.byKey(const ValueKey('report-option-overview'));
      await tester.ensureVisible(overview);
      await tester.tap(overview);
      await tester.pumpAndSettle();
      expect(find.text('Lihat Paket'), findsNothing);
      expect(find.text('Analitik Bisnis'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Stock history displays recorded additions newest first', (
    tester,
  ) async {
    final ref = FakeFirebaseFirestore().collection('stockMovements');
    await ref.doc('older').set({
      'productId': product.id,
      'quantity': 4,
      'date': Timestamp.fromDate(today.subtract(const Duration(days: 1))),
    });
    await ref.doc('newer').set({
      'productId': product.id,
      'quantity': 10,
      'date': Timestamp.fromDate(today),
    });
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StockHistorySheet(
            product: product,
            movements: ref
                .where('productId', isEqualTo: product.id)
                .snapshots(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      tester.getTopLeft(find.text('+10 pcs')).dy,
      lessThan(tester.getTopLeft(find.text('+4 pcs')).dy),
    );
    expect(tester.takeException(), isNull);
  });
}
