import 'package:cloud_firestore/cloud_firestore.dart';

import 'firebase_store.dart';
import 'transactions.dart';

class CashierShift {
  const CashierShift({
    required this.id,
    required this.cashier,
    required this.startedAt,
    required this.openingCash,
    this.endedAt,
    this.countedCash,
    this.note = '',
  });

  final String id, cashier, note;
  final DateTime startedAt;
  final DateTime? endedAt;
  final int openingCash;
  final int? countedCash;
  bool get active => endedAt == null;

  factory CashierShift.fromDocument(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data()!;
    return CashierShift(
      id: doc.id,
      cashier: data['cashier'] as String,
      startedAt: (data['startedAt'] as Timestamp).toDate(),
      endedAt: (data['endedAt'] as Timestamp?)?.toDate(),
      openingCash: (data['openingCash'] as num).toInt(),
      countedCash: (data['countedCash'] as num?)?.toInt(),
      note: data['note'] as String? ?? '',
    );
  }
}

class ShiftSummary {
  ShiftSummary(this.shift, Iterable<SaleTransaction> history)
    : sales = history
          .where(
            (sale) =>
                !sale.date.isBefore(shift.startedAt) &&
                (shift.endedAt == null || sale.date.isBefore(shift.endedAt!)),
          )
          .toList();

  final CashierShift shift;
  final List<SaleTransaction> sales;
  int get cashSales => _total('Tunai');
  int get qrisSales => _total('QRIS');
  int _total(String method) => sales
      .where((sale) => sale.method == method)
      .fold(0, (amount, sale) => amount + sale.total);
  int get revenue => sales.fold(0, (amount, sale) => amount + sale.total);
  int get expectedCash => shift.openingCash + cashSales;
  int? get difference =>
      shift.countedCash == null ? null : shift.countedCash! - expectedCash;
}

class ShiftRepository {
  ShiftRepository({this._account});
  final DocumentReference<Map<String, dynamic>>? _account;
  DocumentReference<Map<String, dynamic>> get account => _account ?? accountRef;

  Stream<List<CashierShift>> watch() => account
      .collection('shifts')
      .orderBy('startedAt', descending: true)
      .snapshots()
      .map(
        (snapshot) => snapshot.docs
            .where(
              (doc) =>
                  !doc.metadata.hasPendingWrites &&
                  doc.data()['startedAt'] is Timestamp,
            )
            .map(CashierShift.fromDocument)
            .toList(),
      );

  Future<void> start({
    required String cashier,
    required int openingCash,
  }) async {
    if (cashier.trim().isEmpty ||
        cashier.trim().length > 100 ||
        openingCash < 0) {
      throw StateError('Nama petugas dan modal awal tidak valid.');
    }
    final owner = account;
    final state = owner.collection('shiftState').doc('current');
    final shift = owner.collection('shifts').doc();
    await owner.firestore.runTransaction((transaction) async {
      final current = await transaction.get(state);
      if (current.data()?['activeShiftId'] != null) {
        throw StateError(
          'Masih ada shift aktif. Tutup shift tersebut terlebih dahulu.',
        );
      }
      transaction.set(shift, {
        'cashier': cashier.trim(),
        'openingCash': openingCash,
        'startedAt': FieldValue.serverTimestamp(),
        'endedAt': null,
        'countedCash': null,
        'note': '',
      });
      transaction.set(state, {'activeShiftId': shift.id});
    });
  }

  Future<void> close({
    required String id,
    required int countedCash,
    String note = '',
  }) async {
    if (countedCash < 0 || note.trim().length > 1000) {
      throw StateError('Uang tunai aktual atau catatan tidak valid.');
    }
    final owner = account;
    final state = owner.collection('shiftState').doc('current');
    final shift = owner.collection('shifts').doc(id);
    await owner.firestore.runTransaction((transaction) async {
      final current = await transaction.get(state);
      final saved = await transaction.get(shift);
      if (current.data()?['activeShiftId'] != id ||
          !saved.exists ||
          saved.data()?['endedAt'] != null) {
        throw StateError('Shift ini sudah ditutup atau tidak lagi aktif.');
      }
      transaction.update(shift, {
        'endedAt': FieldValue.serverTimestamp(),
        'countedCash': countedCash,
        'note': note.trim(),
      });
      transaction.set(state, {'activeShiftId': null});
    });
  }
}
