// Timer mengatur durasi splash; import lain menyediakan UI dan halaman login.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../colors.dart';
import '../widgets/splash_loading.dart';
import '../widgets/splash_logo.dart';
import 'session_gate.dart';

// StatefulWidget diperlukan agar timer dapat dimulai dan dibatalkan.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  // Timer disimpan agar tidak tetap aktif setelah halaman ditutup.
  late final Timer _timer;

  @override
  void initState() {
    // Memulai hitungan tiga detik sekali saat splash dibuat.
    super.initState();
    _timer = Timer(const Duration(seconds: 3), () {
      if (!mounted) return;
      // Mengganti splash agar tombol kembali tidak membuka splash lagi.
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(builder: (context) => const SessionGate()),
      );
    });
  }

  @override
  void dispose() {
    // Membatalkan timer untuk mencegah navigasi dari halaman yang sudah ditutup.
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Tinggi minimum memberi ruang ketika ukuran teks diperbesar.
    final minimumHeight = 400 + MediaQuery.textScalerOf(context).scale(160);

    // Menyamakan bilah sistem dengan warna splash dan memakai ikon terang.
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: AppColors.background,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: AppColors.background,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        // Latar memenuhi seluruh layar dengan semburat warna sesuai referensi.
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
              colors: [
                AppColors.background,
                AppColors.splashAccent,
                AppColors.background,
              ],
              stops: [0, 0.65, 1],
            ),
          ),
          // Menghindari notch dan menyesuaikan layout dengan ruang layar tersedia.
          child: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                // Landscape tetap vertikal; logo dan jarak diringkas agar sesuai layar pendek.
                if (MediaQuery.orientationOf(context) ==
                    Orientation.landscape) {
                  return SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const SplashLogo(size: 64),
                                const SizedBox(height: 8),
                                SizedBox(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: const [
                                      Text(
                                        'Nalara',
                                        style: TextStyle(
                                          color: AppColors.white,
                                          fontSize: 32,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      SizedBox(height: 8),
                                      Text(
                                        'Kelola bisnis, pahami data,\nambil keputusan.',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: AppColors.tagline,
                                          fontSize: 16,
                                          height: 1.6,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            const SplashLoading(),
                          ],
                        ),
                      ),
                    ),
                  );
                }
                // Layar pendek dapat di-scroll tanpa memampatkan logo dan teks.
                final height = constraints.maxHeight < minimumHeight
                    ? minimumHeight
                    : constraints.maxHeight;

                // Tinggi intrinsik memungkinkan teks membesar tanpa overflow.
                return SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: height,
                      minWidth: constraints.maxWidth,
                    ),
                    child: IntrinsicHeight(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          children: [
                            // Spacer mengatur ruang kosong di atas kelompok identitas.
                            const Spacer(flex: 6),
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                // Logo, nama aplikasi, dan tagline dua baris.
                                SplashLogo(),
                                SizedBox(height: 36),
                                Text(
                                  'Nalara',
                                  style: TextStyle(
                                    color: AppColors.white,
                                    fontSize: 48,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Kelola bisnis, pahami data,\nambil keputusan.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: AppColors.tagline,
                                    fontSize: 16,
                                    height: 1.6,
                                  ),
                                ),
                              ],
                            ),
                            // Indikator loading berada dekat bagian bawah layar.
                            const Spacer(flex: 3),
                            const SplashLoading(),
                            const SizedBox(height: 90),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
