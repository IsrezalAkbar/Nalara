import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../colors.dart';
import '../products.dart';
import '../rupiah_input.dart';

class CashAmountInput extends StatelessWidget {
  const CashAmountInput({
    super.key,
    required this.controller,
    required this.total,
    required this.onChanged,
    required this.onAmountSelected,
  });

  final TextEditingController controller;
  final int total;
  final VoidCallback onChanged;
  final ValueChanged<int> onAmountSelected;

  @override
  Widget build(BuildContext context) {
    final cash = int.tryParse(controller.text.replaceAll('.', '')) ?? 0;
    final entered = controller.text.isNotEmpty;
    final sufficient = cash >= total;
    final color = sufficient
        ? const Color(0xFF0D9488)
        : const Color(0xFFD97706);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFEDF1F7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Uang Diterima',
                  style: TextStyle(
                    color: AppColors.ink,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              TextButton(
                onPressed: () => onAmountSelected(total),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.logoBlue,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                ),
                child: const Text(
                  'Uang Pas',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          TextField(
            key: const ValueKey('cash-received'),
            controller: controller,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.done,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              RupiahInputFormatter(),
            ],
            onChanged: (_) => onChanged(),
            style: const TextStyle(
              color: AppColors.ink,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
            decoration: InputDecoration(
              hintText: '0',
              hintStyle: const TextStyle(color: Color(0xFFB0BDCF)),
              prefixIcon: const Padding(
                padding: EdgeInsets.only(left: 16, right: 10),
                child: Text(
                  'Rp',
                  style: TextStyle(
                    color: AppColors.muted,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              prefixIconConstraints: const BoxConstraints(minWidth: 44),
              suffixIcon: controller.text.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Hapus nominal',
                      onPressed: () {
                        controller.clear();
                        onChanged();
                      },
                      icon: const Icon(
                        Icons.close_rounded,
                        size: 18,
                        color: AppColors.muted,
                      ),
                    ),
              filled: true,
              fillColor: const Color(0xFFF7F9FC),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFFE2EAF6)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(
                  color: AppColors.logoBlue,
                  width: 1.5,
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Pilih nominal untuk mengisi uang diterima.',
            style: TextStyle(color: AppColors.muted, fontSize: 11),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final amount in [
                1000,
                2000,
                5000,
                10000,
                20000,
                50000,
                100000,
              ])
                ChoiceChip(
                  key: ValueKey('cash-$amount'),
                  label: Text(productRupiah(amount)),
                  selected: entered && cash == amount,
                  onSelected: (_) => onAmountSelected(amount),
                  showCheckmark: false,
                  selectedColor: AppColors.softBlue,
                  backgroundColor: Colors.white,
                  side: BorderSide(
                    color: entered && cash == amount
                        ? AppColors.logoBlue
                        : const Color(0xFFE5EBF4),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 7,
                  ),
                  labelStyle: TextStyle(
                    color: entered && cash == amount
                        ? AppColors.background
                        : AppColors.muted,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: !entered
                  ? const Color(0xFFF7F9FC)
                  : sufficient
                  ? const Color(0xFFECFDF5)
                  : const Color(0xFFFFFBEB),
              borderRadius: BorderRadius.circular(13),
            ),
            child: !entered
                ? const Text(
                    'Masukkan jumlah uang yang diterima dari pelanggan.',
                    style: TextStyle(color: AppColors.muted, fontSize: 12),
                  )
                : Row(
                    children: [
                      Icon(
                        sufficient
                            ? Icons.check_circle_outline_rounded
                            : Icons.info_outline_rounded,
                        size: 18,
                        color: color,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          sufficient ? 'Kembalian' : 'Uang kurang',
                          style: TextStyle(
                            color: color,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          productRupiah((cash - total).abs()),
                          key: const ValueKey('cash-difference'),
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            color: color,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
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
}
