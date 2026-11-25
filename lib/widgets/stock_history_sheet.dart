import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../colors.dart';
import '../firebase_store.dart';
import '../products.dart';
import '../transactions.dart';

Future<void> showProductStockHistory(
  BuildContext context,
  Product product,
) async {
  try {
    final stream = accountRef
        .collection('stockMovements')
        .where('productId', isEqualTo: product.id)
        .snapshots();
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * .75,
      ),
      builder: (_) => StockHistorySheet(product: product, movements: stream),
    );
  } catch (error) {
    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(firebaseMessage(error))));
    }
  }
}

class StockHistorySheet extends StatelessWidget {
  const StockHistorySheet({
    super.key,
    required this.product,
    required this.movements,
  });
  final Product product;
  final Stream<QuerySnapshot<Map<String, dynamic>>> movements;

  @override
  Widget build(BuildContext context) => SafeArea(
    child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: movements,
      builder: (context, snapshot) {
        final docs = [...?snapshot.data?.docs]
          ..sort((a, b) {
            final left = a.data()['date'] as Timestamp?;
            final right = b.data()['date'] as Timestamp?;
            return (right?.millisecondsSinceEpoch ?? 0).compareTo(
              left?.millisecondsSinceEpoch ?? 0,
            );
          });
        return ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          children: [
            const Text(
              'Riwayat Penambahan Stok',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(product.name, style: const TextStyle(color: AppColors.muted)),
            const SizedBox(height: 20),
            if (snapshot.hasError)
              Text(firebaseMessage(snapshot.error!))
            else if (!snapshot.hasData)
              const Center(child: CircularProgressIndicator())
            else if (docs.isEmpty)
              const Text('Belum ada penambahan stok yang tercatat.'),
            for (final doc in docs)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(
                  Icons.add_box_outlined,
                  color: AppColors.background,
                ),
                title: Text(
                  '+${(doc.data()['quantity'] as num?)?.toInt() ?? 0} pcs',
                ),
                subtitle: Text(
                  doc.data()['date'] is Timestamp
                      ? transactionDate(
                          (doc.data()['date'] as Timestamp).toDate(),
                        )
                      : 'Sedang menyimpan...',
                ),
              ),
          ],
        );
      },
    ),
  );
}
