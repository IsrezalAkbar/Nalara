import 'package:flutter/material.dart';

import '../colors.dart';
import '../products.dart';

class HomeNotificationsSheet extends StatelessWidget {
  const HomeNotificationsSheet({super.key});

  @override
  Widget build(BuildContext context) => SafeArea(
    top: false,
    child: Column(
      children: [
        const SizedBox(height: 10),
        Container(
          width: 36,
          height: 4,
          decoration: BoxDecoration(
            color: AppColors.border,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 12, 16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(11),
                decoration: BoxDecoration(
                  color: AppColors.softBlue,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.notifications_none_rounded,
                  color: AppColors.background,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Notifikasi',
                  style: TextStyle(
                    color: AppColors.ink,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Tutup',
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close_rounded, color: AppColors.muted),
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: AppColors.border),
        Flexible(
          child: ListenableBuilder(
            listenable: ProductCatalog.instance,
            builder: (context, _) {
              final products =
                  ProductCatalog.instance.items
                      .where(
                        (product) =>
                            product.active &&
                            product.stock <= product.minimumStock,
                      )
                      .toList()
                    ..sort((a, b) {
                      final stockOrder = a.stock.compareTo(b.stock);
                      return stockOrder == 0
                          ? a.name.compareTo(b.name)
                          : stockOrder;
                    });
              if (products.isEmpty) return const _NoStockAlerts();
              final emptyCount = products
                  .where((product) => product.stock <= 0)
                  .length;
              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                itemCount: products.length + 1,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            '${products.length} produk perlu perhatian',
                            style: const TextStyle(
                              color: AppColors.ink,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Pantau persediaan agar penjualan tetap berjalan lancar.',
                            style: TextStyle(
                              color: AppColors.muted,
                              fontSize: 13,
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 14),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              if (emptyCount > 0)
                                _StockBadge(
                                  label: '$emptyCount stok habis',
                                  empty: true,
                                ),
                              if (products.length > emptyCount)
                                _StockBadge(
                                  label:
                                      '${products.length - emptyCount} stok menipis',
                                  empty: false,
                                ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }
                  return _StockAlertCard(product: products[index - 1]);
                },
              );
            },
          ),
        ),
      ],
    ),
  );
}

class _StockAlertCard extends StatelessWidget {
  const _StockAlertCard({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    final empty = product.stock <= 0;
    final color = empty ? const Color(0xFFBE3946) : const Color(0xFF996315);
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.of(context).pop(product),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: empty
                      ? const Color(0xFFFFEEF0)
                      : const Color(0xFFFFF7E7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  empty
                      ? Icons.inventory_2_outlined
                      : Icons.warning_amber_rounded,
                  color: color,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: const TextStyle(
                        color: AppColors.ink,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _StockBadge(
                      label: empty ? 'Stok habis' : 'Stok menipis',
                      empty: empty,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Sisa ${product.stock} • Minimum ${product.minimumStock}',
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 12,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      empty
                          ? 'Isi kembali stok agar produk bisa dijual.'
                          : 'Siapkan stok tambahan sebelum habis.',
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 12,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Lihat produk',
                      style: TextStyle(
                        color: AppColors.background,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.muted,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StockBadge extends StatelessWidget {
  const _StockBadge({required this.label, required this.empty});

  final String label;
  final bool empty;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
    decoration: BoxDecoration(
      color: empty ? const Color(0xFFFFEEF0) : const Color(0xFFFFF7E7),
      borderRadius: BorderRadius.circular(7),
    ),
    child: Text(
      label,
      style: TextStyle(
        color: empty ? const Color(0xFFBE3946) : const Color(0xFF996315),
        fontSize: 11,
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}

class _NoStockAlerts extends StatelessWidget {
  const _NoStockAlerts();

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 36),
    children: [
      const Center(
        child: CircleAvatar(
          radius: 38,
          backgroundColor: Color(0xFFE7F6EF),
          child: Icon(
            Icons.check_circle_outline_rounded,
            color: Color(0xFF168166),
            size: 38,
          ),
        ),
      ),
      const SizedBox(height: 20),
      const Text(
        'Semua stok aman',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: AppColors.ink,
          fontSize: 20,
          fontWeight: FontWeight.w800,
        ),
      ),
      const SizedBox(height: 10),
      const Text(
        'Tidak ada stok menipis.',
        textAlign: TextAlign.center,
        style: TextStyle(color: AppColors.muted, fontSize: 14),
      ),
      const SizedBox(height: 6),
      const Text(
        'Peringatan akan muncul di sini ketika stok produk mencapai batas minimum.',
        textAlign: TextAlign.center,
        style: TextStyle(color: AppColors.muted, fontSize: 13, height: 1.6),
      ),
    ],
  );
}
