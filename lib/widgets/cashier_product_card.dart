import 'package:flutter/material.dart';

import '../colors.dart';
import '../products.dart';

class CashierProductCard extends StatelessWidget {
  const CashierProductCard({
    super.key,
    required this.product,
    required this.quantity,
    required this.onAdd,
    required this.onRemove,
  });

  final Product product;
  final int quantity;
  final VoidCallback onAdd;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final soldOut = product.stock <= 0;
    final selected = quantity > 0;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: selected ? AppColors.background : const Color(0xFFE5EBF4),
          width: selected ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: AspectRatio(
                aspectRatio: 1.35,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ProductPhoto(product: product),
                    if (selected)
                      Positioned(
                        top: 7,
                        right: 7,
                        child: Semantics(
                          label: '$quantity dipilih',
                          child: Container(
                            padding: const EdgeInsets.all(5),
                            decoration: const BoxDecoration(
                              color: AppColors.background,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.check_rounded,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                      ),
                    if (product.favorite)
                      Positioned(
                        top: 7,
                        left: 7,
                        child: Tooltip(
                          message: 'Produk favorit',
                          child: Container(
                            padding: const EdgeInsets.all(5),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.star_rounded,
                              color: Color(0xFFB45309),
                              size: 14,
                            ),
                          ),
                        ),
                      ),
                    if (soldOut) ...[
                      const ColoredBox(color: Color(0x80FFFFFF)),
                      Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'HABIS',
                            style: TextStyle(
                              color: Color(0xFFEF4444),
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  product.category.isEmpty ? 'Produk' : product.category,
                  style: const TextStyle(color: AppColors.muted, fontSize: 10),
                ),
                const SizedBox(height: 5),
                Text(
                  product.name,
                  style: const TextStyle(
                    color: AppColors.ink,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 5),
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 5,
                  runSpacing: 4,
                  children: [
                    Text(
                      productRupiah(product.price),
                      style: TextStyle(
                        color: soldOut ? AppColors.muted : AppColors.background,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      'Stok ${product.stock}',
                      style: TextStyle(
                        color: soldOut
                            ? const Color(0xFFC2414B)
                            : product.stockStatus == ProductStockStatus.low
                            ? const Color(0xFFB45309)
                            : AppColors.muted,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (selected)
                  Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: AppColors.softBlue,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        _quantityButton(
                          icon: Icons.remove_rounded,
                          tooltip: 'Kurangi ${product.name}',
                          onPressed: onRemove,
                          filled: false,
                        ),
                        Expanded(
                          child: Text(
                            '$quantity',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: AppColors.ink,
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        _quantityButton(
                          icon: Icons.add_rounded,
                          tooltip: 'Tambah ${product.name}',
                          onPressed: quantity < product.stock ? onAdd : null,
                          filled: true,
                        ),
                      ],
                    ),
                  )
                else
                  FilledButton.icon(
                    onPressed: soldOut ? null : onAdd,
                    icon: Icon(
                      soldOut ? Icons.block_rounded : Icons.add_rounded,
                      size: 16,
                    ),
                    label: Text(soldOut ? 'Habis' : 'Tambah'),
                    // Label habis tetap terlihat meski tombol dinonaktifkan.
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.background,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: const Color(0xFFF6F8FA),
                      disabledForegroundColor: AppColors.muted,
                      minimumSize: const Size.fromHeight(44),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 10,
                      ),
                      textStyle: Theme.of(context).textTheme.labelLarge
                          ?.copyWith(fontSize: 11, fontWeight: FontWeight.w700),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _quantityButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback? onPressed,
    required bool filled,
  }) => IconButton(
    tooltip: tooltip,
    onPressed: onPressed,
    icon: Icon(icon, size: 16),
    style: IconButton.styleFrom(
      padding: EdgeInsets.zero,
      minimumSize: const Size(36, 40),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      backgroundColor: filled ? const Color(0xFF233E91) : Colors.white,
      foregroundColor: filled ? Colors.white : AppColors.background,
      disabledBackgroundColor: const Color(0xFFE8EEF6),
      disabledForegroundColor: const Color(0xFFB8C3D2),
      side: filled
          ? BorderSide.none
          : const BorderSide(color: Color(0xFFE5EBF4)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
    ),
  );
}
