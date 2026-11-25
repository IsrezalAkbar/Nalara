import 'dart:convert';
import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import 'analytics.dart';
import 'products.dart';
import 'transactions.dart';

Future<Uint8List> receiptPdf(SaleTransaction sale, String store) async {
  final document = pw.Document();
  document.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a5,
      build: (_) => [
        pw.Header(
          level: 0,
          child: pw.Text(store.isEmpty ? 'Struk Penjualan' : store),
        ),
        pw.Text('#${sale.id}'),
        pw.Text(
          '${transactionDate(sale.date)} ${transactionTime(sale.date)} - ${sale.method}',
        ),
        pw.SizedBox(height: 16),
        pw.TableHelper.fromTextArray(
          headers: ['Produk', 'Jumlah', 'Harga', 'Subtotal'],
          data: [
            for (final item in sale.items)
              [
                item.name,
                '${item.quantity}',
                productRupiah(item.price),
                productRupiah(item.subtotal),
              ],
          ],
        ),
        pw.SizedBox(height: 16),
        pw.Text('Diskon: ${productRupiah(sale.discount)}'),
        pw.Text(
          'Total: ${productRupiah(sale.total)}',
          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
        ),
      ],
    ),
  );
  return document.save();
}

Future<void> exportReceipt(
  SaleTransaction sale,
  String store, {
  required bool print,
}) async {
  final bytes = await receiptPdf(sale, store);
  if (print) {
    await Printing.layoutPdf(
      onLayout: (_) async => bytes,
      name: 'Struk-${sale.id}',
    );
  } else {
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile.fromData(bytes, mimeType: 'application/pdf')],
        fileNameOverrides: ['Struk-${sale.id}.pdf'],
      ),
    );
  }
}

String csvCell(String value) {
  final safe = RegExp(r'^[=+\-@\t\r]').hasMatch(value) ? "'$value" : value;
  return '"${safe.replaceAll('"', '""')}"';
}

Future<void> exportReport(
  SalesAnalytics analytics,
  String store, {
  bool csv = false,
}) async {
  if (csv) {
    final lines = <List<String>>[
      ['ID', 'Tanggal', 'Metode', 'Omzet', 'Modal', 'Laba kotor'],
      for (final sale in analytics.sales)
        [
          sale.id,
          sale.date.toIso8601String(),
          sale.method,
          '${sale.total}',
          '${sale.cost}',
          '${sale.total - sale.cost}',
        ],
    ];
    final bytes = Uint8List.fromList(
      utf8.encode(
        '\ufeff${lines.map((line) => line.map(csvCell).join(',')).join('\r\n')}',
      ),
    );
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile.fromData(bytes, mimeType: 'text/csv')],
        fileNameOverrides: ['Laporan-Nalara.csv'],
      ),
    );
    return;
  }
  final document = pw.Document();
  document.addPage(
    pw.MultiPage(
      build: (_) => [
        pw.Header(level: 0, child: pw.Text('Laporan $store')),
        pw.Text(
          '${transactionDate(analytics.start)} - ${transactionDate(analytics.end.subtract(const Duration(days: 1)))}',
        ),
        pw.Text('Omzet: ${productRupiah(analytics.revenue)}'),
        pw.Text('Modal: ${productRupiah(analytics.cost)}'),
        pw.Text('Laba kotor: ${productRupiah(analytics.profit)}'),
        pw.SizedBox(height: 16),
        pw.TableHelper.fromTextArray(
          headers: ['Transaksi', 'Tanggal', 'Total'],
          data: [
            for (final sale in analytics.sales)
              [sale.id, transactionDate(sale.date), productRupiah(sale.total)],
          ],
        ),
      ],
    ),
  );
  await Printing.sharePdf(
    bytes: await document.save(),
    filename: 'Laporan-Nalara.pdf',
  );
}
