import 'package:flutter/material.dart';

// Membagi elemen menjadi dua kolom hanya ketika lebarnya cukup untuk tetap terbaca.
// Wrap menjaga tinggi setiap elemen fleksibel, termasuk saat ukuran teks diperbesar.
class ResponsiveColumns extends StatelessWidget {
  const ResponsiveColumns({super.key, required this.children, this.gap = 16});

  final List<Widget> children;
  final double gap;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final largeText = MediaQuery.textScalerOf(context).scale(16) / 16;
        final twoColumns = constraints.maxWidth >= 600 * largeText;
        final width = twoColumns
            ? (constraints.maxWidth - gap) / 2
            : constraints.maxWidth;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final child in children) SizedBox(width: width, child: child),
          ],
        );
      },
    );
  }
}
