import 'package:flutter/material.dart';

import '../colors.dart';
import '../products.dart' show productRupiah;
import '../transactions.dart';

class TransactionSummaryCard extends StatelessWidget {
  const TransactionSummaryCard({
    super.key,
    required this.entries,
    required this.filtered,
  });

  final List<SaleTransaction> entries;
  final bool filtered;

  @override
  Widget build(BuildContext context) {
    final total = entries.fold(0, (sum, entry) => sum + entry.total);
    final quantity = entries.fold(0, (sum, entry) => sum + entry.quantity);
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.background, Color(0xFF3658AD)],
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: AppColors.background.withValues(alpha: 0.14),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(
                Icons.account_balance_wallet_outlined,
                size: 20,
                color: Color(0xFFCBDAFF),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  filtered ? 'Total sesuai filter' : 'Total seluruh transaksi',
                  style: const TextStyle(
                    color: Color(0xFFDFE8FF),
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            productRupiah(total),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 30,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.8,
            ),
          ),
          const SizedBox(height: 20),
          const Divider(color: Color(0xFF627DC1), height: 1),
          const SizedBox(height: 16),
          Wrap(
            spacing: 24,
            runSpacing: 12,
            children: [
              _metric(
                Icons.receipt_long_outlined,
                '${entries.length} transaksi',
              ),
              _metric(Icons.shopping_bag_outlined, '$quantity item terjual'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _metric(IconData icon, String value) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, color: const Color(0xFFCBDAFF), size: 16),
      const SizedBox(width: 8),
      Flexible(
        child: Text(
          value,
          style: const TextStyle(color: Colors.white, fontSize: 12),
        ),
      ),
    ],
  );
}

class TransactionHistoryCard extends StatelessWidget {
  const TransactionHistoryCard({
    super.key,
    required this.transaction,
    required this.onTap,
  });

  final SaleTransaction transaction;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final (icon, color, background) = switch (transaction.method) {
      'Tunai' => (
        Icons.payments_outlined,
        const Color(0xFF0F766E),
        const Color(0xFFEAF7F2),
      ),
      'QRIS' => (
        Icons.qr_code_rounded,
        const Color(0xFF6D4DC0),
        const Color(0xFFF2EEFC),
      ),
      _ => (
        Icons.account_balance_outlined,
        AppColors.background,
        AppColors.softBlue,
      ),
    };
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(11),
                    decoration: BoxDecoration(
                      color: background,
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Icon(icon, color: color, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '#${transaction.id}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.ink,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          '${transactionTime(transaction.date)}  •  ${transaction.quantity} item',
                          style: const TextStyle(
                            color: AppColors.muted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.muted,
                    size: 20,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              if (transaction.items.isNotEmpty) ...[
                Text(
                  transaction.items.map((item) => item.name).join(', '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppColors.muted, fontSize: 12),
                ),
                const SizedBox(height: 14),
              ],
              const Divider(height: 1, color: Color(0xFFEDF1F7)),
              const SizedBox(height: 14),
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 12,
                runSpacing: 12,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: background,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      transaction.method,
                      style: TextStyle(
                        color: color,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Text(
                    productRupiah(transaction.total),
                    style: const TextStyle(
                      color: AppColors.ink,
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.4,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class TransactionHistoryEmpty extends StatelessWidget {
  const TransactionHistoryEmpty({
    super.key,
    required this.filtered,
    required this.onReset,
  });

  final bool filtered;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 36),
    child: Column(
      children: [
        CircleAvatar(
          radius: 36,
          backgroundColor: AppColors.softBlue,
          child: Icon(
            filtered ? Icons.search_off_rounded : Icons.receipt_long_outlined,
            size: 32,
            color: AppColors.logoBlue,
          ),
        ),
        const SizedBox(height: 18),
        Text(
          filtered ? 'Tidak ada transaksi yang sesuai' : 'Belum ada transaksi',
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.ink,
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          filtered
              ? 'Coba kata kunci lain atau ubah filter untuk menemukan transaksi Anda.'
              : 'Transaksi yang selesai di kasir akan muncul di sini. Semua catatan penjualan tersimpan rapi.',
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.muted,
            fontSize: 13,
            height: 1.6,
          ),
        ),
        if (filtered) ...[
          const SizedBox(height: 18),
          OutlinedButton.icon(
            onPressed: onReset,
            icon: const Icon(Icons.restart_alt_rounded, size: 18),
            label: const Text('Reset pencarian & filter'),
          ),
        ],
      ],
    ),
  );
}
