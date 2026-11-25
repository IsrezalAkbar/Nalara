import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nalara/exports.dart';
import 'package:nalara/transactions.dart';
import 'package:nalara/screens/transactions_screen.dart';

void main() {
  testWidgets('Report filters an inclusive custom range and returns to today', (
    tester,
  ) async {
    final today = DateUtils.dateOnly(DateTime.now());
    final start = DateTime(today.year, today.month, today.day - 3);
    final end = DateTime(today.year, today.month, today.day - 1);
    SaleTransaction sale(String id, DateTime date, String method, int price) =>
        SaleTransaction(
          id: id,
          date: date,
          method: method,
          items: [TransactionItem(id, price, 1, productId: id)],
        );
    TransactionHistory.instance.replace([
      sale('before', start.subtract(const Duration(seconds: 1)), 'Tunai', 1000),
      sale('first', start, 'Tunai', 2000),
      sale(
        'last',
        today.subtract(const Duration(microseconds: 1)),
        'QRIS',
        3000,
      ),
      sale('today', today, 'Tunai', 9000),
    ]);
    addTearDown(() => TransactionHistory.instance.replace([]));
    await tester.pumpWidget(const MaterialApp(home: TransactionsScreen()));
    await tester.tap(find.text('Laporan Transaksi'));
    await tester.pumpAndSettle();
    String? value(String key) =>
        tester.widget<Text>(find.byKey(ValueKey(key))).data;

    Future<void> chooseRange(DateTime from, DateTime to) async {
      await tester.tap(find.text('Rentang Waktu'));
      await tester.pumpAndSettle();
      final picker = tester.widget<DateRangePickerDialog>(
        find.byType(DateRangePickerDialog),
      );
      expect(picker.lastDate, today);
      await tester.tap(find.byIcon(Icons.edit_outlined));
      await tester.pumpAndSettle();
      final fields = find.byType(TextField);
      final localizations = MaterialLocalizations.of(
        tester.element(fields.first),
      );
      await tester.enterText(
        fields.at(0),
        localizations.formatCompactDate(from),
      );
      await tester.enterText(fields.at(1), localizations.formatCompactDate(to));
      await tester.tap(find.text('Terapkan'));
      await tester.pumpAndSettle();
    }

    expect(value('daily-revenue'), 'Rp9.000');
    await chooseRange(start, end);
    expect(value('daily-revenue'), 'Rp5.000');
    expect(value('daily-count'), '2 transaksi');
    expect(value('daily-quantity'), '2 barang terjual');
    expect(value('daily-Tunai-revenue'), 'Rp2.000');
    expect(value('daily-QRIS-revenue'), 'Rp3.000');
    expect(find.byKey(const ValueKey('sold-product-first')), findsOneWidget);
    expect(find.byKey(const ValueKey('sold-product-last')), findsOneWidget);
    expect(find.byKey(const ValueKey('sold-product-before')), findsNothing);
    expect(find.byKey(const ValueKey('sold-product-today')), findsNothing);
    expect(
      find.text('${transactionDate(start)} – ${transactionDate(end)}'),
      findsOneWidget,
    );

    await tester.tap(find.text('Ubah Rentang Waktu'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Close'));
    await tester.pumpAndSettle();
    expect(value('daily-revenue'), 'Rp5.000');

    await chooseRange(end, end);
    expect(value('daily-revenue'), 'Rp3.000');
    expect(value('daily-count'), '1 transaksi');
    await chooseRange(
      start.add(const Duration(days: 1)),
      start.add(const Duration(days: 1)),
    );
    expect(value('daily-revenue'), 'Rp0');
    expect(
      find.text('Belum ada penjualan pada rentang waktu ini'),
      findsOneWidget,
    );

    await tester.tap(find.text('Hari Ini'));
    await tester.pumpAndSettle();
    expect(value('daily-revenue'), 'Rp9.000');
    expect(find.text('Ringkasan hari ini'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Daily report separates methods, aggregates sold products, and ignores history filters',
    (tester) async {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      SaleTransaction sale(
        String id,
        DateTime date,
        String method,
        List<TransactionItem> items,
      ) => SaleTransaction(id: id, date: date, method: method, items: items);
      final sales = [
        sale('cash', today, 'Tunai', [
          const TransactionItem('Kopi', 10000, 2, productId: 'coffee'),
        ]),
        sale('qris', today.add(const Duration(minutes: 1)), 'QRIS', [
          const TransactionItem('Kopi', 12000, 1, productId: 'coffee'),
          const TransactionItem('Kue', 8000, 1, productId: 'cake'),
        ]),
        sale('yesterday', today.subtract(const Duration(seconds: 1)), 'Tunai', [
          const TransactionItem('Kemarin', 90000, 1, productId: 'yesterday'),
        ]),
        sale('tomorrow', DateTime(now.year, now.month, now.day + 1), 'QRIS', [
          const TransactionItem('Besok', 90000, 1, productId: 'tomorrow'),
        ]),
      ];
      TransactionHistory.instance.replace(sales);
      addTearDown(() => TransactionHistory.instance.replace([]));
      await tester.pumpWidget(const MaterialApp(home: TransactionsScreen()));
      await tester.enterText(find.byType(TextField), 'missing');
      await tester.tap(find.text('Laporan Transaksi'));
      await tester.pumpAndSettle();
      String? value(String key) =>
          tester.widget<Text>(find.byKey(ValueKey(key))).data;
      expect(value('daily-revenue'), 'Rp40.000');
      expect(value('daily-count'), '2 transaksi');
      expect(value('daily-quantity'), '4 barang terjual');
      expect(value('daily-Tunai-revenue'), 'Rp20.000');
      expect(value('daily-QRIS-revenue'), 'Rp20.000');
      expect(value('daily-Tunai-count'), '1 transaksi');
      expect(value('daily-QRIS-count'), '1 transaksi');
      expect(find.text('3 terjual'), findsOneWidget);
      expect(find.text('Rp32.000'), findsOneWidget);
      expect(find.text('Kemarin'), findsNothing);
      expect(find.text('Besok'), findsNothing);
      TransactionHistory.instance.replace([
        ...sales,
        sale('new', today, 'QRIS', [
          const TransactionItem('Kopi', 10000, 1, productId: 'coffee'),
        ]),
      ]);
      await tester.pumpAndSettle();
      expect(value('daily-revenue'), 'Rp50.000');
      expect(value('daily-QRIS-count'), '2 transaksi');
      expect(find.text('4 terjual'), findsOneWidget);
      await tester.tap(find.text('Riwayat'));
      await tester.pumpAndSettle();
      expect(find.text('missing'), findsOneWidget);
      expect(find.text('Tidak ada transaksi yang sesuai'), findsOneWidget);
      await tester.ensureVisible(find.byTooltip('Filter metode'));
      await tester.tap(find.byTooltip('Filter metode'));
      await tester.pumpAndSettle();
      expect(find.text('Transfer Bank'), findsNothing);
    },
  );

  testWidgets(
    'Daily report shows empty data and fits narrow screens with large text',
    (tester) async {
      TransactionHistory.instance.replace([]);
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await tester.pumpWidget(const MaterialApp(home: TransactionsScreen()));
      await tester.ensureVisible(find.text('Laporan Transaksi'));
      await tester.tap(find.text('Laporan Transaksi'));
      await tester.pumpAndSettle();
      expect(find.text('Belum ada penjualan hari ini'), findsOneWidget);
      expect(
        tester.widget<Text>(find.byKey(const ValueKey('daily-revenue'))).data,
        'Rp0',
      );
      expect(tester.takeException(), isNull);
      tester.view.physicalSize = const Size(640, 320);
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Belum ada penjualan hari ini'));
      expect(tester.takeException(), isNull);
    },
  );

  test(
    'History starts empty',
    () => expect(TransactionHistory().items, isEmpty),
  );
  test('Receipt export creates a PDF from the saved snapshot', () async {
    final sale = SaleTransaction(
      id: 'receipt-1',
      date: DateTime(2026, 10, 1),
      method: 'Tunai',
      items: [
        const TransactionItem(
          'Produk Uji',
          10000,
          2,
          productId: 'p',
          cost: 5000,
        ),
      ],
    );
    final bytes = await receiptPdf(sale, 'Toko Uji');
    expect(String.fromCharCodes(bytes.take(4)), '%PDF');
    expect(bytes.length, greaterThan(100));
  });
  testWidgets('History shows loaded records and filters by ID', (tester) async {
    TransactionHistory.instance.replace([
      SaleTransaction(
        id: 'saved-1',
        date: DateTime.now(),
        method: 'Tunai',
        items: [const TransactionItem('Produk Uji', 10000, 1)],
      ),
    ]);
    addTearDown(() => TransactionHistory.instance.replace([]));
    await tester.pumpWidget(const MaterialApp(home: TransactionsScreen()));
    expect(find.text('#saved-1'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'missing');
    await tester.pumpAndSettle();
    expect(find.text('Tidak ada transaksi yang sesuai'), findsOneWidget);
  });
}
