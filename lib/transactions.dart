import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'firebase_store.dart';

// Snapshot pesanan menjaga riwayat tetap sama meskipun produk kemudian diedit.
class TransactionItem {
  const TransactionItem(
    this.name,
    this.price,
    this.quantity, {
    this.productId = '',
    this.cost = 0,
  });
  final String productId;
  final int cost;
  final String name;
  final int price;
  final int quantity;
  int get subtotal => price * quantity;
}

// Nominal transaksi dihitung dari snapshot pesanan, bukan katalog produk terbaru.
class SaleTransaction {
  SaleTransaction({
    required this.id,
    required this.date,
    required this.method,
    required List<TransactionItem> items,
    this.discount = 0,
    this.points = 0,
  }) : items = List.unmodifiable(items);
  final String id;
  final DateTime date;
  final String method;
  final List<TransactionItem> items;
  final int discount;
  int get subtotal => items.fold(0, (amount, item) => amount + item.subtotal);
  int get total => subtotal - discount;
  int get quantity => items.fold(0, (amount, item) => amount + item.quantity);
  final int points;
  int get cost =>
      items.fold(0, (amount, item) => amount + item.cost * item.quantity);
  factory SaleTransaction.fromDocument(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data()!;
    return SaleTransaction(
      id: doc.id,
      date: (data['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      method: data['method'] as String,
      discount: (data['discount'] as num?)?.toInt() ?? 0,
      points: (data['points'] as num?)?.toInt() ?? 0,
      items: (data['items'] as List)
          .map(
            (item) => TransactionItem(
              item['name'] as String,
              (item['price'] as num).toInt(),
              (item['quantity'] as num).toInt(),
              productId: item['productId'] as String,
              cost: (item['cost'] as num).toInt(),
            ),
          )
          .toList(),
    );
  }
}

class TransactionHistory extends ChangeNotifier {
  TransactionHistory({this._account});
  final DocumentReference<Map<String, dynamic>>? _account;
  static final instance = TransactionHistory();
  final List<SaleTransaction> _items = [];
  List<SaleTransaction> get items =>
      List.unmodifiable([..._items]..sort((a, b) => b.date.compareTo(a.date)));
  void replace(List<SaleTransaction> items) {
    _items
      ..clear()
      ..addAll(items);
    notifyListeners();
  }

  Future<SaleTransaction> checkout({
    required String id,
    required List<TransactionItem> items,
    required int cash,
    String method = 'Tunai',
  }) async {
    if (!['Tunai', 'QRIS'].contains(method)) {
      throw StateError('Metode pembayaran tidak didukung.');
    }
    if (cash < 0 || (method == 'QRIS' && cash != 0)) {
      throw StateError(
        'Nominal tunai tidak valid untuk metode pembayaran ini.',
      );
    }
    if (items.isEmpty ||
        items.length > 100 ||
        items.any((item) => item.quantity <= 0 || item.productId.isEmpty) ||
        items.map((e) => e.productId).toSet().length != items.length) {
      throw StateError('Keranjang tidak valid.');
    }
    final account = _account ?? accountRef;
    final ref = account.collection('transactions').doc(id);
    await account.firestore.runTransaction((transaction) async {
      final existing = await transaction.get(ref);
      if (existing.exists) {
        final saved = SaleTransaction.fromDocument(existing);
        if (saved.method != method ||
            saved.items.length != items.length ||
            saved.items.any(
              (savedItem) => !items.any(
                (item) =>
                    item.productId == savedItem.productId &&
                    item.price == savedItem.price &&
                    item.quantity == savedItem.quantity,
              ),
            )) {
          throw StateError(
            'Pembayaran sebelumnya sudah tercatat dengan keranjang atau metode berbeda. Periksa riwayat lalu buka kasir kembali.',
          );
        }
        return; // Retrying the same payment never reduces stock twice.
      }
      final profile = await transaction.get(account);
      if ((profile.data()?['paymentMethods'] as Map?)?[method] == false) {
        throw StateError('Pembayaran $method dinonaktifkan.');
      }
      final snapshots = <DocumentSnapshot<Map<String, dynamic>>>[];
      for (final item in items) {
        snapshots.add(
          await transaction.get(
            account.collection('products').doc(item.productId),
          ),
        );
      }
      final lines = <Map<String, dynamic>>[];
      var total = 0;
      for (var index = 0; index < items.length; index++) {
        final item = items[index];
        final product = snapshots[index].data();
        if (product == null || product['active'] != true) {
          throw StateError('Produk tidak lagi tersedia.');
        }
        if (product['price'] != item.price) {
          throw StateError('Harga berubah. Buat ulang keranjang.');
        }
        final stock = (product['stock'] as num).toInt();
        if (stock < item.quantity) {
          throw StateError('Stok ${item.name} tidak mencukupi.');
        }
        total += item.price * item.quantity;
        lines.add({
          'productId': item.productId,
          'name': product['name'],
          'price': product['price'],
          'cost': product['cost'],
          'quantity': item.quantity,
        });
      }
      if (method == 'Tunai' && cash < total) {
        throw StateError('Nominal tunai belum mencukupi.');
      }
      for (var index = 0; index < items.length; index++) {
        final item = items[index];
        transaction.update(snapshots[index].reference, {
          'stock':
              (snapshots[index].data()!['stock'] as num).toInt() -
              item.quantity,
          'sold': FieldValue.increment(item.quantity),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
      transaction.set(ref, {
        'date': FieldValue.serverTimestamp(),
        'method': method,
        'items': lines,
        'discount': 0,
        'points': 0,
        'total': total,
        'cash': cash,
      });
    });
    final sale = SaleTransaction.fromDocument(
      await ref.get(const GetOptions(source: Source.server)),
    );
    if (_account == null &&
        FirebaseAuth.instance.currentUser?.uid != account.id) {
      return sale;
    }
    _items.removeWhere((item) => item.id == sale.id);
    _items.add(sale);
    notifyListeners();
    return sale;
  }
}

// Format tanggal Indonesia tanpa dependensi tambahan.
String transactionDate(DateTime date) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'Mei',
    'Jun',
    'Jul',
    'Agu',
    'Sep',
    'Okt',
    'Nov',
    'Des',
  ];
  return '${date.day} ${months[date.month - 1]} ${date.year}';
}

String transactionTime(DateTime date) =>
    '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
