// Mengimpor komponen Material, warna, dan halaman pertama aplikasi.
import 'package:flutter/material.dart';

import 'colors.dart';
import 'screens/splash_screen.dart';

// Widget utama yang membungkus semua halaman Nalara.
class NalaraApp extends StatelessWidget {
  const NalaraApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Menentukan nama aplikasi, tema bersama, dan halaman splash.
    return MaterialApp(
      title: 'Nalara',
      debugShowCheckedModeBanner: false,
      // Tema ini digunakan oleh tombol dan komponen di seluruh halaman.
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.logoBlue),
        scaffoldBackgroundColor: AppColors.background,
        // Tombol utama/sekunder berbagi warna, tinggi minimum, dan radius di semua halaman.
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.background,
            foregroundColor: Colors.white,
            minimumSize: const Size(48, 48),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.background,
            side: const BorderSide(color: AppColors.border),
            minimumSize: const Size(48, 48),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(foregroundColor: AppColors.logoBlue),
        ),
      ),
      home: const SplashScreen(),
    );
  }
}
