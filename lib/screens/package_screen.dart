import 'package:flutter/material.dart';

import '../colors.dart';
import '../firebase_store.dart';
import '../products.dart';
import '../session.dart';
import '../widgets/profile_components.dart';
import '../widgets/responsive_columns.dart';
import 'reports_screen.dart';

class NalaraPackage {
  static const monthlyPrice = 30000;
  static final premium = StoreSession.instance.premium;
}

class PackageScreen extends StatefulWidget {
  const PackageScreen({super.key, this.onActivateDemo});
  final Future<void> Function()? onActivateDemo;

  @override
  State<PackageScreen> createState() => _PackageScreenState();
}

class _PackageScreenState extends State<PackageScreen> {
  bool _activating = false;
  String? _activationError;
  static const _blue = Color(0xFF233F91);
  static const _basicFeatures = [
    'Pencatatan produk dan harga modal',
    'Kasir digital dan struk transaksi',
    'Manajemen stok dan peringatan stok menipis',
    'Riwayat dan detail transaksi',
    'Ringkasan omzet, laba kotor, dan tren penjualan',
    'Ekspor laporan PDF dan CSV',
    'Pengaturan profil dan informasi toko',
  ];
  static const _premiumFeatures = [
    (
      icon: Icons.query_stats_rounded,
      title: 'Laporan penjualan terperinci',
      description:
          'Telusuri penjualan harian dan transaksi dalam satu periode.',
    ),
    (
      icon: Icons.account_balance_wallet_outlined,
      title: 'Analisis laba kotor',
      description:
          'Bandingkan omzet dengan modal produk saat transaksi dicatat.',
    ),
    (
      icon: Icons.emoji_events_outlined,
      title: 'Performa produk',
      description: 'Lihat peringkat produk berdasarkan jumlah yang terjual.',
    ),
    (
      icon: Icons.insights_rounded,
      title: 'Insight bisnis',
      description: 'Tinjau perubahan omzet antarperiode dan kebutuhan stok.',
    ),
  ];

  String _expiryLabel(DateTime expiry) {
    final local = expiry.toLocal();
    String two(int value) => value.toString().padLeft(2, '0');
    return '${two(local.day)}/${two(local.month)}/${local.year}, '
        '${two(local.hour)}:${two(local.minute)}';
  }

  Future<void> _activateDemo() async {
    if (_activating) return;
    setState(() {
      _activating = true;
      _activationError = null;
    });
    try {
      await (widget.onActivateDemo ??
          StoreSession.instance.activatePremiumDemo)();
    } catch (error) {
      if (mounted) {
        setState(() => _activationError = firebaseMessage(error));
      }
    } finally {
      if (mounted) setState(() => _activating = false);
    }
  }

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<bool>(
    valueListenable: NalaraPackage.premium,
    builder: (context, premium, _) => Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: const ProfileHeader(title: 'Paket Nalara'),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _hero(premium),
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1040),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _status(premium),
                        const SizedBox(height: 24),
                        ResponsiveColumns(
                          children: [
                            _premiumPlan(context, premium),
                            _basicPlan(premium),
                          ],
                        ),
                        const SizedBox(height: 28),
                        const Text(
                          'Tentang paket',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.ink,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _card(
                          children: [
                            _question(
                              'Apa saja yang termasuk Basic?',
                              'Semua fitur yang saat ini dapat Anda gunakan tetap '
                                  'tersedia di Basic, termasuk kasir, produk, stok, '
                                  'transaksi, ringkasan bisnis, dan ekspor laporan.',
                            ),
                            _question(
                              'Bagaimana cara mengaktifkan Premium demo?',
                              'Tekan Aktifkan Premium Demo untuk langsung '
                                  'mendapatkan akses selama 1 bulan (30 hari), '
                                  'tanpa pembayaran. Masa aktif tersimpan pada '
                                  'akun Anda dan tetap berjalan saat aplikasi ditutup.',
                            ),
                            _question(
                              'Apa yang terjadi setelah 30 hari?',
                              'Akun otomatis kembali ke Basic. Tidak ada '
                                  'perpanjangan atau tagihan otomatis. Anda dapat '
                                  'mengaktifkan Premium demo lagi setelah masa '
                                  'aktif sebelumnya berakhir.',
                            ),
                            _question(
                              'Apakah data toko tetap tersimpan?',
                              'Produk, stok, dan transaksi tetap terhubung ke akun '
                                  'yang sama. Anda tidak perlu membuat toko baru '
                                  'untuk memakai Premium.',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );

  Widget _hero(bool premium) => Container(
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        colors: [AppColors.background, Color(0xFF3578E4)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
    ),
    padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
    child: Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(22),
          ),
          child: const Icon(
            Icons.workspace_premium_rounded,
            size: 42,
            color: Color(0xFFFFD780),
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Nalara Premium',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          premium ? 'Kenali perkembangan bisnis Anda lebih dalam.' : 'Kelola bisnis dengan Basic.\nPahami lebih dalam dengan Premium.',
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Color(0xFFE0E7FF),
            fontSize: 15,
            height: 1.5,
          ),
        ),
      ],
    ),
  );

  Widget _status(bool premium) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: premium ? const Color(0xFFEFF5FF) : AppColors.softBlue,
      borderRadius: BorderRadius.circular(16),
    ),
    child: Row(
      children: [
        Icon(
          premium ? Icons.verified_rounded : Icons.storefront_outlined,
          color: premium ? _blue : AppColors.background,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                premium ? 'Paket Anda: Premium' : 'Paket Anda: Basic',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text(
                premium
                    ? 'Semua fitur Basic dan analitik lanjutan aktif.'
                    : NalaraPackage.premium.expiresAt != null
                    ? 'Masa Premium telah berakhir. Fitur Basic tetap tersedia.'
                    : 'Fitur operasional harian tersedia gratis.',
                style: const TextStyle(color: AppColors.muted, height: 1.4),
              ),
              if (premium && NalaraPackage.premium.expiresAt != null) ...[
                const SizedBox(height: 6),
                Text(
                  'Aktif sampai ${_expiryLabel(NalaraPackage.premium.expiresAt!)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    height: 1.4,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    ),
  );

  Widget _premiumPlan(BuildContext context, bool premium) => _card(
    highlighted: true,
    children: [
      _planHeading('Premium', premium ? 'AKTIF' : 'ANALITIK LANJUTAN', true),
      const SizedBox(height: 16),
      Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 6,
        children: [
          Text(
            productRupiah(NalaraPackage.monthlyPrice),
            style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w800),
          ),
          const Text('/ bulan', style: TextStyle(color: AppColors.muted)),
        ],
      ),
      const SizedBox(height: 8),
      const Text(
        'MODE DEMO • GRATIS 30 HARI',
        style: TextStyle(color: _blue, fontWeight: FontWeight.w700),
      ),
      const SizedBox(height: 8),
      const Text(
        'Semua fitur Basic, ditambah:',
        style: TextStyle(color: AppColors.muted, height: 1.5),
      ),
      const SizedBox(height: 20),
      for (final feature in _premiumFeatures)
        Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(feature.icon, color: _blue, size: 23),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      feature.title,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      feature.description,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.muted,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      if (premium && NalaraPackage.premium.expiresAt != null) ...[
        Text(
          'Aktif sampai ${_expiryLabel(NalaraPackage.premium.expiresAt!)}',
          style: const TextStyle(color: _blue, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
      ],
      if (_activationError != null) ...[
        Semantics(
          liveRegion: true,
          child: Text(
            _activationError!,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ),
        const SizedBox(height: 12),
      ],
      FilledButton.icon(
        onPressed: _activating
            ? null
            : premium
            ? () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const ReportsScreen(view: ReportView.profit),
                ),
              )
            : _activateDemo,
        style: FilledButton.styleFrom(
          backgroundColor: _blue,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        icon: _activating
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Icon(premium ? Icons.insights_rounded : Icons.workspace_premium),
        label: Text(
          _activating
              ? 'Mengaktifkan...'
              : premium
              ? 'Buka Analitik Premium'
              : 'Aktifkan Premium Demo',
        ),
      ),
      if (!premium) ...[
        const SizedBox(height: 10),
        const Text(
          'Langsung aktif selama 1 bulan (30 hari), tanpa pembayaran. '
          'Setelah habis, akun kembali ke Basic.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12, color: AppColors.muted, height: 1.4),
        ),
      ],
    ],
  );

  Widget _basicPlan(bool premium) => _card(
    children: [
      _planHeading('Basic', premium ? 'TERMASUK' : 'PAKET SAAT INI', false),
      const SizedBox(height: 16),
      const Text(
        'Gratis',
        style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800),
      ),
      const SizedBox(height: 8),
      const Text(
        'Untuk mencatat dan menjalankan usaha sehari-hari.',
        style: TextStyle(color: AppColors.muted, height: 1.5),
      ),
      const SizedBox(height: 20),
      for (final feature in _basicFeatures)
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.check_circle_outline,
                color: AppColors.green,
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(feature, style: const TextStyle(height: 1.5)),
              ),
            ],
          ),
        ),
    ],
  );

  Widget _planHeading(String title, String status, bool highlighted) => Wrap(
    alignment: WrapAlignment.spaceBetween,
    crossAxisAlignment: WrapCrossAlignment.center,
    spacing: 10,
    runSpacing: 10,
    children: [
      Text(
        title,
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: highlighted ? _blue : AppColors.background,
        ),
      ),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: highlighted ? const Color(0xFFEFF5FF) : AppColors.softBlue,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          status,
          style: TextStyle(
            color: highlighted ? _blue : AppColors.background,
            fontSize: 10,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    ],
  );

  Widget _question(String title, String answer) => ExpansionTile(
    tilePadding: EdgeInsets.zero,
    childrenPadding: const EdgeInsets.only(bottom: 16),
    title: Text(title),
    children: [Text(answer, style: const TextStyle(height: 1.5))],
  );

  Widget _card({required List<Widget> children, bool highlighted = false}) =>
      Material(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(
            color: highlighted ? _blue : AppColors.border,
            width: highlighted ? 1.5 : 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: children,
          ),
        ),
      );
}
