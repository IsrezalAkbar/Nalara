// Mengimpor widget Flutter dan palet warna bersama.
import 'package:flutter/material.dart';

import '../colors.dart';

// Indikator visual loading; tidak menjalankan permintaan data atau backend.
class SplashLoading extends StatelessWidget {
  const SplashLoading({super.key});

  @override
  Widget build(BuildContext context) {
    // Menyusun titik dan teks secara vertikal dengan tinggi sesuai isi.
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Membuat tiga titik; titik pertama lebih terang sesuai desain.
        Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(
            3,
            (index) => Container(
              width: 6,
              height: 6,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: index == 0 ? AppColors.white : AppColors.loadingDot,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Teks status loading di bawah indikator.
        const Text(
          'MEMUAT DATA',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.loadingText,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
