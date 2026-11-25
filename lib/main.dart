// Mengimpor Flutter dan widget utama aplikasi.
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'app.dart';

// Titik awal aplikasi; seluruh pengaturan tampilan berada di app.dart.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp();
    runApp(const NalaraApp());
  } catch (_) {
    runApp(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Firebase tidak dapat dimulai. Periksa konfigurasi aplikasi dan koneksi.',
                  ),
                  FilledButton(onPressed: main, child: const Text('Coba lagi')),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
