import 'package:flutter/material.dart';

import '../colors.dart';

// Semua aksi unduh/ekspor memakai bentuk yang sama, termasuk saat teks diperbesar.
// Widget hanya mengatur tampilan; pembuatan file ditangani callback halaman.
class NalaraDownloadButton extends StatelessWidget {
  const NalaraDownloadButton({
    super.key,
    required this.label,
    required this.onPressed,
  });
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => FilledButton(
    onPressed: onPressed,
    style: FilledButton.styleFrom(
      backgroundColor: AppColors.background,
      foregroundColor: Colors.white,
      minimumSize: const Size.fromHeight(48),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    child: Row(
      children: [
        const Icon(Icons.download_outlined, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    ),
  );
}
