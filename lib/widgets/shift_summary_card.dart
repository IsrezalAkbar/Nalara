import 'package:flutter/material.dart';

import '../colors.dart';
import '../products.dart' show productRupiah;
import '../shifts.dart';
import '../transactions.dart';
import 'profile_components.dart';

class ShiftSummaryCard extends StatelessWidget {
  const ShiftSummaryCard({super.key, required this.shift});
  final CashierShift shift;

  @override
  Widget build(BuildContext context) {
    final report = ShiftSummary(shift, TransactionHistory.instance.items);
    final difference = report.difference;
    final balanced = difference == null || difference == 0;
    final statusColor = shift.active || balanced
        ? const Color(0xFF087F6D)
        : const Color(0xFFB45309);
    return ProfileCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircleAvatar(
                          backgroundColor: AppColors.softBlue,
                          foregroundColor: AppColors.background,
                          radius: 19,
                          child: Icon(Icons.person_outline_rounded, size: 21),
                        ),
                        const SizedBox(width: 10),
                        Flexible(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'PETUGAS KASIR',
                                style: TextStyle(
                                  fontSize: 9,
                                  letterSpacing: 1,
                                  color: AppColors.muted,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                shift.cashier,
                                style: const TextStyle(
                                  color: AppColors.ink,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: .08),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            shift.active
                                ? Icons.circle
                                : Icons.check_circle_rounded,
                            size: shift.active ? 7 : 13,
                            color: statusColor,
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              shift.active ? 'SHIFT AKTIF' : 'SELESAI',
                              style: TextStyle(
                                color: statusColor,
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                letterSpacing: .4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (shift.active)
                  _ShiftTime(label: 'Mulai', date: shift.startedAt)
                else
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        _ShiftTime(label: 'Mulai', date: shift.startedAt),
                        const SizedBox(height: 10),
                        _ShiftTime(label: 'Selesai', date: shift.endedAt!),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: shift.active
                    ? [const Color(0xFF294B9C), const Color(0xFF1C3376)]
                    : [const Color(0xFFEFF6FF), const Color(0xFFF5F8FF)],
              ),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Total penjualan',
                        style: TextStyle(
                          color: shift.active
                              ? const Color(0xFFCEDBFA)
                              : AppColors.muted,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    if (!shift.active)
                      const Icon(
                        Icons.receipt_long_outlined,
                        size: 20,
                        color: AppColors.logoBlue,
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  productRupiah(report.revenue),
                  style: TextStyle(
                    color: shift.active ? Colors.white : AppColors.background,
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -.8,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${report.sales.length} transaksi tercatat',
                  style: TextStyle(
                    color: shift.active
                        ? const Color(0xFFCEDBFA)
                        : AppColors.muted,
                    fontSize: 11,
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
                    final stacked =
                        constraints.maxWidth <
                        290 * MediaQuery.textScalerOf(context).scale(12) / 12;
                    final cash = _MethodAmount(
                      label: 'Tunai',
                      amount: report.cashSales,
                      icon: Icons.payments_outlined,
                      color: const Color(0xFF087F6D),
                    );
                    final qris = _MethodAmount(
                      label: 'QRIS',
                      amount: report.qrisSales,
                      icon: Icons.qr_code_rounded,
                      color: const Color(0xFF7560B3),
                    );
                    return stacked
                        ? Column(
                            children: [cash, const SizedBox(height: 16), qris],
                          )
                        : Row(
                            children: [
                              Expanded(child: cash),
                              const SizedBox(width: 20),
                              Expanded(child: qris),
                            ],
                          );
                  },
                ),
                const Divider(height: 32, color: AppColors.border),
                _CashLine('Modal awal', productRupiah(shift.openingCash)),
                const SizedBox(height: 12),
                _CashLine(
                  'Kas seharusnya',
                  productRupiah(report.expectedCash),
                  bold: true,
                ),
                if (shift.countedCash != null) ...[
                  const SizedBox(height: 12),
                  _CashLine(
                    'Uang tunai aktual',
                    productRupiah(shift.countedCash!),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: .06),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          balanced
                              ? Icons.verified_outlined
                              : Icons.info_outline_rounded,
                          size: 19,
                          color: statusColor,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _CashLine(
                            'Selisih kas',
                            difference == 0
                                ? 'Sesuai'
                                : '${difference! > 0 ? 'Lebih' : 'Kurang'} ${productRupiah(difference.abs())}',
                            color: statusColor,
                            bold: true,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                if (shift.note.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.notes_rounded,
                          size: 17,
                          color: AppColors.muted,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Catatan: ${shift.note}',
                            style: const TextStyle(
                              color: AppColors.muted,
                              fontSize: 12,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ShiftTime extends StatelessWidget {
  const _ShiftTime({required this.label, required this.date});
  final String label;
  final DateTime date;
  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Icon(Icons.schedule_rounded, size: 14, color: AppColors.muted),
      const SizedBox(width: 7),
      Expanded(
        child: Text(
          '$label: ${transactionDate(date)} • ${transactionTime(date)}',
          style: const TextStyle(
            color: AppColors.muted,
            fontSize: 11,
            height: 1.4,
          ),
        ),
      ),
    ],
  );
}

class _MethodAmount extends StatelessWidget {
  const _MethodAmount({
    required this.label,
    required this.amount,
    required this.icon,
    required this.color,
  });
  final String label;
  final int amount;
  final IconData icon;
  final Color color;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(
        padding: const EdgeInsets.all(9),
        decoration: BoxDecoration(
          color: color.withValues(alpha: .07),
          borderRadius: BorderRadius.circular(11),
        ),
        child: Icon(icon, color: color, size: 19),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(color: AppColors.muted, fontSize: 11),
            ),
            const SizedBox(height: 4),
            Text(
              productRupiah(amount),
              style: const TextStyle(
                color: AppColors.ink,
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

class _CashLine extends StatelessWidget {
  const _CashLine(
    this.label,
    this.value, {
    this.bold = false,
    this.color = AppColors.background,
  });
  final String label, value;
  final bool bold;
  final Color color;
  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Expanded(
        child: Text(
          label,
          style: const TextStyle(color: AppColors.muted, fontSize: 12),
        ),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Text(
          value,
          textAlign: TextAlign.right,
          style: TextStyle(
            color: color,
            fontSize: 13,
            fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
          ),
        ),
      ),
    ],
  );
}
