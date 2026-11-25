import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nalara/products.dart';

void main() {
  test('Catalog starts empty and writes to the account collection', () async {
    final db = FakeFirebaseFirestore();
    final account = db.collection('users').doc('owner');
    final catalog = ProductCatalog(account: account);
    expect(catalog.items, isEmpty);
    await catalog.save(
      Product(
        id: 'p1',
        name: 'Produk Uji',
        price: 10000,
        cost: 4000,
        stock: 3,
        minimumStock: 1,
      ),
    );
    final snapshot = await account.collection('products').doc('p1').get();
    final saved = Product.fromDocument(snapshot);
    expect(saved.name, 'Produk Uji');
    expect(saved.stock, 3);
    expect(
      (await db.collection('users').doc('other').collection('products').get())
          .docs,
      isEmpty,
    );
    await catalog.addStock('p1', 2);
    expect((await snapshot.reference.get()).data()!['stock'], 5);
    expect(
      (await account.collection('stockMovements').get()).docs.single
          .data()['quantity'],
      2,
    );
  });
  test('Invalid products and stock increments are rejected', () async {
    final account = FakeFirebaseFirestore().collection('users').doc('owner');
    final catalog = ProductCatalog(account: account);
    await expectLater(
      catalog.save(
        Product(
          id: 'bad',
          name: '',
          price: 0,
          cost: -1,
          stock: -1,
          minimumStock: 0,
        ),
      ),
      throwsStateError,
    );
    await expectLater(catalog.addStock('missing', 0), throwsStateError);
    expect((await account.collection('products').get()).docs, isEmpty);
  });
  test('Stale product edits cannot overwrite newer stock', () async {
    final account = FakeFirebaseFirestore().collection('users').doc('owner');
    final catalog = ProductCatalog(account: account);
    await catalog.save(
      Product(
        id: 'p',
        name: 'Produk',
        price: 10,
        cost: 4,
        stock: 5,
        minimumStock: 1,
      ),
    );
    final old = Product.fromDocument(
      await account.collection('products').doc('p').get(),
    );
    await Future<void>.delayed(const Duration(milliseconds: 2));
    await catalog.addStock('p', 2);
    await expectLater(
      catalog.save(old.withStock(20), previous: old),
      throwsStateError,
    );
    expect(
      (await account.collection('products').doc('p').get()).data()!['stock'],
      7,
    );
  });
}
