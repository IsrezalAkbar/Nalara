import 'package:flutter/material.dart';

import '../colors.dart';
import '../report_view.dart';

const _reports = [
  (
    ReportView.overview,
    'Analitik Bisnis',
    'Ringkasan usaha',
    Icons.dashboard_rounded,
  ),
  (
    ReportView.sales,
    'Laporan Penjualan',
    'Omzet dan transaksi',
    Icons.bar_chart_rounded,
  ),
  (
    ReportView.products,
    'Performa Produk',
    'Produk terlaris dan tren penjualan',
    Icons.inventory_2_outlined,
  ),
  (
    ReportView.profit,
    'Analisis Laba',
    'Modal, margin, dan laba',
    Icons.account_balance_wallet_outlined,
  ),
  (
    ReportView.insights,
    'Insight Bisnis',
    'Stok dan rekomendasi usaha',
    Icons.auto_awesome_outlined,
  ),
];

/// One consistent entry point for switching reports without adding routes.
class ReportSwitcher extends StatelessWidget {
  const ReportSwitcher({
    super.key,
    required this.current,
    required this.onSelected,
    this.onDark = false,
  });
  final ReportView current;
  final ValueChanged<ReportView> onSelected;
  final bool onDark;

  Future<void> _open(BuildContext context) async {
    final selected = current == ReportView.insightDetail
        ? ReportView.insights
        : current;
    final result = await showModalBottomSheet<ReportView>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      constraints: BoxConstraints(
        maxWidth: 540,
        maxHeight: MediaQuery.sizeOf(context).height * .85,
      ),
      builder: (sheetContext) => SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Pilih laporan',
                      style: TextStyle(
                        color: AppColors.ink,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Tutup pilihan laporan',
                    onPressed: () => Navigator.pop(sheetContext),
                    icon: const Icon(
                      Icons.close_rounded,
                      color: AppColors.muted,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              for (final report in _reports) ...[
                Semantics(
                  selected: selected == report.$1,
                  child: Material(
                    color: selected == report.$1
                        ? const Color(0xFFEDF2FF)
                        : Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                      side: BorderSide(
                        color: selected == report.$1
                            ? const Color(0xFFD1DEFF)
                            : const Color(0xFFF0F3F8),
                      ),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      key: ValueKey('report-option-${report.$1.name}'),
                      onTap: () => Navigator.pop(sheetContext, report.$1),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          children: [
                            Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: selected == report.$1
                                    ? AppColors.background
                                    : const Color(0xFFF5F7FB),
                                borderRadius: BorderRadius.circular(13),
                              ),
                              child: Icon(
                                report.$4,
                                size: 21,
                                color: selected == report.$1
                                    ? Colors.white
                                    : const Color(0xFF697C9B),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    report.$2,
                                    style: const TextStyle(
                                      color: AppColors.ink,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    report.$3,
                                    style: const TextStyle(
                                      color: AppColors.muted,
                                      fontSize: 12,
                                      height: 1.4,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              selected == report.$1
                                  ? Icons.check_circle_rounded
                                  : Icons.chevron_right_rounded,
                              size: 20,
                              color: selected == report.$1
                                  ? AppColors.background
                                  : const Color(0xFFB4C0D2),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ],
          ),
        ),
      ),
    );
    if (context.mounted && result != null && result != current) {
      onSelected(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = current == ReportView.insightDetail
        ? 'Detail Insight'
        : _reports.firstWhere((report) => report.$1 == current).$2;
    return Tooltip(
      message: 'Pilih laporan',
      child: Material(
        color: onDark
            ? Colors.white.withValues(alpha: .09)
            : const Color(0xFFF1F5FC),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: () => _open(context),
          borderRadius: BorderRadius.circular(14),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: onDark ? Colors.white : AppColors.background,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.expand_more_rounded,
                    size: 21,
                    color: onDark
                        ? const Color(0xFFCDDAFF)
                        : AppColors.background,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
