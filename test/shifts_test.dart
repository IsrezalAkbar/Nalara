import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nalara/screens/shifts_screen.dart';
import 'package:nalara/session.dart';
import 'package:nalara/shifts.dart';
import 'package:nalara/transactions.dart';

void main() {
  test('Shift spans midnight, includes start, excludes end, and separates QRIS from cash', () {
    final start = DateTime(2026, 11, 10, 22);
    final end = DateTime(2026, 11, 11, 6);
    final shift = CashierShift(
      id: 's',
      cashier: 'Kasir',
      startedAt: start,
      endedAt: end,
      openingCash: 100000,
      countedCash: 125000,
    );
    SaleTransaction sale(String id, DateTime date, String method, int price) =>
        SaleTransaction(
          id: id,
          date: date,
          method: method,
          items: [TransactionItem('Produk', price, 1)],
          discount: 1000,
        );
    final summary = ShiftSummary(shift, [
      sale(
        'before',
        start.subtract(const Duration(microseconds: 1)),
        'Tunai',
        900000,
      ),
      sale('start', start, 'Tunai', 21000),
      sale(
        'late',
        end.subtract(const Duration(microseconds: 1)),
        'QRIS',
        31000,
      ),
      sale('after', end, 'Tunai', 900000),
    ]);
    expect(summary.sales.length, 2);
    expect(summary.cashSales, 20000);
    expect(summary.qrisSales, 30000);
    expect(summary.revenue, 50000);
    expect(summary.expectedCash, 120000);
    expect(summary.difference, 5000);
    final empty = ShiftSummary(
      CashierShift(
        id: 'e',
        cashier: 'Kasir',
        startedAt: start,
        openingCash: 100000,
        countedCash: 90000,
        endedAt: end,
      ),
      [],
    );
    expect(empty.difference, -10000);
  });

  test('Shifts persist, prevent double starts and repeated closes, and allow the next shift', () async {
    final account = FakeFirebaseFirestore().collection('users').doc('owner');
    final repository = ShiftRepository(account: account);
    await expectLater(
      repository.start(cashier: '', openingCash: 0),
      throwsStateError,
    );
    await expectLater(
      repository.start(cashier: 'A', openingCash: -1),
      throwsStateError,
    );
    await repository.start(cashier: ' Petugas A ', openingCash: 100000);
    final active = (await repository.watch().first).single;
    expect(active.active, isTrue);
    expect(active.cashier, 'Petugas A');
    await expectLater(
      repository.start(cashier: 'B', openingCash: 0),
      throwsStateError,
    );
    await expectLater(
      repository.close(id: active.id, countedCash: -1),
      throwsStateError,
    );
    await expectLater(
      repository.close(id: 'other', countedCash: 0),
      throwsStateError,
    );
    await repository.close(
      id: active.id,
      countedCash: 120000,
      note: ' Selesai ',
    );
    final closed = (await ShiftRepository(
      account: account,
    ).watch().first).single;
    expect(closed.active, isFalse);
    expect(closed.openingCash, 100000);
    expect(closed.countedCash, 120000);
    expect(closed.note, 'Selesai');
    await expectLater(
      repository.close(id: active.id, countedCash: 0),
      throwsStateError,
    );
    await repository.start(cashier: 'B', openingCash: 0);
    final shifts = await repository.watch().first;
    expect(shifts.length, 2);
    expect(shifts.where((shift) => shift.active).length, 1);
    expect(
      await ShiftRepository(account: account.parent.doc('other')).watch().first,
      isEmpty,
    );
  });

  testWidgets(
    'Start and close forms validate, show difference, and restore history',
    (tester) async {
      final account = FakeFirebaseFirestore().collection('users').doc('owner');
      final repository = ShiftRepository(account: account);
      StoreSession.instance.profile = {'name': 'Petugas Uji'};
      TransactionHistory.instance.replace([]);
      addTearDown(() {
        StoreSession.instance.profile = {};
        TransactionHistory.instance.replace([]);
      });
      await tester.pumpWidget(
        MaterialApp(home: ShiftsScreen(repository: repository)),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Mulai Shift'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Mulai'));
      await tester.pumpAndSettle();
      expect(
        find.text('Masukkan nominal rupiah, isi 0 jika tidak ada.'),
        findsOneWidget,
      );
      await tester.ensureVisible(find.text('Rp100.000'));
      await tester.tap(find.text('Rp100.000'));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<TextFormField>(find.byType(TextFormField).at(1))
            .controller!
            .text,
        '100.000',
      );
      await tester.tap(find.text('Mulai'));
      await tester.pumpAndSettle();
      expect(find.text('SHIFT AKTIF'), findsOneWidget);
      final active = (await repository.watch().first).single;
      expect(active.openingCash, 100000);
      TransactionHistory.instance.replace([
        SaleTransaction(
          id: 'sale',
          date: active.startedAt,
          method: 'Tunai',
          items: [const TransactionItem('Kopi', 10000, 2)],
        ),
        SaleTransaction(
          id: 'qris',
          date: active.startedAt,
          method: 'QRIS',
          items: [const TransactionItem('Kue', 30000, 1)],
        ),
      ]);
      await tester.pumpAndSettle();
      expect(find.text('Rp120.000'), findsOneWidget);
      await tester.pump(const Duration(seconds: 4));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Tutup Shift'),
        150,
        scrollable: find
            .descendant(
              of: find.byType(ListView).first,
              matching: find.byType(Scrollable),
            )
            .first,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Tutup Shift'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField).first, '115000');
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<TextFormField>(find.byType(TextFormField).first)
            .controller!
            .text,
        '115.000',
      );
      expect(find.text('Kurang Rp5.000'), findsOneWidget);
      await tester.enterText(
        find.byType(TextFormField).last,
        'Selisih dicatat',
      );
      await tester.tap(find.text('Simpan & Tutup'));
      await tester.pumpAndSettle();
      expect((await repository.watch().first).single.countedCash, 115000);
      expect(find.text('SHIFT AKTIF'), findsNothing);
      await tester.scrollUntilVisible(
        find.text('SELESAI'),
        180,
        scrollable: find
            .descendant(
              of: find.byType(ListView).last,
              matching: find.byType(Scrollable),
            )
            .first,
      );
      await tester.pumpAndSettle();
      expect(find.text('SELESAI'), findsOneWidget);
      expect(find.text('Catatan: Selisih dicatat'), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpWidget(
        MaterialApp(
          home: ShiftsScreen(repository: ShiftRepository(account: account)),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Riwayat Shift'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('SELESAI'),
        180,
        scrollable: find
            .descendant(
              of: find.byType(ListView).last,
              matching: find.byType(Scrollable),
            )
            .first,
      );
      await tester.pumpAndSettle();
      expect(find.text('SELESAI'), findsOneWidget);
      expect(find.text('Petugas Uji'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'History defaults to today, filters dates, and logs overnight events on their own dates',
    (tester) async {
      final account = FakeFirebaseFirestore()
          .collection('users')
          .doc('history');
      final today = DateUtils.dateOnly(DateTime.now());
      final yesterday = DateTime(today.year, today.month, today.day - 1);
      Future<void> seed(
        String id,
        String cashier,
        DateTime start,
        DateTime? end,
      ) => account.collection('shifts').doc(id).set({
        'cashier': cashier,
        'startedAt': Timestamp.fromDate(start),
        'endedAt': end == null ? null : Timestamp.fromDate(end),
        'openingCash': 100000,
        'countedCash': end == null ? null : 100000,
        'note': '',
      });
      await seed(
        'old',
        'Petugas kemarin',
        yesterday,
        yesterday.add(const Duration(hours: 8)),
      );
      await seed(
        'night',
        'Petugas malam',
        yesterday.add(const Duration(hours: 22)),
        today.add(const Duration(hours: 1)),
      );
      await seed(
        'active',
        'Petugas aktif',
        today.add(const Duration(hours: 2)),
        null,
      );
      SaleTransaction sale(
        String id,
        DateTime date,
        String method,
        int price,
      ) => SaleTransaction(
        id: id,
        date: date,
        method: method,
        items: [TransactionItem('Produk', price, 1)],
      );
      TransactionHistory.instance.replace([
        sale(
          'old-sale',
          yesterday.add(const Duration(hours: 2)),
          'Tunai',
          15000,
        ),
        sale(
          'night-cash',
          yesterday.add(const Duration(hours: 23)),
          'Tunai',
          20000,
        ),
        sale(
          'night-qris',
          today.add(const Duration(minutes: 30)),
          'QRIS',
          30000,
        ),
        sale('active-sale', today.add(const Duration(hours: 3)), 'Tunai', 8000),
      ]);
      addTearDown(() => TransactionHistory.instance.replace([]));
      tester.view.physicalSize = const Size(900, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          home: ShiftsScreen(repository: ShiftRepository(account: account)),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Petugas aktif'), findsOneWidget);
      expect(find.text('Petugas malam'), findsNothing);
      await tester.tap(find.text('Riwayat Shift'));
      await tester.pumpAndSettle();
      expect(find.text('Hari ini • ${transactionDate(today)}'), findsOneWidget);
      expect(find.text('Petugas malam'), findsOneWidget);
      expect(find.text('Petugas kemarin'), findsNothing);
      expect(
        tester
            .widget<Text>(find.byKey(const ValueKey('history-total-revenue')))
            .data,
        'Rp50.000',
      );
      expect(find.text('2 transaksi'), findsOneWidget);
      expect(find.text('1 shift berselisih'), findsOneWidget);
      expect(find.text('Shift dimulai'), findsOneWidget);
      expect(find.text('Shift ditutup'), findsOneWidget);
      expect(
        tester
            .widget<IconButton>(
              find.byWidgetPredicate(
                (widget) =>
                    widget is IconButton && widget.tooltip == 'Hari berikutnya',
              ),
            )
            .onPressed,
        isNull,
      );

      await tester.tap(find.byTooltip('Hari sebelumnya'));
      await tester.pumpAndSettle();
      expect(find.text(transactionDate(yesterday)), findsOneWidget);
      expect(find.text('Petugas kemarin'), findsOneWidget);
      expect(find.text('Petugas malam'), findsNothing);
      expect(
        tester
            .widget<Text>(find.byKey(const ValueKey('history-total-revenue')))
            .data,
        'Rp15.000',
      );
      expect(find.text('Shift dimulai'), findsNWidgets(2));
      expect(find.text('Shift ditutup'), findsOneWidget);

      // The date remains selected when moving between the two tabs.
      await tester.tap(find.text('Shift Aktif'));
      await tester.pumpAndSettle();
      expect(find.text('Petugas aktif'), findsOneWidget);
      await tester.tap(find.text('Riwayat Shift'));
      await tester.pumpAndSettle();
      expect(find.text(transactionDate(yesterday)), findsOneWidget);
      await tester.tap(find.text('Pilih Tanggal'));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.edit_outlined));
      await tester.pumpAndSettle();
      final field = find.byType(TextField);
      final emptyDate = DateTime(today.year, today.month, today.day - 4);
      final localization = MaterialLocalizations.of(tester.element(field));
      await tester.enterText(field, localization.formatCompactDate(emptyDate));
      await tester.tap(find.text('Terapkan'));
      await tester.pumpAndSettle();
      expect(
        find.text('Belum ada shift yang ditutup pada tanggal ini.'),
        findsOneWidget,
      );
      expect(
        find.text('Tidak ada aktivitas shift pada tanggal ini.'),
        findsOneWidget,
      );
      await tester.tap(find.text('Hari Ini'));
      await tester.pumpAndSettle();
      expect(find.text('Petugas malam'), findsOneWidget);
      expect(find.text('Hari ini • ${transactionDate(today)}'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Shift forms fit narrow and landscape screens with enlarged text',
    (tester) async {
      final repository = ShiftRepository(
        account: FakeFirebaseFirestore().collection('users').doc('owner'),
      );
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      for (final size in [const Size(360, 800), const Size(640, 320)]) {
        tester.view.physicalSize = size;
        await tester.pumpWidget(
          MaterialApp(
            key: ValueKey(size),
            home: ShiftsScreen(repository: repository),
          ),
        );
        await tester.pumpAndSettle();
        await tester.scrollUntilVisible(
          find.text('Mulai Shift'),
          200,
          scrollable: find
              .descendant(
                of: find.byType(ListView).first,
                matching: find.byType(Scrollable),
              )
              .first,
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('Mulai Shift'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await tester.ensureVisible(find.text('Batal'));
        await tester.tap(find.text('Batal'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await tester.tap(find.text('Riwayat Shift'));
        await tester.pumpAndSettle();
        await tester.scrollUntilVisible(
          find.text('Pilih Tanggal'),
          150,
          scrollable: find
              .descendant(
                of: find.byType(ListView).last,
                matching: find.byType(Scrollable),
              )
              .first,
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('Pilih Tanggal'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await tester.tap(find.text('Batal'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }
    },
  );
}
