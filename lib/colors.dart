// Color berasal dari Flutter sehingga warna bisa dipakai langsung oleh widget.
import 'package:flutter/material.dart';

// Kumpulan warna bersama agar tampilan antarhalaman konsisten.
class AppColors {
  // Konstruktor privat: kelas ini hanya menyimpan konstanta, bukan objek.
  AppColors._();

  // Warna utama dan logo sesuai referensi desain.
  static const background = Color(0xFF1E3A8A);
  static const splashAccent = Color(0xFF303181);
  static const logoBlue = Color(0xFF3B82F6);
  static const white = Color(0xFFFFFFFF);
  // Warna teks dan indikator pada splash screen.
  static const tagline = Color(0xFFB0B8DD);
  static const loadingText = Color(0xFF7787B8);
  static const loadingDot = Color(0xFF8293C5);
  // Warna latar, teks, dan garis pembatas halaman login serta home.
  static const surface = Color(0xFFF7FAFC);
  static const ink = Color(0xFF111827);
  static const muted = Color(0xFF71829E);
  static const border = Color(0xFFE2E8F0);
  // Warna status bisnis dan latar ikon pada beranda.
  static const green = Color(0xFF10B981);
  static const orange = Color(0xFFF59E0B);
  static const softBlue = Color(0xFFEFF6FF);
}
