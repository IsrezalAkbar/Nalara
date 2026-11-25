import 'package:flutter/material.dart';

import '../colors.dart';
import '../products.dart' show productRupiah;
import '../shifts.dart';
import '../transactions.dart';
import 'profile_components.dart';

class ShiftHistoryOverview extends StatelessWidget {
  const ShiftHistoryOverview({super.key, required this.shifts});

  final List<CashierShift> shifts;

  @override
  Widget build(BuildContext context) {
    final reports = shifts
        .map((shift) => ShiftSummary(shift, TransactionHistory.instance.items))
        .toList();
    final revenue = reports.fold(0, (sum, report) => sum + report.revenue);
    final sales = reports.fold(0, (sum, report) => sum + report.sales.length);
    final discrepancies = reports
        .where((report) => report.difference != null && report.difference != 0)
        .length;
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.background, Color(0xFF3059B7)],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Row(
            children: [
              Icon(Icons.bar_chart_rounded, color: Color(0xFFD9E6FF), size: 20),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'PENJUALAN SHIFT SELESAI',
                  style: TextStyle(
                    color: Color(0xFFD9E6FF),
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.1,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            productRupiah(revenue),
            key: const ValueKey('history-total-revenue'),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 30,
              fontWeight: FontWeight.w800,
              letterSpacing: -.8,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Dari shift yang ditutup pada tanggal pilihan.',
            style: TextStyle(
              color: Color(0xFFD9E6FF),
              fontSize: 12,
              height: 1.5,
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Divider(height: 1, color: Color(0xFF5472B5)),
          ),
          Wrap(
            spacing: 20,
            runSpacing: 12,
            children: [
              _OverviewMetric(
                icon: Icons.task_alt_rounded,
                text: '${shifts.length} shift selesai',
              ),
              _OverviewMetric(
                icon: Icons.receipt_long_outlined,
                text: '$sales transaksi',
              ),
              if (discrepancies > 0)
                _OverviewMetric(
                  icon: Icons.info_outline_rounded,
                  text: '$discrepancies shift berselisih',
                  color: const Color(0xFFFFDF9B),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _OverviewMetric extends StatelessWidget {
  const _OverviewMetric({
    required this.icon,
    required this.text,
    this.color = Colors.white,
  });
  final IconData icon;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 16, color: color),
      const SizedBox(width: 7),
      Flexible(
        child: Text(
          text,
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    ],
  );
}

class ShiftHistoryEmpty extends StatelessWidget {
  const ShiftHistoryEmpty({super.key, required this.activity});
  final bool activity;

  @override
  Widget build(BuildContext context) => ProfileCard(
    padding: const EdgeInsets.all(26),
    child: Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.softBlue,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Icon(
            activity ? Icons.history_rounded : Icons.event_available_outlined,
            color: AppColors.background,
            size: 28,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          activity ? 'Belum ada aktivitas' : 'Belum ada shift selesai',
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.ink,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          activity
              ? 'Tidak ada aktivitas shift pada tanggal ini.'
              : 'Belum ada shift yang ditutup pada tanggal ini.',
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.muted,
            fontSize: 12,
            height: 1.6,
          ),
        ),
        if (!activity) ...[
          const SizedBox(height: 6),
          const Text(
            'Pilih tanggal lain untuk melihat riwayat.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.muted, fontSize: 12, height: 1.6),
          ),
        ],
      ],
    ),
  );
}

class ShiftHistoryEvent extends StatelessWidget {
  const ShiftHistoryEvent({
    super.key,
    required this.shift,
    required this.time,
    required this.opening,
    required this.last,
  });
  final CashierShift shift;
  final DateTime time;
  final bool opening, last;

  @override
  Widget build(BuildContext context) {
    final color = opening ? AppColors.background : const Color(0xFF087F6D);
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 36,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: .08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    opening ? Icons.play_arrow_rounded : Icons.check_rounded,
                    size: 20,
                    color: color,
                  ),
                ),
                if (!last)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      color: AppColors.border,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: last ? 0 : 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 12,
                    runSpacing: 6,
                    children: [
                      Text(
                        opening ? 'Shift dimulai' : 'Shift ditutup',
                        style: const TextStyle(
                          color: AppColors.ink,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(7),
                        ),
                        child: Text(
                          transactionTime(time),
                          style: const TextStyle(
                            color: AppColors.muted,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Petugas: ${shift.cashier}',
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 12,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: .04),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          opening ? 'Modal awal' : 'Uang tunai aktual',
                          style: const TextStyle(
                            color: AppColors.muted,
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          productRupiah(
                            opening
                                ? shift.openingCash
                                : shift.countedCash ?? 0,
                          ),
                          style: TextStyle(
                            color: color,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
