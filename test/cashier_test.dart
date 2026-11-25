import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nalara/products.dart';
import 'package:nalara/transactions.dart';
import 'package:nalara/screens/cashier_screen.dart';

void main() {
  test('Manual QRIS stores its method, decrements stock once, and rejects method changes on retry', () async {
    final account = FakeFirebaseFirestore().collection('users').doc('owner');
    await account.set({
      'paymentMethods': {'Tunai': true},
    });
    await ProductCatalog(account: account).save(
      Product(
        id: 'p',
        name: 'Produk',
        price: 10000,
        cost: 4000,
        stock: 5,
        minimumStock: 1,
      ),
    );
    final history = TransactionHistory(account: account);
    const items = [TransactionItem('Produk', 10000, 2, productId: 'p')];
    final sale = await history.checkout(
      id: 'qris-1',
      items: items,
      cash: 0,
      method: 'QRIS',
    );
    expect(sale.method, 'QRIS');
    expect(sale.total, 20000);
    expect(sale.cost, 8000);
    final saved = (await account.collection('transactions').doc('qris-1').get())
        .data()!;
    expect(saved['method'], 'QRIS');
    expect(saved['cash'], 0);
    await history.checkout(id: 'qris-1', items: items, cash: 0, method: 'QRIS');
    await expectLater(
      history.checkout(
        id: 'qris-1',
        items: items,
        cash: 20000,
        method: 'Tunai',
      ),
      throwsStateError,
    );
    expect((await account.collection('transactions').get()).docs, hasLength(1));
    final product = (await account.collection('products').doc('p').get())
        .data()!;
    expect(product['stock'], 3);
    expect(product['sold'], 2);
  });

  test('Disabled and unsupported methods and QRIS cash are rejected without stock changes', () async {
    final account = FakeFirebaseFirestore().collection('users').doc('owner');
    await account.set({
      'paymentMethods': {'Tunai': false, 'QRIS': false},
    });
    await ProductCatalog(account: account).save(
      Product(
        id: 'p',
        name: 'Produk',
        price: 100,
        cost: 40,
        stock: 5,
        minimumStock: 1,
      ),
    );
    final history = TransactionHistory(account: account);
    const items = [TransactionItem('Produk', 100, 1, productId: 'p')];
    for (final method in ['Tunai', 'QRIS', 'Transfer Bank']) {
      await expectLater(
        history.checkout(
          id: method,
          items: items,
          cash: method == 'QRIS' ? 0 : 100,
          method: method,
        ),
        throwsStateError,
      );
    }
    await expectLater(
      history.checkout(
        id: 'invalid-cash',
        items: items,
        cash: 100,
        method: 'QRIS',
      ),
      throwsStateError,
    );
    expect((await account.collection('transactions').get()).docs, isEmpty);
    expect(
      (await account.collection('products').doc('p').get()).data()!['stock'],
      5,
    );
  });

  test('Checkout snapshots cost, reduces stock, and is idempotent', () async {
    final account = FakeFirebaseFirestore().collection('users').doc('owner');
    await ProductCatalog(account: account).save(
      Product(
        id: 'p',
        name: 'Produk',
        price: 10000,
        cost: 4000,
        stock: 5,
        minimumStock: 1,
      ),
    );
    final history = TransactionHistory(account: account);
    const items = [TransactionItem('Produk', 10000, 2, productId: 'p')];
    final sale = await history.checkout(
      id: 'payment-1',
      items: items,
      cash: 25000,
    );
    expect(sale.total, 20000);
    expect(sale.cost, 8000);
    expect(sale.points, 0);
    await history.checkout(id: 'payment-1', items: items, cash: 25000);
    final product = (await account.collection('products').doc('p').get())
        .data()!;
    expect(product['stock'], 3);
    expect(product['sold'], 2);
    expect((await account.collection('transactions').get()).docs, hasLength(1));
    await account.collection('products').doc('p').update({'cost': 8000});
    expect(sale.cost, 8000);
  });
  test('Checkout rejects insufficient stock, changed prices, and insufficient cash', () async {
    final account = FakeFirebaseFirestore().collection('users').doc('owner');
    await ProductCatalog(account: account).save(
      Product(
        id: 'p',
        name: 'Produk',
        price: 100,
        cost: 40,
        stock: 1,
        minimumStock: 0,
      ),
    );
    final history = TransactionHistory(account: account);
    for (final items in [
      [const TransactionItem('Produk', 100, 2, productId: 'p')],
      [const TransactionItem('Produk', 90, 1, productId: 'p')],
    ]) {
      await expectLater(
        history.checkout(id: 'failure', items: items, cash: 300),
        throwsStateError,
      );
    }
    await expectLater(
      history.checkout(
        id: 'failure',
        items: [const TransactionItem('Produk', 100, 1, productId: 'p')],
        cash: 50,
      ),
      throwsStateError,
    );
    expect((await account.collection('transactions').get()).docs, isEmpty);
    expect(
      (await account.collection('products').doc('p').get()).data()!['stock'],
      1,
    );
  });
  testWidgets('Empty cashier does not offer a payment', (tester) async {
    ProductCatalog.instance.replace([]);
    await tester.pumpWidget(const MaterialApp(home: CashierScreen()));
    expect(find.text('Es Kopi Susu'), findsNothing);
    final button = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Lanjutkan'),
    );
    expect(button.onPressed, isNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Cashier preserves selections through filters and respects stock',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(() => ProductCatalog.instance.replace([]));
      ProductCatalog.instance.replace([
        Product(
          id: 'coffee',
          name: 'Kopi',
          price: 15000,
          cost: 7000,
          stock: 1,
          minimumStock: 0,
          category: 'Minuman',
        ),
        Product(
          id: 'cake',
          name: 'Kue',
          price: 10000,
          cost: 5000,
          stock: 0,
          minimumStock: 1,
          category: 'Makanan',
        ),
      ]);
      await tester.pumpWidget(const MaterialApp(home: CashierScreen()));
      final soldOut = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Habis'),
      );
      expect(soldOut.onPressed, isNull);
      await tester.tap(find.widgetWithText(FilledButton, 'Tambah'));
      await tester.pump();
      expect(
        tester
            .widget<IconButton>(
              find.widgetWithIcon(IconButton, Icons.add_rounded),
            )
            .onPressed,
        isNull,
      );
      expect(find.text('Rp15.000'), findsNWidgets(2));

      await tester.tap(find.widgetWithText(ChoiceChip, 'Makanan'));
      await tester.pump();
      expect(find.text('Kopi'), findsNothing);
      expect(find.text('Rp15.000'), findsOneWidget);
      await tester.tap(find.widgetWithText(ChoiceChip, 'Semua'));
      await tester.pump();
      expect(find.byTooltip('Kurangi Kopi'), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'tidak ada');
      await tester.pump();
      expect(find.text('Produk tidak ditemukan'), findsOneWidget);
      expect(find.text('Rp15.000'), findsOneWidget);
      await tester.tap(find.byTooltip('Hapus pencarian'));
      await tester.pump();
      await tester.tap(find.widgetWithText(FilledButton, 'Lanjutkan'));
      await tester.pumpAndSettle();
      expect(find.text('Keranjang'), findsOneWidget);
      expect(find.text('Kopi'), findsOneWidget);
      expect(find.text('Kue'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Catalog stock updates reduce selected quantities', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(() => ProductCatalog.instance.replace([]));
    final product = Product(
      id: 'coffee',
      name: 'Kopi',
      price: 15000,
      cost: 7000,
      stock: 3,
      minimumStock: 0,
    );
    ProductCatalog.instance.replace([product]);
    await tester.pumpWidget(const MaterialApp(home: CashierScreen()));
    await tester.tap(find.widgetWithText(FilledButton, 'Tambah'));
    await tester.pump();
    await tester.tap(find.byTooltip('Tambah Kopi'));
    await tester.pump();
    expect(find.text('Rp30.000'), findsOneWidget);
    ProductCatalog.instance.replace([product.withStock(1)]);
    await tester.pump();
    expect(find.text('Rp30.000'), findsNothing);
    expect(find.text('Rp15.000'), findsNWidgets(2));
    expect(
      tester
          .widget<IconButton>(
            find.widgetWithIcon(IconButton, Icons.add_rounded),
          )
          .onPressed,
      isNull,
    );
    ProductCatalog.instance.replace([product.withStock(0)]);
    await tester.pump();
    expect(find.text('Rp0'), findsOneWidget);
    expect(
      tester
          .widget<FilledButton>(find.widgetWithText(FilledButton, 'Lanjutkan'))
          .onPressed,
      isNull,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Cash payment presets, manual amounts and exact cash validate the payment',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(() => ProductCatalog.instance.replace([]));
      ProductCatalog.instance.replace([
        Product(
          id: 'coffee',
          name: 'Kopi',
          price: 15000,
          cost: 7000,
          stock: 5,
          minimumStock: 0,
        ),
      ]);
      await tester.pumpWidget(const MaterialApp(home: CashierScreen()));
      await tester.tap(find.widgetWithText(FilledButton, 'Tambah'));
      await tester.pump();
      await tester.tap(find.widgetWithText(FilledButton, 'Lanjutkan'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Lanjut Pembayaran'));
      await tester.pumpAndSettle();
      final pay = find.byKey(const ValueKey('pay-cash'));
      final field = find.byKey(const ValueKey('cash-received'));
      expect(tester.widget<FilledButton>(pay).onPressed, isNull);
      expect(
        tester
            .widget<InkWell>(find.byKey(const ValueKey('payment-method-QRIS')))
            .onTap,
        isNotNull,
      );
      expect(find.text('Transfer Bank'), findsNothing);
      expect(find.byType(BottomNavigationBar), findsOneWidget);

      for (final amount in [1000, 2000, 5000, 10000, 20000, 50000, 100000]) {
        final preset = find.byKey(ValueKey('cash-$amount'));
        await tester.ensureVisible(preset);
        await tester.tap(preset);
        await tester.pumpAndSettle();
        expect(
          tester.widget<TextField>(field).controller!.text,
          productRupiah(amount).substring(2),
        );
        expect(
          tester.widget<FilledButton>(pay).onPressed != null,
          amount >= 15000,
        );
        expect(
          tester
              .widget<Text>(find.byKey(const ValueKey('cash-difference')))
              .data,
          productRupiah((amount - 15000).abs()),
        );
      }

      await tester.ensureVisible(field);
      await tester.enterText(field, '25000');
      await tester.pump();
      expect(tester.widget<TextField>(field).controller!.text, '25.000');
      expect(
        tester.widget<Text>(find.byKey(const ValueKey('cash-difference'))).data,
        'Rp10.000',
      );
      expect(tester.widget<FilledButton>(pay).onPressed, isNotNull);
      final exact = find.widgetWithText(TextButton, 'Uang Pas');
      await tester.ensureVisible(exact);
      await tester.tap(exact);
      await tester.pumpAndSettle();
      expect(tester.widget<TextField>(field).controller!.text, '15.000');
      expect(
        tester.widget<Text>(find.byKey(const ValueKey('cash-difference'))).data,
        'Rp0',
      );
      expect(tester.widget<FilledButton>(pay).onPressed, isNotNull);
      await tester.ensureVisible(field);
      await tester.enterText(field, '');
      await tester.pump();
      expect(tester.widget<FilledButton>(pay).onPressed, isNull);

      final qris = find.byKey(const ValueKey('payment-method-QRIS'));
      await tester.ensureVisible(qris);
      await tester.tap(qris);
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('cash-received')), findsNothing);
      final payQris = find.byKey(const ValueKey('pay-qris'));
      expect(tester.widget<FilledButton>(payQris).onPressed, isNull);
      final confirm = find.byKey(const ValueKey('qris-confirmed'));
      await tester.ensureVisible(confirm);
      await tester.tap(confirm);
      await tester.pumpAndSettle();
      expect(tester.widget<FilledButton>(payQris).onPressed, isNotNull);
      await tester.ensureVisible(
        find.byKey(const ValueKey('payment-method-Tunai')),
      );
      await tester.tap(find.byKey(const ValueKey('payment-method-Tunai')));
      await tester.pumpAndSettle();
      expect(tester.widget<FilledButton>(pay).onPressed, isNull);
      await tester.ensureVisible(qris);
      await tester.tap(qris);
      await tester.pumpAndSettle();
      expect(tester.widget<CheckboxListTile>(confirm).value, false);

      tester.view.physicalSize = const Size(640, 320);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );
}
