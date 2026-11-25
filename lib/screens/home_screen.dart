// Beranda memakai widget bawaan Flutter dan grafik Canvas tanpa package baru.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../colors.dart';
import '../session.dart';
import '../products.dart';
import '../transactions.dart';
import '../analytics.dart';
import '../widgets/app_navigation.dart';
import '../widgets/responsive_columns.dart';
import '../widgets/home_notifications_sheet.dart';
import 'products_screen.dart';
import 'reports_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _thirtyDays = false;

  final _session = StoreSession.instance;
  @override
  void initState() {
    super.initState();
    _session.addListener(_refresh);
    ProductCatalog.instance.addListener(_refresh);
    TransactionHistory.instance.addListener(_refresh);
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _session.removeListener(_refresh);
    ProductCatalog.instance.removeListener(_refresh);
    TransactionHistory.instance.removeListener(_refresh);
    super.dispose();
  }

  DateTime get _today {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  SalesAnalytics get _daily => SalesAnalytics(
    TransactionHistory.instance.items,
    _today,
    _today.add(const Duration(days: 1)),
  );
  List<double> _sales(int days) => SalesAnalytics(
    TransactionHistory.instance.items,
    _today.subtract(Duration(days: days - 1)),
    _today.add(const Duration(days: 1)),
  ).dailyRevenue.map((v) => v / 1000).toList();
  List<String> _labels(int days) => List.generate(days, (index) {
    final date = _today.subtract(Duration(days: days - index - 1));
    return days == 7 || index % 5 == 0 || index == days - 1
        ? '${date.day}/${date.month}'
        : '';
  });
  List<Product> get _lowStock => ProductCatalog.instance.items
      .where((p) => p.active && p.stock <= p.minimumStock)
      .toList();
  Future<void> _showStockNotifications() async {
    final product = await showModalBottomSheet<Product>(
      context: context,
      // Keep the sheet inside the signed-in session's navigator.
      useRootNavigator: false,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: AppColors.surface,
      constraints: const BoxConstraints(maxWidth: 640),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      clipBehavior: Clip.antiAlias,
      builder: (_) => const FractionallySizedBox(
        heightFactor: 0.85,
        child: HomeNotificationsSheet(),
      ),
    );
    if (!mounted || product == null) return;
    await Navigator.of(context).push<void>(
      MaterialPageRoute(builder: (_) => ProductDetailScreen(id: product.id)),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Landscape memakai ruang lebar tanpa mengubah urutan bagian utama.
    final landscape =
        MediaQuery.orientationOf(context) == Orientation.landscape;
    // Warna bilah sistem mengikuti header biru dan navigasi bawah putih.
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: AppColors.background,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: AppColors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        appBar: const NalaraHeader(title: 'Home'),
        backgroundColor: AppColors.surface,
        // Area konten dapat di-scroll; navigasi bawah tetap terlihat.
        body: SafeArea(
          bottom: false,
          child: SingleChildScrollView(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(minWidth: double.infinity),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header dan ringkasan saling bertumpuk seperti referensi.
                    _buildHeader(),
                    Center(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: landscape ? 1200 : 600,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Insight produk terlaris dan peringatan stok.
                              Row(
                                children: [
                                  const Expanded(
                                    child: Text(
                                      'Insight Hari Ini',
                                      style: TextStyle(
                                        color: AppColors.ink,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  Tooltip(
                                    message: 'Insight Bisnis khusus Premium',
                                    child: TextButton.icon(
                                      onPressed: () => Navigator.of(context)
                                          .push<void>(
                                            MaterialPageRoute(
                                              builder: (_) =>
                                                  const ReportsScreen(
                                                    view: ReportView.insights,
                                                  ),
                                            ),
                                          ),
                                      icon: const Icon(
                                        Icons.workspace_premium_rounded,
                                        size: 17,
                                        color: Color(0xFFB7791F),
                                      ),
                                      label: const Text(
                                        'Lainnya',
                                        style: TextStyle(fontSize: 12),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              ResponsiveColumns(
                                children: [
                                  _buildInsight(
                                    icon: Icons.local_fire_department_rounded,
                                    color: AppColors.logoBlue,
                                    background: AppColors.softBlue,
                                    label: 'PRODUK TERLARIS',
                                    name: _daily.ranking.isEmpty
                                        ? 'Belum ada penjualan'
                                        : _daily.ranking.first.key,
                                    detail:
                                        '${_daily.ranking.isEmpty ? 0 : _daily.ranking.first.value} terjual',
                                  ),
                                  _buildInsight(
                                    icon: Icons.warning_rounded,
                                    color: AppColors.orange,
                                    background: const Color(0xFFFFFBEB),
                                    label: 'STOK MENIPIS',
                                    name: _lowStock.isEmpty
                                        ? 'Stok aman'
                                        : _lowStock.first.name,
                                    detail: _lowStock.isEmpty
                                        ? 'Tidak ada peringatan'
                                        : 'tersisa ${_lowStock.first.stock}',
                                  ),
                                ],
                              ),
                              const SizedBox(height: 30),
                              // Periode grafik dan tombol menuju analitik.
                              _buildPerformance(),
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
        ),
        bottomNavigationBar: const NalaraNavigation(index: 0),
      ),
    );
  }

  // Header biru dengan sapaan, nama toko, dan tombol notifikasi.
  Widget _buildHeader() {
    return Stack(
      children: [
        Container(
          key: const ValueKey('home_header_background'),
          width: double.infinity,
          height: 158,
          decoration: const BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
          ),
        ),
        // Hanya isi header yang dibatasi; latar biru tetap memenuhi lebar layar.
        Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth:
                  MediaQuery.orientationOf(context) == Orientation.landscape
                  ? 1200
                  : 600,
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 36, 24, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Halo, ${_session.name.isEmpty ? 'Pengguna' : _session.name}',
                              style: TextStyle(
                                color: Color(0xFFD8E2FF),
                                fontSize: 13,
                              ),
                            ),
                            SizedBox(height: 6),
                            Text(
                              _session.storeName,
                              style: TextStyle(
                                color: AppColors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),

                      DecoratedBox(
                        decoration: BoxDecoration(
                          color: AppColors.white.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppColors.white.withValues(alpha: 0.2),
                          ),
                        ),
                        child: IconButton(
                          tooltip: 'Notifikasi',
                          onPressed: _showStockNotifications,
                          icon: Badge.count(
                            count: _lowStock.length,
                            isLabelVisible: _lowStock.isNotEmpty,
                            child: Icon(
                              Icons.notifications_rounded,
                              color: AppColors.white,
                              size: 22,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  _panel(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            const Expanded(
                              child: Text(
                                'RINGKASAN HARI INI',
                                style: TextStyle(
                                  color: AppColors.muted,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFECFDF5),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'Hari ini',
                                style: TextStyle(
                                  color: AppColors.green,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: _SummaryValue(
                                label: 'OMZET',
                                value: productRupiah(_daily.revenue),
                                color: AppColors.background,
                              ),
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: _SummaryValue(
                                label: 'LABA KOTOR',
                                value: productRupiah(_daily.profit),
                                color: AppColors.green,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Komponen insight digunakan ulang untuk produk terlaris dan stok menipis.
  Widget _buildInsight({
    required IconData icon,
    required Color color,
    required Color background,
    required String label,
    required String name,
    required String detail,
  }) {
    return _panel(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 23),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(color: AppColors.muted, fontSize: 10),
                ),
                const SizedBox(height: 4),
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: '$name  ',
                        style: const TextStyle(color: AppColors.ink),
                      ),
                      TextSpan(
                        text: '— $detail',
                        style: TextStyle(color: color),
                      ),
                    ],
                  ),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPerformance() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: [
            const Text(
              'Performa Penjualan',
              style: TextStyle(
                color: AppColors.ink,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SegmentedButton<bool>(
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(value: false, label: Text('7 Hari')),
                ButtonSegment(value: true, label: Text('30 Hari')),
              ],
              selected: {_thirtyDays},
              onSelectionChanged: (selection) =>
                  setState(() => _thirtyDays = selection.first),
              style: SegmentedButton.styleFrom(
                visualDensity: VisualDensity.compact,
                textStyle: const TextStyle(fontSize: 10),
                backgroundColor: const Color(0xFFF1F5F9),
                selectedBackgroundColor: AppColors.white,
                selectedForegroundColor: AppColors.background,
                foregroundColor: AppColors.muted,
                side: BorderSide.none,
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _panel(
          child: Column(
            children: [
              // Deskripsi grafik membantu pengguna pembaca layar memahami isinya.
              Semantics(
                label: _thirtyDays
                    ? 'Grafik penjualan selama 30 hari'
                    : 'Grafik penjualan selama 7 hari',
                image: true,
                child: AspectRatio(
                  aspectRatio: 1.8,
                  child: CustomPaint(
                    painter: _SalesChartPainter(
                      values: _sales(_thirtyDays ? 30 : 7),
                      labels: _labels(_thirtyDays ? 30 : 7),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  style: TextButton.styleFrom(
                    backgroundColor: AppColors.softBlue,
                    foregroundColor: AppColors.background,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  // Pintasan membuka halaman utama Laporan dengan navbar tetap tersedia.
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => const ReportsScreen(),
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Flexible(
                        child: Text(
                          'Lihat Analitik',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      SizedBox(width: 8),
                      Icon(Icons.arrow_forward, size: 16),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Gaya kartu digunakan bersama agar ringkasan, insight, dan grafik seragam.
  Widget _panel({
    required Widget child,
    EdgeInsets padding = const EdgeInsets.all(20),
  }) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.background.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }
}

// Label dan nominal ringkasan membungkus bila teks diperbesar.
class _SummaryValue extends StatelessWidget {
  const _SummaryValue({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: AppColors.muted, fontSize: 10),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

class _SalesChartPainter extends CustomPainter {
  const _SalesChartPainter({required this.values, required this.labels});

  final List<double> values;
  final List<String> labels;

  // Menulis label kecil pada Canvas; ukuran tetap menjaga sumbu tetap terbaca.
  void _drawLabel(
    Canvas canvas,
    String text,
    Offset position, {
    bool centered = false,
  }) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(color: Color(0xFF737373), fontSize: 10),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(
      canvas,
      Offset(position.dx - (centered ? painter.width / 2 : 0), position.dy),
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    // Menyisakan ruang di kiri untuk angka dan di bawah untuk nama hari.
    final plot = Rect.fromLTRB(30, 12, size.width - 8, size.height - 20);
    final gridPaint = Paint()
      ..color = const Color(0xFFF1F5F9)
      ..strokeWidth = 1;
    final maximum = values.fold<double>(
      1,
      (max, value) => value > max ? value : max,
    );
    for (var tick = 0; tick <= 4; tick++) {
      final value = (maximum * tick / 4).round();
      final y = plot.bottom - tick / 4 * plot.height;
      canvas.drawLine(Offset(plot.left, y), Offset(plot.right, y), gridPaint);
      _drawLabel(canvas, '$value', Offset(0, y - 5));
    }

    final points = List.generate(
      values.length,
      (index) => Offset(
        plot.left + index / (values.length - 1) * plot.width,
        plot.bottom - values[index] / maximum * plot.height,
      ),
    );
    final line = Path()..moveTo(points.first.dx, points.first.dy);
    for (var index = 1; index < points.length; index++) {
      final previous = points[index - 1];
      final current = points[index];
      final middleX = (previous.dx + current.dx) / 2;
      line.cubicTo(
        middleX,
        previous.dy,
        middleX,
        current.dy,
        current.dx,
        current.dy,
      );
    }

    // Warna transparan di bawah kurva membantu memperjelas tren penjualan.
    final area = Path.from(line)
      ..lineTo(plot.right, plot.bottom)
      ..lineTo(plot.left, plot.bottom)
      ..close();
    canvas.drawPath(
      area,
      Paint()..color = AppColors.logoBlue.withValues(alpha: 0.1),
    );
    canvas.drawPath(
      line,
      Paint()
        ..color = AppColors.logoBlue
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );
    for (var index = 0; index < points.length; index++) {
      canvas.drawCircle(points[index], 3, Paint()..color = AppColors.logoBlue);
      _drawLabel(
        canvas,
        labels[index],
        Offset(points[index].dx, plot.bottom + 4),
        centered: true,
      );
    }
  }

  // Grafik digambar ulang hanya ketika pengguna mengganti data atau label periode.
  @override
  bool shouldRepaint(covariant _SalesChartPainter oldDelegate) =>
      oldDelegate.values != values || oldDelegate.labels != labels;
}
