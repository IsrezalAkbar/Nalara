import 'package:flutter/material.dart';

import '../colors.dart';
import '../products.dart';

class CashierCartItem extends StatelessWidget {
  const CashierCartItem({
    super.key,
    required this.product,
    required this.quantity,
    required this.onAdd,
    required this.onRemove,
  });

  final Product product;
  final int quantity;
  final VoidCallback? onAdd;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) => Container(
    clipBehavior: Clip.antiAlias,
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: const Color(0xFFE5EBF4)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: SizedBox(
                  width: 68,
                  height: 72,
                  child: ProductPhoto(product: product),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.category.isEmpty ? 'Produk' : product.category,
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 10,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      product.name,
                      style: const TextStyle(
                        color: AppColors.ink,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${productRupiah(product.price)} / item',
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
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
            spacing: 16,
            runSpacing: 12,
            children: [
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: AppColors.softBlue,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _button(
                      icon: Icons.remove_rounded,
                      tooltip: 'Kurangi ${product.name}',
                      onPressed: onRemove,
                      filled: false,
                    ),
                    Flexible(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        child: Text(
                          '$quantity',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: AppColors.background,
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                    _button(
                      icon: Icons.add_rounded,
                      tooltip: 'Tambah ${product.name}',
                      onPressed: onAdd,
                      filled: true,
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    'Subtotal',
                    style: TextStyle(color: AppColors.muted, fontSize: 10),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    productRupiah(product.price * quantity),
                    style: const TextStyle(
                      color: AppColors.background,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _button({
    required IconData icon,
    required String tooltip,
    required VoidCallback? onPressed,
    required bool filled,
  }) => IconButton(
    tooltip: tooltip,
    onPressed: onPressed,
    icon: Icon(icon, size: 18),
    style: IconButton.styleFrom(
      minimumSize: const Size(40, 40),
      padding: EdgeInsets.zero,
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      foregroundColor: filled ? Colors.white : AppColors.background,
      backgroundColor: filled ? AppColors.background : Colors.white,
      disabledForegroundColor: AppColors.muted,
      disabledBackgroundColor: const Color(0xFFE6ECF6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ),
  );
}
