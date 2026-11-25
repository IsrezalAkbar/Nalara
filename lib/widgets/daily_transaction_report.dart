import 'package:flutter/material.dart';

import '../analytics.dart';
import '../colors.dart';
import '../products.dart' show productRupiah;
import '../report_metrics.dart';
import '../transactions.dart';

const _blue = Color(0xFF233F91);
const _muted = Color(0xFF77869E);
const _line = Color(0xFFEBEFF5);

class DailyTransactionReport extends StatefulWidget {
  const DailyTransactionReport({super.key});

  @override
  State<DailyTransactionReport> createState() => _DailyTransactionReportState();
}

class _DailyTransactionReportState extends State<DailyTransactionReport> {
  DateTimeRange? _range;
  bool _customPeriod = false;

  Future<void> _pickRange() async {
    final today = DateUtils.dateOnly(DateTime.now());
    var firstDate = DateTime(2000);
    for (final sale in TransactionHistory.instance.items) {
      if (sale.date.isBefore(firstDate)) {
        firstDate = DateUtils.dateOnly(sale.date);
      }
    }
    final range = await showDateRangePicker(
      context: context,
      firstDate: firstDate,
      lastDate: today,
      initialDateRange: _range ?? DateTimeRange(start: today, end: today),
      helpText: 'Pilih Rentang Waktu',
      saveText: 'Terapkan',
      confirmText: 'Terapkan',
      cancelText: 'Batal',
      fieldStartLabelText: 'Tanggal Mulai',
      fieldEndLabelText: 'Tanggal Akhir',
      errorInvalidRangeText: 'Tanggal akhir harus setelah tanggal mulai.',
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.fromSeed(
            seedColor: _blue,
            brightness: Brightness.light,
            surface: Colors.white,
          ),
          scaffoldBackgroundColor: Colors.white,
        ),
        child: child!,
      ),
    );
    if (!mounted || range == null) return;
    setState(() {
      _range = range;
      _customPeriod = true;
    });
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: TransactionHistory.instance,
    builder: (context, _) {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final start = _customPeriod ? _range!.start : today;
      final end = _customPeriod ? _range!.end : today;
      final periodLabel = start == end
          ? transactionDate(start)
          : '${transactionDate(start)} – ${transactionDate(end)}';
      final report = SalesAnalytics(
        TransactionHistory.instance.items,
        start,
        DateTime(end.year, end.month, end.day + 1),
      );
      final products = productPerformance(report);
      return SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          key: const PageStorageKey('daily-transaction-report'),
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Wrap(
                    spacing: 10,
                    runSpacing: 8,
                    children: [
                      ChoiceChip(
                        label: const Text('Hari Ini'),
                        avatar: const Icon(Icons.today_outlined, size: 18),
                        selected: !_customPeriod,
                        onSelected: (_) =>
                            setState(() => _customPeriod = false),
                      ),
                      ChoiceChip(
                        label: const Text('Rentang Waktu'),
                        avatar: const Icon(Icons.date_range_outlined, size: 18),
                        selected: _customPeriod,
                        onSelected: (_) => _pickRange(),
                      ),
                    ],
                  ),
                  if (_customPeriod) ...[
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: _pickRange,
                      icon: const Icon(Icons.edit_calendar_outlined, size: 18),
                      label: const Text('Ubah Rentang Waktu'),
                    ),
                  ],
                  const SizedBox(height: 18),
                  Wrap(
                    spacing: 12,
                    runSpacing: 10,
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        _customPeriod
                            ? 'Ringkasan periode'
                            : 'Ringkasan hari ini',
                        style: const TextStyle(
                          color: AppColors.ink,
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(9),
                          border: Border.all(color: _line),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.calendar_today_outlined,
                              size: 13,
                              color: _muted,
                            ),
                            const SizedBox(width: 7),
                            Flexible(
                              child: Text(
                                periodLabel,
                                style: const TextStyle(
                                  color: _muted,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  _RevenueCard(report: report, today: !_customPeriod),
                  const SizedBox(height: 26),
                  _SectionHeading(
                    title: 'Metode pembayaran',
                    subtitle: _customPeriod
                        ? 'Porsi nominal dari total penjualan periode ini'
                        : 'Porsi nominal dari total penjualan hari ini',
                  ),
                  const SizedBox(height: 14),
                  _AdaptivePair(
                    first: _PaymentSummary(method: 'Tunai', report: report),
                    second: _PaymentSummary(method: 'QRIS', report: report),
                  ),
                  const SizedBox(height: 26),
                  _SectionHeading(
                    title: 'Barang Terjual',
                    subtitle:
                        '${products.length} jenis produk • Diurutkan dari jumlah terjual',
                  ),
                  const SizedBox(height: 14),
                  Container(
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: _line),
                    ),
                    child: products.isEmpty
                        ? _EmptyProducts(today: !_customPeriod)
                        : Column(
                            children: [
                              for (
                                var index = 0;
                                index < products.length;
                                index++
                              ) ...[
                                if (index > 0)
                                  const Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 18,
                                    ),
                                    child: Divider(height: 1, color: _line),
                                  ),
                                _SoldProductRow(
                                  key: ValueKey(
                                    'sold-product-${products[index].id.isEmpty ? products[index].name : products[index].id}',
                                  ),
                                  product: products[index],
                                  rank: index + 1,
                                ),
                              ],
                            ],
                          ),
                  ),
                  const SizedBox(height: 16),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.receipt_long_outlined,
                        size: 14,
                        color: _muted,
                      ),
                      SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          'Berdasarkan transaksi yang sudah dicatat',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: _muted, fontSize: 11),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}

class _RevenueCard extends StatelessWidget {
  const _RevenueCard({required this.report, required this.today});
  final SalesAnalytics report;
  final bool today;

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(22),
      boxShadow: [
        BoxShadow(
          color: _blue.withValues(alpha: 0.13),
          blurRadius: 20,
          offset: const Offset(0, 7),
        ),
      ],
    ),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF29499F), Color(0xFF1C3379)],
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              right: -42,
              top: -65,
              child: ExcludeSemantics(
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.04),
                      width: 32,
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.account_balance_wallet_outlined,
                        color: Color(0xFFBFCFF6),
                        size: 18,
                      ),
                      const SizedBox(width: 9),
                      Expanded(
                        child: Text(
                          today
                              ? 'Total Penjualan Hari Ini'
                              : 'Total Penjualan Periode Ini',
                          style: const TextStyle(
                            color: Color(0xFFDCE6FF),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    productRupiah(report.revenue),
                    key: const ValueKey('daily-revenue'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 34,
                      height: 1.2,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -1,
                    ),
                  ),
                  const SizedBox(height: 22),
                  const Divider(color: Color(0xFF5067A3), height: 1),
                  const SizedBox(height: 17),
                  _AdaptivePair(
                    first: _RevenueMetric(
                      icon: Icons.receipt_long_outlined,
                      value: '${report.sales.length} transaksi',
                      valueKey: 'daily-count',
                    ),
                    second: _RevenueMetric(
                      icon: Icons.shopping_bag_outlined,
                      value: '${report.quantity} barang terjual',
                      valueKey: 'daily-quantity',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _RevenueMetric extends StatelessWidget {
  const _RevenueMetric({
    required this.icon,
    required this.value,
    required this.valueKey,
  });
  final IconData icon;
  final String value, valueKey;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, color: const Color(0xFFBFCFF6), size: 17),
      const SizedBox(width: 8),
      Expanded(
        child: Text(
          value,
          key: ValueKey(valueKey),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    ],
  );
}

class _PaymentSummary extends StatelessWidget {
  const _PaymentSummary({required this.method, required this.report});
  final String method;
  final SalesAnalytics report;

  @override
  Widget build(BuildContext context) {
    final sales = report.sales.where((sale) => sale.method == method).toList();
    final revenue = sales.fold(0, (sum, sale) => sum + sale.total);
    final share = report.revenue > 0
        ? (revenue / report.revenue).clamp(0.0, 1.0)
        : 0.0;
    final cash = method == 'Tunai';
    final color = cash ? const Color(0xFF168575) : const Color(0xFF7560C6);
    final tint = cash ? const Color(0xFFE9F6F1) : const Color(0xFFF1EDFC);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _line),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: tint,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  cash ? Icons.payments_outlined : Icons.qr_code_rounded,
                  color: color,
                  size: 19,
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  method,
                  style: const TextStyle(
                    color: AppColors.ink,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            productRupiah(revenue),
            key: ValueKey('daily-$method-revenue'),
            style: const TextStyle(
              color: AppColors.ink,
              fontSize: 20,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            '${sales.length} transaksi',
            key: ValueKey('daily-$method-count'),
            style: const TextStyle(color: _muted, fontSize: 11),
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: share,
              minHeight: 5,
              color: color,
              backgroundColor: tint,
              semanticsLabel: 'Porsi nominal $method',
            ),
          ),
          const SizedBox(height: 7),
          Text(
            '${(share * 100).toStringAsFixed(1).replaceAll('.', ',')}% dari penjualan',
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _SoldProductRow extends StatelessWidget {
  const _SoldProductRow({super.key, required this.product, required this.rank});
  final ProductPerformance product;
  final int rank;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(18),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 30,
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: rank == 1
                ? const Color(0xFFFFF4D9)
                : const Color(0xFFF2F5F9),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Text(
            '$rank',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: rank == 1 ? const Color(0xFFA36C16) : _muted,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final stacked =
                  constraints.maxWidth <
                  235 * MediaQuery.textScalerOf(context).scale(14) / 14;
              final name = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: const TextStyle(
                      color: AppColors.ink,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${product.quantity} terjual',
                    style: const TextStyle(color: _muted, fontSize: 11),
                  ),
                ],
              );
              final amount = Text(
                productRupiah(product.revenue),
                textAlign: stacked ? TextAlign.left : TextAlign.right,
                style: const TextStyle(
                  color: _blue,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              );
              if (stacked) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [name, const SizedBox(height: 10), amount],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: name),
                  const SizedBox(width: 12),
                  Expanded(child: amount),
                ],
              );
            },
          ),
        ),
      ],
    ),
  );
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({required this.title, required this.subtitle});
  final String title, subtitle;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        title,
        style: const TextStyle(
          color: AppColors.ink,
          fontSize: 16,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.3,
        ),
      ),
      const SizedBox(height: 5),
      Text(
        subtitle,
        style: const TextStyle(color: _muted, fontSize: 11, height: 1.5),
      ),
    ],
  );
}

class _AdaptivePair extends StatelessWidget {
  const _AdaptivePair({required this.first, required this.second});
  final Widget first, second;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final scale = MediaQuery.textScalerOf(context).scale(14) / 14;
      if (constraints.maxWidth < 280 * scale) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [first, const SizedBox(height: 12), second],
        );
      }
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: first),
          const SizedBox(width: 12),
          Expanded(child: second),
        ],
      );
    },
  );
}

class _EmptyProducts extends StatelessWidget {
  const _EmptyProducts({required this.today});
  final bool today;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
    child: Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.softBlue,
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Icon(
            Icons.receipt_long_outlined,
            color: AppColors.logoBlue,
            size: 30,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          today
              ? 'Belum ada penjualan hari ini'
              : 'Belum ada penjualan pada rentang waktu ini',
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.ink,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Produk yang terjual akan tampil di sini setelah transaksi dicatat di kasir.',
          textAlign: TextAlign.center,
          style: TextStyle(color: _muted, fontSize: 12, height: 1.6),
        ),
      ],
    ),
  );
}
