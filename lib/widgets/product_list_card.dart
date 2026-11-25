import 'package:flutter/material.dart';

import '../colors.dart';
import '../products.dart';

// Foto, harga, dan kondisi stok dibaca dalam urutan yang sama di setiap kartu.
class ProductListCard extends StatelessWidget {
  const ProductListCard({
    super.key,
    required this.product,
    required this.onTap,
  });

  final Product product;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final (label, color, background, icon) = switch (product.stockStatus) {
      ProductStockStatus.safe => (
        'Stok aman',
        const Color(0xFF087F6D),
        const Color(0xFFECF8F3),
        Icons.check_circle_outline_rounded,
      ),
      ProductStockStatus.low => (
        'Menipis',
        const Color(0xFFB45309),
        const Color(0xFFFFF7E8),
        Icons.warning_amber_rounded,
      ),
      ProductStockStatus.empty => (
        'Habis',
        const Color(0xFFC2414B),
        const Color(0xFFFFF0F1),
        Icons.remove_circle_outline_rounded,
      ),
    };
    final information = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 4,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              product.category.isEmpty ? 'Tanpa kategori' : product.category,
              style: const TextStyle(
                color: AppColors.muted,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (!product.active)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F3F7),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: const Text(
                  'Nonaktif',
                  style: TextStyle(
                    color: AppColors.muted,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 5),
        Text(
          product.name,
          style: const TextStyle(
            color: AppColors.ink,
            fontSize: 16,
            fontWeight: FontWeight.w700,
            height: 1.35,
          ),
        ),
        const SizedBox(height: 9),
        Text(
          productRupiah(product.price),
          style: const TextStyle(
            color: AppColors.background,
            fontSize: 18,
            fontWeight: FontWeight.w800,
            letterSpacing: -.3,
          ),
        ),
      ],
    );
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: const BorderSide(color: Color(0xFFE5EBF4)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final stacked =
                      constraints.maxWidth < 250 ||
                      MediaQuery.textScalerOf(context).scale(14) > 21;
                  final photo = ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: SizedBox(
                      width: stacked ? double.infinity : 84,
                      height: stacked ? 130 : 90,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          ProductPhoto(product: product),
                          if (product.favorite)
                            Positioned(
                              top: 6,
                              right: 6,
                              child: Tooltip(
                                message: 'Produk favorit',
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(7),
                                  ),
                                  child: const Icon(
                                    Icons.star_rounded,
                                    size: 14,
                                    color: Color(0xFFB45309),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                  return stacked
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            photo,
                            const SizedBox(height: 14),
                            information,
                          ],
                        )
                      : Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            photo,
                            const SizedBox(width: 14),
                            Expanded(child: information),
                          ],
                        );
                },
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(
                color: Color(0xFFFBFCFE),
                border: Border(top: BorderSide(color: Color(0xFFEDF1F7))),
              ),
              child: Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 10,
                runSpacing: 10,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.layers_outlined,
                        size: 16,
                        color: AppColors.muted,
                      ),
                      const SizedBox(width: 7),
                      Flexible(
                        child: Text.rich(
                          TextSpan(
                            text: 'Stok ',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.muted,
                            ),
                            children: [
                              TextSpan(
                                text: '${product.stock}',
                                style: const TextStyle(
                                  color: AppColors.ink,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: background,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(icon, size: 14, color: color),
                        const SizedBox(width: 5),
                        Flexible(
                          child: Text(
                            label,
                            style: TextStyle(
                              color: color,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
