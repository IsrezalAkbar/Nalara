import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../analytics.dart';
import '../colors.dart';
import '../products.dart';
import '../report_metrics.dart';
import '../report_view.dart';
import 'app_navigation.dart';
import 'report_chart.dart';
import 'report_switcher.dart';

/// Premium report presentation. All figures come from the selected date range.
class PremiumReportPage extends StatelessWidget {
  const PremiumReportPage({
    super.key,
    required this.view,
    required this.analytics,
    required this.previous,
    required this.catalog,
    required this.days,
    required this.customRange,
    required this.month,
    required this.onPeriod,
    required this.onCustomRange,
    required this.onBack,
    required this.onView,
    required this.onProduct,
    required this.onInsight,
    required this.onAddStock,
    required this.onEditProduct,
    required this.onStockHistory,
    required this.onExport,
    required this.exporting,
    this.detailProduct,
    required this.recentSales,
  });
  final ReportView view;
  final SalesAnalytics analytics, previous, recentSales;
  final List<Product> catalog;
  final Product? detailProduct;
  final int days;
  final bool customRange, month, exporting;
  final ValueChanged<int> onPeriod;
  final VoidCallback onCustomRange, onBack;
  final ValueChanged<ReportView> onView;
  final ValueChanged<Product> onProduct,
      onInsight,
      onAddStock,
      onEditProduct,
      onStockHistory;
  final VoidCallback? onExport;

  static const blue = Color(0xFF233F91);
  static const green = Color(0xFF00B985);
  static const red = Color(0xFFFF575F);
  static const muted = Color(0xFF8B9AB3);
  List<ProductPerformance> get ranking => productPerformance(analytics);
  // Include products that sold previously but have no sales in this period.
  List<ProductPerformance> get comparedProducts {
    final current = ranking;
    for (final product in productPerformance(previous)) {
      if (!current.any(
        (p) => product.id.isNotEmpty
            ? p.id == product.id
            : p.id.isEmpty && p.name == product.name,
      )) {
        current.add(ProductPerformance(product.id, product.name));
      }
    }
    return current;
  }

  List<Product> get lowStock =>
      catalog.where((p) => p.active && p.stock <= p.minimumStock).toList();
  Product? lookup(String id) {
    for (final product in catalog) {
      if (product.id == id) return product;
    }
    return null;
  }

  ProductPerformance? previousProduct(ProductPerformance item) {
    for (final product in productPerformance(previous)) {
      if (item.id.isNotEmpty
          ? product.id == item.id
          : product.id.isEmpty && product.name == item.name) {
        return product;
      }
    }
    return null;
  }

  String changeText(double? value) => value == null
      ? 'Belum ada pembanding'
      : '${value >= 0 ? '+' : ''}${value.toStringAsFixed(1)}%';
  String compact(int value) => value.abs() >= 1000000
      ? 'Rp${(value / 1000000).toStringAsFixed(2).replaceAll('.', ',')}jt'
      : productRupiah(value);

  @override
  Widget build(BuildContext context) {
    final textScale = MediaQuery.textScalerOf(context).scale(14) / 14;
    final hasPeriod = [
      ReportView.sales,
      ReportView.products,
      ReportView.profit,
    ].contains(view);
    final sections = switch (view) {
      ReportView.sales => _sales(context),
      ReportView.products => _products(context),
      ReportView.profit => _profit(context),
      ReportView.insights => _insights(context),
      _ => _detail(context),
    };
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        backgroundColor: blue,
        foregroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: 76,
        titleSpacing: 8,
        leadingWidth: 66,
        leading: Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 4, 18),
          child: IconButton(
            padding: EdgeInsets.zero,
            tooltip: 'Kembali',
            onPressed: onBack,
            style: IconButton.styleFrom(
              backgroundColor: Colors.white.withValues(alpha: .12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Icon(Icons.chevron_left_rounded, size: 22),
          ),
        ),
        title: ReportSwitcher(current: view, onSelected: onView, onDark: true),
        actions: [
          if (view == ReportView.profit &&
              MediaQuery.textScalerOf(context).scale(18) <= 24)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _badge(
                '★ PREMIUM',
                const Color(0xFF8A5500),
                background: const Color(0xFFFFD66C),
              ),
            ),
        ],
      ),
      bottomNavigationBar: view == ReportView.insightDetail
          ? SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 14),
                child: _button(
                  'Tambah Stok',
                  Icons.add,
                  detailProduct == null
                      ? null
                      : () => onAddStock(detailProduct!),
                ),
              ),
            )
          : const NalaraNavigation(index: 4),
      body: SafeArea(
        top: false,
        bottom: false,
        child: SingleChildScrollView(
          child: Stack(
            children: [
              Container(
                height: hasPeriod
                    ? 130 + 45 * (textScale - 1)
                    : view == ReportView.insights
                    ? 110 + 90 * (textScale - 1)
                    : 48,
                decoration: const BoxDecoration(
                  color: blue,
                  borderRadius: BorderRadius.vertical(
                    bottom: Radius.circular(32),
                  ),
                ),
              ),
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 620),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (hasPeriod) ...[
                          _periods(),
                          const SizedBox(height: 8),
                          Text(
                            '${_dateLabel(analytics.start)} – ${_dateLabel(analytics.end.subtract(const Duration(days: 1)))}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Color(0xFFCDD9F4),
                              fontSize: 10,
                            ),
                          ),
                          const SizedBox(height: 18),
                        ],
                        if (view == ReportView.insights) ...[
                          const Text(
                            'Asisten Bisnis Kamu',
                            style: TextStyle(
                              color: Color(0xFFB3C5F3),
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Insight untuk Bisnis Kamu',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],
                        for (final section in sections) ...[
                          section,
                          const SizedBox(height: 20),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _dateLabel(DateTime date) => '${date.day}/${date.month}/${date.year}';

  Widget _periods() {
    final options = view == ReportView.products
        ? [(7, '7 Hari'), (30, '30 Hari'), (90, '3 Bulan')]
        : view == ReportView.profit
        ? [(1, 'Hari Ini'), (0, 'Bulan Ini'), (-1, 'Custom')]
        : [(1, 'Hari Ini'), (7, '7 Hari'), (30, '30 Hari')];
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .10),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          for (final option in options)
            Expanded(
              child: TextButton(
                onPressed: option.$1 == -1
                    ? onCustomRange
                    : () => onPeriod(option.$1),
                style: TextButton.styleFrom(
                  backgroundColor:
                      (option.$1 == -1
                          ? customRange
                          : !customRange &&
                                (option.$1 == 0
                                    ? month
                                    : !month && days == option.$1))
                      ? Colors.white
                      : Colors.transparent,
                  foregroundColor:
                      (option.$1 == -1
                          ? customRange
                          : !customRange &&
                                (option.$1 == 0
                                    ? month
                                    : !month && days == option.$1))
                      ? blue
                      : Colors.white,
                  minimumSize: const Size(0, 38),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  option.$2,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _card(
    List<Widget> children, {
    Color color = Colors.white,
    bool shadow = false,
  }) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(26),
      border: Border.all(color: const Color(0xFFEDF1F7)),
      boxShadow: shadow
          ? [
              BoxShadow(
                color: blue.withValues(alpha: .12),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ]
          : null,
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: children,
    ),
  );
  Widget _title(String title, {String? aside, Color color = blue}) => Padding(
    padding: const EdgeInsets.only(bottom: 18),
    child: Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
          ),
        ),
        if (aside != null) ...[
          const SizedBox(width: 8),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 110),
            child: Text(
              aside,
              textAlign: TextAlign.end,
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ],
    ),
  );
  Widget _badge(String text, Color color, {Color? background}) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
    decoration: BoxDecoration(
      color: background ?? color.withValues(alpha: .09),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Text(
      text,
      style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w700),
    ),
  );
  Widget _metric(
    String label,
    String value, {
    Color color = blue,
    IconData? icon,
  }) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      if (icon != null) ...[
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: .08),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(height: 12),
      ],
      Text(
        label.toUpperCase(),
        style: const TextStyle(
          color: muted,
          fontSize: 10,
          fontWeight: FontWeight.w600,
          letterSpacing: .5,
        ),
      ),
      const SizedBox(height: 6),
      Text(
        value,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w800,
          fontSize: 17,
        ),
      ),
    ],
  );
  Widget _pair(Widget left, Widget right) => LayoutBuilder(
    builder: (context, constraints) {
      if (constraints.maxWidth < 245 ||
          MediaQuery.textScalerOf(context).scale(14) > 22) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [left, const SizedBox(height: 18), right],
        );
      }
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: left),
          const SizedBox(width: 16),
          Expanded(child: right),
        ],
      );
    },
  );
  Widget _button(
    String label,
    IconData icon,
    VoidCallback? action, {
    bool soft = false,
  }) => FilledButton.icon(
    onPressed: action,
    icon: exporting && label.contains('Unduh')
        ? const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        : Icon(icon, size: 18),
    label: Text(
      label,
      textAlign: TextAlign.center,
      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
    ),
    style: FilledButton.styleFrom(
      backgroundColor: soft ? const Color(0xFFF0F4FA) : blue,
      foregroundColor: soft ? blue : Colors.white,
      minimumSize: const Size.fromHeight(48),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
  );
  Widget _empty(String text) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 16),
    child: Text(
      text,
      style: const TextStyle(color: muted, fontSize: 13, height: 1.6),
    ),
  );
  Widget _change(double? change) => _badge(
    changeText(change),
    change == null
        ? muted
        : change >= 0
        ? green
        : red,
  );
  List<String> get _labels => List.generate(analytics.dailyRevenue.length, (i) {
    final d = analytics.start.add(Duration(days: i));
    return '${d.day}/${d.month}';
  });
  Widget _exportCard(String title) => _card([
    _title(title, aside: 'PDF'),
    const Text(
      'Unduh laporan sesuai periode yang dipilih.',
      style: TextStyle(color: muted, fontSize: 12, height: 1.5),
    ),
    const SizedBox(height: 14),
    _button('Unduh Laporan PDF', Icons.picture_as_pdf_outlined, onExport),
  ], color: const Color(0xFFEFF5FF));

  List<Widget> _sales(BuildContext context) {
    final change = percentageChange(analytics.revenue, previous.revenue);
    return [
      _card([
        Row(
          children: [
            const Expanded(
              child: Text(
                'Total Omzet',
                style: TextStyle(color: muted, fontSize: 12),
              ),
            ),
            Flexible(
              child: Align(
                alignment: Alignment.centerRight,
                child: _change(change),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          productRupiah(analytics.revenue),
          style: const TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.w900,
            letterSpacing: -.8,
          ),
        ),
        const SizedBox(height: 24),
        _pair(
          _metric('Total modal', productRupiah(analytics.cost)),
          _metric('Laba kotor', productRupiah(analytics.profit), color: green),
        ),
      ], shadow: true),
      _card([
        _title('Grafik Penjualan', aside: 'OMZET HARIAN', color: muted),
        ReportChart(
          values: analytics.dailyRevenue.map((e) => e.toDouble()).toList(),
          labels: _labels,
          bars: true,
          money: true,
          description: 'Omzet harian',
        ),
        if (analytics.sales.isEmpty)
          _empty('Belum ada transaksi pada periode ini.'),
      ]),
      const Text(
        'Statistik Operasional',
        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
      ),
      _pair(
        _card([
          _metric(
            'Total transaksi',
            '${analytics.sales.length}',
            icon: Icons.shopping_bag_rounded,
          ),
        ]),
        _card([
          _metric(
            'Rata-rata transaksi',
            productRupiah(
              analytics.sales.isEmpty
                  ? 0
                  : (analytics.revenue / analytics.sales.length).round(),
            ),
            icon: Icons.local_atm_rounded,
            color: green,
          ),
        ]),
      ),
      _card([
        _pair(
          _metric(
            'Total produk terjual',
            '${analytics.quantity} items',
            icon: Icons.shopping_cart_checkout_rounded,
            color: red,
          ),
          Align(
            alignment: Alignment.centerRight,
            child: _change(
              percentageChange(analytics.quantity, previous.quantity),
            ),
          ),
        ),
      ]),
      Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [blue, Color(0xFF3578E4)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.description_outlined, color: Colors.white, size: 22),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Ringkasan Eksekutif',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              change == null
                  ? 'Catat transaksi secara rutin untuk melihat perubahan penjualan dari periode ke periode.'
                  : 'Omzet ${change >= 0 ? 'meningkat' : 'menurun'} ${change.abs().toStringAsFixed(1)}% dibanding periode sebelumnya. '
                        '${ranking.isEmpty ? '' : '${ranking.first.name} menjadi produk paling banyak terjual.'}',
              style: const TextStyle(
                color: Color(0xFFE1EBFF),
                height: 1.8,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              '${analytics.sales.length} transaksi dianalisis',
              style: const TextStyle(color: Color(0xFFB4D2FF), fontSize: 11),
            ),
          ],
        ),
      ),
      _button('Unduh Laporan PDF', Icons.picture_as_pdf_outlined, onExport),
    ];
  }

  Widget _productRow(
    ProductPerformance item,
    int index, {
    bool profit = false,
  }) {
    final product = lookup(item.id);
    final change = percentageChange(
      item.quantity,
      previousProduct(item)?.quantity ?? 0,
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: product == null ? null : () => onProduct(product),
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: 48,
                height: 52,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: SizedBox(
                        width: 46,
                        height: 46,
                        child: product == null
                            ? const ColoredBox(
                                color: AppColors.softBlue,
                                child: Icon(
                                  Icons.inventory_2_outlined,
                                  color: blue,
                                ),
                              )
                            : ProductPhoto(product: product),
                      ),
                    ),
                    if (!profit)
                      Positioned(
                        top: -5,
                        left: -5,
                        child: CircleAvatar(
                          radius: 9,
                          backgroundColor: muted,
                          child: Text(
                            '${index + 1}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      profit
                          ? 'Margin ${item.margin.toStringAsFixed(1)}%'
                          : '${item.quantity} unit terjual',
                      style: const TextStyle(fontSize: 11, color: muted),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      profit
                          ? '${compact(item.profit)} laba kotor'
                          : changeText(change),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: profit
                            ? (item.profit >= 0 ? green : red)
                            : (change == null
                                  ? muted
                                  : change >= 0
                                  ? green
                                  : red),
                      ),
                    ),
                  ],
                ),
              ),
              if (product != null)
                const Icon(Icons.chevron_right_rounded, color: muted, size: 18),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _products(BuildContext context) {
    final sorted = ranking;
    final declining = comparedProducts
        .where(
          (p) =>
              (percentageChange(
                    p.quantity,
                    previousProduct(p)?.quantity ?? 0,
                  ) ??
                  0) <
              0,
        )
        .toList();
    List<double> daily(ProductPerformance item) =>
        List.generate(analytics.dailyRevenue.length, (i) {
          final start = analytics.start.add(Duration(days: i));
          return analytics.sales
              .where(
                (s) =>
                    !s.date.isBefore(start) &&
                    s.date.isBefore(start.add(const Duration(days: 1))),
              )
              .fold<double>(
                0,
                (sum, s) =>
                    sum +
                    s.items
                        .where(
                          (p) => item.id.isNotEmpty
                              ? p.productId == item.id
                              : p.productId.isEmpty && p.name == item.name,
                        )
                        .fold(0, (sum, p) => sum + p.quantity),
              );
        });
    return [
      _card([
        _title('Produk Terlaris', aside: 'TOP ${math.min(sorted.length, 3)}'),
        if (sorted.isEmpty)
          _empty('Belum ada produk terjual pada periode ini.'),
        for (var i = 0; i < math.min(sorted.length, 3); i++)
          _productRow(sorted[i], i),
      ]),
      _card([
        _title('Tren Produk Terlaris', aside: 'UNIT TERJUAL'),
        if (sorted.isEmpty)
          _empty('Grafik akan muncul setelah ada penjualan.')
        else ...[
          ReportChart(
            values: daily(sorted.first),
            secondary: sorted.length > 1 ? daily(sorted[1]) : null,
            labels: _labels,
            description: 'Jumlah produk terjual per hari',
          ),
          Wrap(
            spacing: 14,
            runSpacing: 8,
            children: [
              Text(
                '━ ${sorted.first.name}',
                style: const TextStyle(color: blue, fontSize: 11),
              ),
              if (sorted.length > 1)
                Text(
                  '┄ ${sorted[1].name}',
                  style: const TextStyle(
                    color: AppColors.logoBlue,
                    fontSize: 11,
                  ),
                ),
            ],
          ),
        ],
      ]),
      _card([
        _title('Perlu Perhatian', aside: 'PENJUALAN TURUN', color: red),
        if (declining.isEmpty)
          _empty('Belum ada penurunan penjualan yang terdeteksi.'),
        for (var i = 0; i < declining.length; i++) _productRow(declining[i], i),
        if (declining.isNotEmpty)
          _recommendation(
            'Pertimbangkan evaluasi harga atau promosi produk yang menurun. Bandingkan kembali pada periode berikutnya.',
            AppColors.orange,
          ),
      ]),
      _exportCard('Unduh Analisis Lengkap'),
    ];
  }

  List<Widget> _profit(BuildContext context) {
    final products = ranking..sort((a, b) => b.profit.compareTo(a.profit));
    final daily = List.generate(analytics.dailyRevenue.length, (i) {
      final start = analytics.start.add(Duration(days: i));
      return analytics.sales
          .where(
            (s) =>
                !s.date.isBefore(start) &&
                s.date.isBefore(start.add(const Duration(days: 1))),
          )
          .fold<double>(0, (sum, s) => sum + s.total - s.cost);
    });
    return [
      _card([
        Text(
          month ? 'LABA KOTOR BULAN INI' : 'LABA KOTOR PERIODE INI',
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: muted,
            letterSpacing: 1,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          productRupiah(analytics.profit),
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 12),
        Center(
          child: _change(percentageChange(analytics.profit, previous.profit)),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 20),
          child: Divider(color: Color(0xFFEDF1F7)),
        ),
        _pair(
          _metric('Total omzet', productRupiah(analytics.revenue)),
          _metric('Total modal', productRupiah(analytics.cost), color: red),
        ),
        const SizedBox(height: 20),
        _pair(
          _metric('Laba kotor', productRupiah(analytics.profit)),
          _metric(
            'Margin',
            '${(analytics.revenue == 0 ? 0 : analytics.profit / analytics.revenue * 100).toStringAsFixed(1)}%',
            color: green,
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Belum dikurangi biaya operasional.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 11, color: muted),
        ),
      ], shadow: true),
      _card([
        _title('Tren Profitabilitas', aside: 'LABA HARIAN'),
        ReportChart(
          values: daily,
          labels: _labels,
          bars: true,
          money: true,
          description: 'Laba kotor harian',
        ),
        if (analytics.sales.isEmpty)
          _empty('Belum ada transaksi pada periode ini.'),
      ]),
      _title('Kontribusi Laba per Produk', aside: 'LABA KOTOR'),
      if (products.isEmpty)
        _card([_empty('Belum ada kontribusi laba produk.')]),
      for (var i = 0; i < products.length; i++)
        _card([_productRow(products[i], i, profit: true)]),
      _exportCard('Ekspor Analisis Laba'),
    ];
  }

  Widget _recommendation(String text, Color color) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: color.withValues(alpha: .06),
      border: Border(left: BorderSide(color: color, width: 3)),
      borderRadius: BorderRadius.circular(10),
    ),
    child: Text.rich(
      TextSpan(
        children: [
          const TextSpan(
            text: 'Rekomendasi: ',
            style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.ink),
          ),
          TextSpan(text: text),
        ],
      ),
      style: const TextStyle(color: muted, height: 1.7, fontSize: 12),
    ),
  );

  List<Widget> _insights(BuildContext context) {
    final trends = comparedProducts
        .where(
          (p) =>
              lookup(p.id)?.active == true &&
              (percentageChange(
                        p.quantity,
                        previousProduct(p)?.quantity ?? 0,
                      ) ??
                      0) !=
                  0,
        )
        .toList();
    return [
      for (final product in lowStock)
        _card([
          _title('STOK HAMPIR HABIS', aside: 'Saat ini', color: muted),
          Text(
            product.name,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 18),
          _pair(
            _metric('Sisa stok', '${product.stock} pcs', color: red),
            _metric('Batas minimum', '${product.minimumStock} pcs'),
          ),
          const SizedBox(height: 18),
          _recommendation(
            'Tinjau kebutuhan restock agar penjualan ${product.name} tidak terganggu.',
            red,
          ),
          const SizedBox(height: 16),
          _button('Lihat Stok', Icons.chevron_right, () => onInsight(product)),
        ]),
      for (final product in trends) _trendInsight(product),
      if (lowStock.isEmpty && trends.isEmpty)
        _card([
          const Icon(Icons.insights_rounded, color: blue, size: 36),
          _empty(
            'Belum ada peringatan stok atau perubahan penjualan untuk periode ini.',
          ),
        ]),
      _card([
        const Icon(Icons.description_outlined, color: blue, size: 30),
        const SizedBox(height: 14),
        const Text(
          'Butuh Analisis Lebih Dalam?',
          textAlign: TextAlign.center,
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
        ),
        const SizedBox(height: 8),
        const Text(
          'Lihat laporan penjualan lengkap untuk periode yang dipilih.',
          textAlign: TextAlign.center,
          style: TextStyle(color: muted, fontSize: 12, height: 1.6),
        ),
        const SizedBox(height: 16),
        _button(
          'Lihat Laporan',
          Icons.arrow_forward_rounded,
          () => onView(ReportView.sales),
          soft: true,
        ),
      ], color: const Color(0xFFEFF5FF)),
    ];
  }

  Widget _trendInsight(ProductPerformance product) {
    final change = percentageChange(
      product.quantity,
      previousProduct(product)?.quantity ?? 0,
    )!;
    final up = change > 0;
    final color = up ? green : AppColors.orange;
    return _card([
      _title(
        up ? 'TREN MENINGKAT' : 'PERLU PERHATIAN',
        aside: '$days hari terakhir',
        color: color,
      ),
      Text(
        product.name,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
      ),
      const SizedBox(height: 12),
      Align(alignment: Alignment.centerLeft, child: _change(change)),
      const SizedBox(height: 16),
      _recommendation(
        up
            ? 'Penjualan meningkat. Tinjau ketersediaan stok untuk memenuhi permintaan.'
            : 'Penjualan menurun. Pertimbangkan promosi atau evaluasi harga untuk meningkatkan minat.',
        color,
      ),
      const SizedBox(height: 16),
      _button(
        'Lihat Produk',
        Icons.chevron_right,
        () => onProduct(lookup(product.id)!),
        soft: true,
      ),
    ]);
  }

  List<Widget> _detail(BuildContext context) {
    final product = detailProduct;
    if (product == null) {
      return [
        _card([
          _empty('Produk tidak ditemukan. Pilih produk dari Insight Bisnis.'),
        ]),
      ];
    }
    final quantity = recentSales.sales.fold<int>(
      0,
      (sum, sale) =>
          sum +
          sale.items
              .where((p) => p.productId == product.id)
              .fold(0, (sum, p) => sum + p.quantity),
    );
    final average = quantity / 7;
    final daysLeft = average == 0 ? null : product.stock / average;
    final projection = List.generate(
      7,
      (i) => math.max(0.0, product.stock - average * i),
    );
    return [
      _card([
        Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: SizedBox(
                width: 66,
                height: 66,
                child: ProductPhoto(product: product),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _badge(
                    product.stock <= product.minimumStock
                        ? 'HAMPIR HABIS'
                        : 'STOK AMAN',
                    product.stock <= product.minimumStock ? red : green,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    product.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        _pair(
          _metric('Stok saat ini', '${product.stock} pcs', color: red),
          _metric('Minimum stok', '${product.minimumStock} pcs'),
        ),
        const SizedBox(height: 24),
        _pair(
          _metric('Rata-rata / hari', '${average.toStringAsFixed(1)} pcs'),
          _metric(
            'Estimasi sisa',
            daysLeft == null
                ? 'Belum tersedia'
                : daysLeft < 1
                ? '< 1 hari'
                : '${daysLeft.floor()} hari',
            color: red,
          ),
        ),
      ], shadow: true),
      _card([
        _title('Proyeksi Stok (7 Hari)', aside: 'ESTIMASI', color: muted),
        ReportChart(
          values: projection,
          labels: List.generate(7, (i) {
            final d = DateTime.now().add(Duration(days: i));
            return '${d.day}/${d.month}';
          }),
          color: red,
          description: 'Proyeksi stok tanpa penambahan stok',
        ),
        const Text(
          'Berdasarkan rata-rata penjualan 7 hari, tanpa restock. Bukan riwayat stok aktual.',
          style: TextStyle(color: muted, fontSize: 11, height: 1.6),
        ),
      ]),
      _card([
        _title('REKOMENDASI STOK'),
        _recommendation(
          product.stock <= product.minimumStock
              ? 'Pertimbangkan restock ${product.name}. Stok saat ini sudah mencapai batas minimum yang Anda tetapkan.'
              : 'Stok berada di atas batas minimum. Pantau penjualan secara berkala sebelum menambah stok.',
          blue,
        ),
      ], color: const Color(0xFFEFF5FF)),
      _button(
        'Riwayat Stok ${product.name}',
        Icons.layers_outlined,
        () => onStockHistory(product),
        soft: true,
      ),
      _button(
        'Atur Ambang Batas',
        Icons.settings_outlined,
        () => onEditProduct(product),
        soft: true,
      ),
    ];
  }
}
