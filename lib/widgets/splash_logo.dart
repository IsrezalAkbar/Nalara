// Mengimpor widget Flutter untuk menampilkan logo dari gambar lokal.
import 'package:flutter/material.dart';

// Logo yang sama digunakan pada splash dan halaman login dengan ukuran berbeda.
class SplashLogo extends StatelessWidget {
  const SplashLogo({super.key, this.size = 100});

  // Ukuran tetap menjaga layout stabil selama gambar dimuat.
  final double size;

  @override
  Widget build(BuildContext context) {
    // Menjelaskan identitas logo kepada pengguna pembaca layar.
    return Semantics(
      label: 'Logo Nalara',
      image: true,
      child: Image.asset(
        // Asset terdaftar di pubspec.yaml dan tersedia tanpa koneksi internet.
        'assets/images/nalara_logo.png',
        width: size,
        height: size,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
        excludeFromSemantics: true,
      ),
    );
  }
}
