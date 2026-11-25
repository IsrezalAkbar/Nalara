import 'package:flutter/material.dart';

import '../analytics.dart';
import '../colors.dart';
import '../exports.dart';
import '../firebase_store.dart';
import '../products.dart';
import '../session.dart';
import '../transactions.dart';
import '../widgets/app_navigation.dart';
import '../widgets/business_analytics_overview.dart';
import '../widgets/premium_report_pages.dart';
import '../widgets/premium_report_notice.dart';
import '../widgets/stock_history_sheet.dart';
import '../widgets/report_switcher.dart';
import '../report_view.dart';

import 'products_screen.dart';
import 'package_screen.dart';

export '../report_view.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({
    super.key,
    this.view = ReportView.overview,
    this.productId,
  });
  final ReportView view;
  final String? productId;
  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  late ReportView _view = widget.view;
  int _days = 7;
  late bool _month = widget.view == ReportView.profit;
  DateTimeRange? _range;
  bool _exporting = false;
  DateTime get _today {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  SalesAnalytics get _analytics => SalesAnalytics(
    TransactionHistory.instance.items,
    _range?.start ??
        (_month
            ? DateTime(_today.year, _today.month)
            : _today.subtract(Duration(days: _days - 1))),
    (_range?.end ?? _today).add(const Duration(days: 1)),
  );

  Future<void> _pickRange() async {
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: _today,
      initialDateRange: _range,
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.fromSeed(seedColor: AppColors.background),
        ),
        child: child!,
      ),
    );
    if (mounted && range != null) {
      setState(() {
        _range = range;
        _month = false;
      });
    }
  }

  Future<void> _export({bool csv = false}) async {
    if (_exporting) return;
    setState(() => _exporting = true);
    try {
      await exportReport(_analytics, StoreSession.instance.storeName, csv: csv);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(firebaseMessage(error))));
      }
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  void _openReport(ReportView view, {Product? product}) {
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => ReportsScreen(view: view, productId: product?.id),
      ),
    );
  }

  void _selectReport(ReportView view) {
    if (view == _view) return;
    setState(() {
      _view = view;
      _range = null;
      _days = 7;
      _month = view == ReportView.profit;
    });
  }

  void _back() {
    if (Navigator.of(context).canPop()) {
      Navigator.pop(context);
    } else {
      setState(() {
        _view = ReportView.overview;
        _month = false;
        _range = null;
      });
    }
  }

  void _showStockAlerts(List<Product> products) => showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    constraints: BoxConstraints(
      maxHeight: MediaQuery.sizeOf(context).height * 0.75,
    ),
    builder: (sheetContext) => SafeArea(
      child: ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        children: [
          const Text(
            'Peringatan Stok',
            style: TextStyle(
              color: AppColors.ink,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          if (products.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Text(
                'Tidak ada produk dengan stok di bawah batas minimum.',
              ),
            ),
          for (final product in products)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(
                Icons.warning_amber_rounded,
                color: AppColors.orange,
              ),
              title: Text(product.name),
              subtitle: Text(
                'Stok ${product.stock} · Minimum ${product.minimumStock}',
              ),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () {
                Navigator.pop(sheetContext);
                Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => ProductDetailScreen(id: product.id),
                  ),
                );
              },
            ),
        ],
      ),
    ),
  );

  void _showReportActions(
    SalesAnalytics analytics,
  ) => showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) => SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Laporan Penjualan',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              '${transactionDate(analytics.start)} – ${transactionDate(analytics.end.subtract(const Duration(days: 1)))}',
              style: const TextStyle(color: AppColors.muted, fontSize: 12),
            ),
            if (analytics.sales.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 12),
                child: Text('Belum ada transaksi untuk diekspor.'),
              ),
            ListTile(
              leading: const Icon(Icons.picture_as_pdf_outlined),
              title: const Text('Unduh PDF'),
              enabled: !_exporting && analytics.sales.isNotEmpty,
              onTap: () {
                Navigator.pop(sheetContext);
                _export();
              },
            ),
            ListTile(
              leading: const Icon(Icons.table_chart_outlined),
              title: const Text('Ekspor CSV'),
              enabled: !_exporting && analytics.sales.isNotEmpty,
              onTap: () {
                Navigator.pop(sheetContext);
                _export(csv: true);
              },
            ),
            ListTile(
              leading: const Icon(Icons.receipt_long_rounded),
              title: const Text('Lihat Laporan Penjualan'),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () {
                Navigator.pop(sheetContext);
                _openReport(ReportView.sales);
              },
            ),
          ],
        ),
      ),
    ),
  );

  Widget _overview(
    SalesAnalytics analytics,
    SalesAnalytics previous,
    List<Product> lowStock,
  ) => Scaffold(
    backgroundColor: const Color(0xFFF7F9FC),
    appBar: AppBar(
      automaticallyImplyLeading: false,
      backgroundColor: const Color(0xFF233F91),
      foregroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      toolbarHeight: 76,
      titleSpacing: 20,
      title: ReportSwitcher(
        current: _view,
        onSelected: _selectReport,
        onDark: true,
      ),
      actions: [
        IconButton(
          tooltip: 'Peringatan stok',
          onPressed: () => _showStockAlerts(lowStock),
          icon: Badge(
            isLabelVisible: lowStock.isNotEmpty,
            child: const Icon(Icons.notifications_rounded, size: 19),
          ),
          style: IconButton.styleFrom(
            backgroundColor: Colors.white.withValues(alpha: .12),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        IconButton(
          tooltip: 'Rentang Tanggal',
          onPressed: _pickRange,
          icon: const Icon(
            Icons.calendar_month_outlined,
            size: 20,
            color: Colors.white,
          ),
        ),
        const SizedBox(width: 8),
      ],
    ),
    bottomNavigationBar: const NalaraNavigation(index: 4),
    body: SafeArea(
      top: false,
      bottom: false,
      child: SingleChildScrollView(
        child: Stack(
          children: [
            Container(
              height:
                  130 +
                  45 * (MediaQuery.textScalerOf(context).scale(14) / 14 - 1),
              decoration: const BoxDecoration(
                color: Color(0xFF233F91),
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(32),
                ),
              ),
            ),
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 620),
                child: BusinessAnalyticsOverview(
                  analytics: analytics,
                  previous: previous,
                  days: _days,
                  customRange: _range != null,
                  exporting: _exporting,
                  onPeriodChanged: (days) => setState(() {
                    _range = null;
                    _days = days;
                  }),
                  onInsights: () => _openReport(ReportView.insights),
                  onProducts: () => _openReport(ReportView.products),
                  onReport: () => _showReportActions(analytics),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: Listenable.merge([
      TransactionHistory.instance,
      ProductCatalog.instance,
      StoreSession.instance.premium,
    ]),
    builder: (context, _) {
      if (_view != ReportView.overview &&
          !StoreSession.instance.premium.value) {
        return Scaffold(
          backgroundColor: const Color(0xFFF7F9FC),
          appBar: AppBar(
            backgroundColor: AppColors.background,
            foregroundColor: Colors.white,
            toolbarHeight: 76,
            leading: IconButton(
              tooltip: 'Kembali',
              onPressed: _back,
              icon: const Icon(Icons.chevron_left_rounded),
            ),
            title: ReportSwitcher(
              current: _view,
              onSelected: _selectReport,
              onDark: true,
            ),
          ),
          bottomNavigationBar: const NalaraNavigation(index: 4),
          body: PremiumReportNotice(
            view: _view,
            onPackages: () => Navigator.push(
              context,
              MaterialPageRoute<void>(builder: (_) => const PackageScreen()),
            ),
            onOverview: () => _selectReport(ReportView.overview),
          ),
        );
      }
      final analytics = _analytics;
      final previous = SalesAnalytics(
        TransactionHistory.instance.items,
        analytics.start.subtract(analytics.end.difference(analytics.start)),
        analytics.start,
      );
      final lowStock = ProductCatalog.instance.items
          .where((p) => p.active && p.stock <= p.minimumStock)
          .toList();
      if (_view == ReportView.overview) {
        return _overview(analytics, previous, lowStock);
      }
      final catalog = ProductCatalog.instance.items;
      Product? detailProduct;
      for (final product in catalog) {
        if (product.id == widget.productId) detailProduct = product;
      }
      return PremiumReportPage(
        view: _view,
        analytics: analytics,
        previous: previous,
        recentSales: SalesAnalytics(
          TransactionHistory.instance.items,
          _today.subtract(const Duration(days: 6)),
          _today.add(const Duration(days: 1)),
        ),
        catalog: catalog,
        detailProduct: detailProduct,
        days: _days,
        customRange: _range != null,
        month: _month,
        exporting: _exporting,
        onPeriod: (days) => setState(() {
          _range = null;
          _month = days == 0;
          if (days > 0) _days = days;
        }),
        onCustomRange: _pickRange,
        onBack: _back,
        onView: _selectReport,
        onProduct: (product) => Navigator.push(
          context,
          MaterialPageRoute<void>(
            builder: (_) => ProductDetailScreen(id: product.id),
          ),
        ),
        onInsight: (product) =>
            _openReport(ReportView.insightDetail, product: product),
        onAddStock: (product) => showAddProductStock(context, product),
        onEditProduct: (product) => Navigator.push(
          context,
          MaterialPageRoute<void>(
            builder: (_) => ProductFormScreen(product: product),
          ),
        ),
        onStockHistory: (product) => showProductStockHistory(context, product),
        onExport: _exporting || analytics.sales.isEmpty
            ? null
            : () => _export(),
      );
    },
  );
}
