import 'package:flutter/material.dart';

import '../analytics.dart';
import '../colors.dart';
import '../products.dart';
import '../transactions.dart';
import 'revenue_trend_chart.dart';

class BusinessAnalyticsOverview extends StatelessWidget {
  const BusinessAnalyticsOverview({
    super.key,
    required this.analytics,
    required this.previous,
    required this.days,
    required this.customRange,
    required this.exporting,
    required this.onPeriodChanged,
    required this.onInsights,
    required this.onProducts,
    required this.onReport,
  });

  final SalesAnalytics analytics;
  final SalesAnalytics previous;
  final int days;
  final bool customRange;
  final bool exporting;
  final ValueChanged<int> onPeriodChanged;
  final VoidCallback onInsights;
  final VoidCallback onProducts;
  final VoidCallback onReport;

  double? _change(int current, int before) =>
      before == 0 ? null : (current - before) / before * 100;

  String _percent(double value) =>
      '${value > 0 ? '+' : ''}${value.toStringAsFixed(0)}%';

  String _money(int amount) {
    if (amount.abs() >= 1000000000) {
      return 'Rp${(amount / 1000000000).toStringAsFixed(2).replaceAll('.', ',')} M';
    }
    if (amount.abs() >= 1000000) {
      return 'Rp${(amount / 1000000).toStringAsFixed(2).replaceAll('.', ',')} jt';
    }
    return productRupiah(amount);
  }

  @override
  Widget build(BuildContext context) {
    final revenueChange = _change(analytics.revenue, previous.revenue);
    final ranking = analytics.ranking;
    final previousSold = previous.sold;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .10),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    for (final period in [1, 7, 30])
                      Expanded(
                        child: Semantics(
                          selected: !customRange && days == period,
                          child: TextButton(
                            onPressed: () => onPeriodChanged(period),
                            style: TextButton.styleFrom(
                              foregroundColor: !customRange && days == period
                                  ? const Color(0xFF233F91)
                                  : Colors.white,
                              backgroundColor: !customRange && days == period
                                  ? Colors.white
                                  : Colors.transparent,
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
                              period == 1 ? 'Hari Ini' : '$period Hari',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: !customRange && days == period
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              if (customRange)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Text(
                    '${transactionDate(analytics.start)} – ${transactionDate(analytics.end.subtract(const Duration(days: 1)))}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFFCDD9F4),
                      fontSize: 11,
                    ),
                  ),
                ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              LayoutBuilder(
                builder: (context, constraints) {
                  final revenue = _metric(
                    'Total Omzet',
                    _money(analytics.revenue),
                    revenueChange,
                    primary: true,
                    exactValue: productRupiah(analytics.revenue),
                  );
                  final transactions = _metric(
                    'Transaksi',
                    '${analytics.sales.length}',
                    _change(analytics.sales.length, previous.sales.length),
                  );
                  if (constraints.maxWidth < 280 ||
                      MediaQuery.textScalerOf(context).scale(14) > 20) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        revenue,
                        const SizedBox(height: 12),
                        transactions,
                      ],
                    );
                  }
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: revenue),
                      const SizedBox(width: 14),
                      Expanded(child: transactions),
                    ],
                  );
                },
              ),
              const SizedBox(height: 20),
              _card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Tren Penjualan',
                            style: TextStyle(
                              color: AppColors.ink,
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            customRange
                                ? 'RENTANG PILIHAN'
                                : days == 1
                                ? 'HARI INI'
                                : '$days HARI TERAKHIR',
                            textAlign: TextAlign.right,
                            style: const TextStyle(
                              color: Color(0xFF8B9AB3),
                              fontSize: 10,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    RevenueTrendChart(
                      values: analytics.dailyRevenue,
                      start: analytics.start,
                    ),
                    if (analytics.sales.isEmpty)
                      const Padding(
                        padding: EdgeInsets.only(top: 8),
                        child: Text(
                          'Belum ada transaksi pada periode ini.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppColors.muted,
                            fontSize: 11,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              _insight(revenueChange),
              const SizedBox(height: 20),
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Performa Produk',
                      style: TextStyle(
                        color: AppColors.ink,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: onProducts,
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF233F91),
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                    ),
                    child: const Text(
                      'Lihat Semua',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              if (ranking.isEmpty)
                _card(
                  child: const Text(
                    'Performa produk akan muncul setelah ada penjualan.',
                    style: TextStyle(color: AppColors.muted, fontSize: 12),
                  ),
                ),
              for (var i = 0; i < ranking.length && i < 2; i++) ...[
                _product(
                  ranking[i],
                  _change(ranking[i].value, previousSold[ranking[i].key] ?? 0),
                  first: i == 0,
                ),
                const SizedBox(height: 10),
              ],
              const SizedBox(height: 12),
              Material(
                color: const Color(0xFFEFF5FF),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(26),
                  side: const BorderSide(color: Color(0xFFEDF1F7)),
                ),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: exporting ? null : onReport,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 24,
                    ),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: const BoxDecoration(
                            color: Color(0xFFFFFFFF),
                            shape: BoxShape.circle,
                          ),
                          child: exporting
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(
                                  Icons.description_rounded,
                                  color: Color(0xFF233F91),
                                  size: 22,
                                ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Laporan Penjualan',
                          style: TextStyle(
                            color: AppColors.ink,
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          exporting
                              ? 'Menyiapkan laporan...'
                              : 'Unduh laporan detail untuk pembukuan',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Color(0xFF8B9AB3),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _card({required Widget child}) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(26),
      border: Border.all(color: const Color(0xFFEDF1F7)),
    ),
    child: child,
  );

  Widget _metric(
    String label,
    String value,
    double? change, {
    bool primary = false,
    String? exactValue,
  }) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(26),
      boxShadow: primary
          ? [
              BoxShadow(
                color: const Color(0xFF233F91).withValues(alpha: .10),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ]
          : null,
      border: Border.all(color: const Color(0xFFEDF1F7)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Color(0xFF8B9AB3), fontSize: 12),
        ),
        const SizedBox(height: 8),
        Tooltip(
          message: exactValue ?? value,
          child: Text(
            value,
            style: TextStyle(
              color: primary ? AppColors.ink : const Color(0xFF233F91),
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(height: 12),
        if (change == null)
          const Text(
            'Belum ada pembanding',
            style: TextStyle(color: Color(0xFF8B9AB3), fontSize: 10),
          )
        else
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
            decoration: BoxDecoration(
              color: change < 0
                  ? const Color(0xFFFEF2F2)
                  : const Color(0xFFECFDF5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  change < 0
                      ? Icons.trending_down_rounded
                      : Icons.trending_up_rounded,
                  size: 12,
                  color: change < 0
                      ? const Color(0xFFFF575F)
                      : const Color(0xFF00B985),
                ),
                const SizedBox(width: 3),
                Flexible(
                  child: Text(
                    _percent(change),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: change < 0
                          ? const Color(0xFFFF575F)
                          : const Color(0xFF00B985),
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    ),
  );

  Widget _insight(double? change) {
    final daily = analytics.dailyRevenue;
    var peak = 0;
    for (var i = 1; i < daily.length; i++) {
      if (daily[i] > daily[peak]) peak = i;
    }
    const weekdays = [
      'Senin',
      'Selasa',
      'Rabu',
      'Kamis',
      'Jumat',
      'Sabtu',
      'Minggu',
    ];
    final bestDay = analytics.start.add(Duration(days: peak));
    final description = analytics.sales.isEmpty
        ? 'Catat penjualan pertama untuk melihat tren dan insight bisnis Anda.'
        : change == null
        ? 'Omzet periode ini ${productRupiah(analytics.revenue)}. Belum ada penjualan pada periode pembanding.'
        : 'Omzet ${change == 0
              ? 'tetap'
              : change > 0
              ? 'meningkat'
              : 'menurun'}${change == 0 ? '' : ' ${change.abs().toStringAsFixed(1)}%'} dibanding periode sebelumnya.';
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF233F91), Color(0xFF3578E4)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(26),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 19),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Insight Bisnis',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Icon(
                Icons.lightbulb_outline_rounded,
                color: Color(0xFFCCDEF9),
                size: 32,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '$description${analytics.sales.isEmpty ? '' : ' Penjualan tertinggi pada ${weekdays[bestDay.weekday - 1]}, ${transactionDate(bestDay)}.'}',
            style: const TextStyle(
              color: Color(0xFFE1EBFF),
              fontSize: 13,
              height: 1.8,
            ),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: onInsights,
            style: FilledButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF233F91),
              minimumSize: const Size(0, 48),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: const Text(
              'Lihat semua insight  ›',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _product(
    MapEntry<String, int> product,
    double? change, {
    required bool first,
  }) {
    final declining = change != null && change < 0;
    final color = declining ? const Color(0xFFFF575F) : const Color(0xFF00B985);
    return _card(
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(
              color: declining
                  ? const Color(0xFFFEF2F2)
                  : const Color(0xFFECFDF5),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              declining
                  ? Icons.trending_down_rounded
                  : Icons.workspace_premium_rounded,
              size: 22,
              color: color,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.key,
                  style: const TextStyle(
                    color: AppColors.ink,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${first
                      ? 'TERLARIS'
                      : declining
                      ? 'MENURUN'
                      : 'TERJUAL'} · ${product.value} TERJUAL',
                  style: const TextStyle(
                    color: Color(0xFF8B9AB3),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              change == null ? '—' : _percent(change),
              textAlign: TextAlign.right,
              style: TextStyle(
                color: change == null ? AppColors.muted : color,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
