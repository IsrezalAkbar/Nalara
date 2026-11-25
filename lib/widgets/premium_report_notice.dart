import 'package:flutter/material.dart';

import '../colors.dart';
import '../report_view.dart';

class PremiumReportNotice extends StatelessWidget {
  const PremiumReportNotice({
    super.key,
    required this.view,
    required this.onPackages,
    required this.onOverview,
  });

  final ReportView view;
  final VoidCallback onPackages, onOverview;

  @override
  Widget build(BuildContext context) {
    final feature = switch (view) {
      ReportView.sales => 'Laporan penjualan terperinci',
      ReportView.products => 'Analisis performa produk',
      ReportView.profit => 'Analisis laba kotor',
      _ => 'Insight dan rekomendasi bisnis',
    };
    return SafeArea(
      top: false,
      bottom: false,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.background, Color(0xFF284CAA)],
                ),
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(32),
                ),
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 560),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 30),
                    child: Column(
                      children: [
                        const _ReportIllustration(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFE8A8),
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.workspace_premium_rounded,
                                size: 16,
                                color: Color(0xFF825611),
                              ),
                              SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  'NALARA PREMIUM',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Color(0xFF825611),
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Kenali bisnismu\nlebih dalam.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            height: 1.2,
                            letterSpacing: -.6,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '$feature tersedia untuk pengguna Premium.',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Color(0xFFD3DFFA),
                            fontSize: 13,
                            height: 1.6,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: const Color(0xFFE8EEF7)),
                        ),
                        child: const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Buka gambaran yang lebih lengkap',
                              style: TextStyle(
                                color: AppColors.ink,
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            SizedBox(height: 20),
                            _Benefit(
                              icon: Icons.bar_chart_rounded,
                              title: 'Pahami penjualanmu',
                              description: 'Telusuri omzet dan tren penjualan per periode.',
                            ),
                            SizedBox(height: 18),
                            _Benefit(
                              icon: Icons.pie_chart_outline_rounded,
                              title: 'Kenali produk yang menguntungkan',
                              description: 'Lihat produk terlaris, modal, dan laba kotor.',
                            ),
                            SizedBox(height: 18),
                            _Benefit(
                              icon: Icons.auto_awesome_outlined,
                              title: 'Ambil langkah berikutnya',
                              description:
                                  'Pantau stok dan temukan rekomendasi bisnis.',
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEAF3FF),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Row(
                          children: [
                            Icon(
                              Icons.redeem_rounded,
                              color: AppColors.background,
                              size: 22,
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Coba Premium Demo selama 30 hari',
                                    style: TextStyle(
                                      color: AppColors.background,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'Tanpa pembayaran. Setelah berakhir, kembali ke Basic.',
                                    style: TextStyle(
                                      color: AppColors.muted,
                                      fontSize: 11,
                                      height: 1.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      FilledButton(
                        onPressed: onPackages,
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.background,
                          foregroundColor: Colors.white,
                          minimumSize: const Size.fromHeight(52),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 16,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Flexible(
                              child: Text(
                                'Lihat Paket',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            SizedBox(width: 10),
                            Icon(Icons.arrow_forward_rounded, size: 18),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: onOverview,
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.muted,
                          minimumSize: const Size.fromHeight(48),
                        ),
                        child: const Text(
                          'Kembali ke Analitik',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Benefit extends StatelessWidget {
  const _Benefit({
    required this.icon,
    required this.title,
    required this.description,
  });
  final IconData icon;
  final String title, description;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: AppColors.softBlue,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: AppColors.background, size: 20),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: AppColors.ink,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              description,
              style: const TextStyle(
                color: AppColors.muted,
                fontSize: 12,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

/// Decorative report artwork, without sample revenue or customer data.
class _ReportIllustration extends StatelessWidget {
  const _ReportIllustration();

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: SizedBox(
      height: 152,
      child: Center(
        child: SizedBox(
          width: 232,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 142,
                height: 142,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: .1),
                    width: 1,
                  ),
                ),
              ),
              Container(
                width: 112,
                height: 112,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: .05),
                ),
              ),
              Transform.rotate(
                angle: -.08,
                child: Container(
                  width: 108,
                  height: 119,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F8FF),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF102356).withValues(alpha: .2),
                        blurRadius: 24,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 38,
                        height: 5,
                        decoration: BoxDecoration(
                          color: const Color(0xFFCFDBEE),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 7),
                      Container(
                        width: 24,
                        height: 4,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE3EAF6),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const Spacer(),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          for (final height in [20.0, 30.0, 26.0, 44.0])
                            Container(
                              width: 13,
                              height: height,
                              decoration: BoxDecoration(
                                color: height == 44
                                    ? AppColors.logoBlue
                                    : const Color(0xFFBFD4FB),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                right: 38,
                bottom: 14,
                child: Container(
                  width: 47,
                  height: 47,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFE8A8),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(
                      color: const Color(0xFF294BA0),
                      width: 3,
                    ),
                  ),
                  child: const Icon(
                    Icons.lock_outline_rounded,
                    color: Color(0xFF825611),
                    size: 23,
                  ),
                ),
              ),
              const Positioned(
                left: 28,
                top: 27,
                child: Icon(
                  Icons.auto_awesome_rounded,
                  size: 17,
                  color: Color(0xFFBBD2FF),
                ),
              ),
              const Positioned(
                right: 31,
                top: 21,
                child: Icon(
                  Icons.add_rounded,
                  size: 14,
                  color: Color(0xFF7DA7F6),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
