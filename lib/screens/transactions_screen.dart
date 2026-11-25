import 'package:flutter/material.dart';

import '../colors.dart';
import '../exports.dart';
import '../firebase_store.dart';
import '../session.dart';
import '../products.dart' show productRupiah;
import '../transactions.dart';
import '../widgets/responsive_columns.dart';
import '../widgets/app_navigation.dart';
import '../widgets/transaction_history_cards.dart';
import '../widgets/daily_transaction_report.dart';

// State hanya menyimpan pencarian dan filter pada perangkat.
class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});
  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  final _search = TextEditingController();
  bool _report = false;
  String _query = '';
  String _method = 'Semua Metode';
  String _period = 'Semua Tanggal';
  DateTimeRange? _range;

  // Pilihan tanggal khusus menggunakan date range picker bawaan Flutter.
  Future<void> _choosePeriod(String value) async {
    if (value == 'Rentang Tanggal') {
      final now = DateTime.now();
      final result = await showDateRangePicker(
        context: context,
        firstDate: DateTime(2000),
        lastDate: DateTime(now.year + 1),
        initialDateRange: _range,
        helpText: 'Pilih Rentang Tanggal',
        saveText: 'Terapkan',
        cancelText: 'Batal',
        fieldStartLabelText: 'Tanggal Mulai',
        fieldEndLabelText: 'Tanggal Akhir',
        // Tema lokal mencegah kalender mewarisi latar splash yang berwarna biru.
        // Header tetap biru, tetapi area tanggal putih dengan teks gelap.
        builder: (context, child) {
          final scheme =
              ColorScheme.fromSeed(
                seedColor: AppColors.background,
                brightness: Brightness.light,
              ).copyWith(
                primary: AppColors.background,
                onPrimary: Colors.white,
                surface: Colors.white,
                onSurface: AppColors.ink,
              );
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: scheme,
              scaffoldBackgroundColor: Colors.white,
              textButtonTheme: TextButtonThemeData(
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.background,
                ),
              ),
              datePickerTheme: DatePickerThemeData(
                backgroundColor: Colors.white,
                surfaceTintColor: Colors.transparent,
                rangePickerBackgroundColor: Colors.white,
                rangePickerSurfaceTintColor: Colors.transparent,
                rangePickerHeaderBackgroundColor: AppColors.background,
                rangePickerHeaderForegroundColor: Colors.white,
                rangeSelectionBackgroundColor: AppColors.softBlue,
                todayForegroundColor: const WidgetStatePropertyAll(
                  AppColors.background,
                ),
                todayBorder: const BorderSide(color: AppColors.logoBlue),
                dayForegroundColor: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.selected)) {
                    return Colors.white;
                  }
                  if (states.contains(WidgetState.disabled)) {
                    return AppColors.muted;
                  }
                  return AppColors.ink;
                }),
                dayBackgroundColor: WidgetStateProperty.resolveWith(
                  (states) => states.contains(WidgetState.selected)
                      ? AppColors.background
                      : null,
                ),
              ),
            ),
            child: child!,
          );
        },
      );
      if (!mounted || result == null) return;
      setState(() {
        _period = value;
        _range = result;
      });
    } else {
      setState(() {
        _period = value;
        _range = null;
      });
    }
  }

  // Batas akhir bersifat eksklusif agar seluruh waktu pada tanggal terakhir masuk.
  bool _matchesDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    DateTime? start;
    DateTime? end;
    if (_period == 'Hari Ini') {
      start = today;
      end = today.add(const Duration(days: 1));
    }
    if (_period == '7 Hari Terakhir') {
      start = today.subtract(const Duration(days: 6));
      end = today.add(const Duration(days: 1));
    }
    if (_period == 'Rentang Tanggal' && _range != null) {
      start = _range!.start;
      end = _range!.end.add(const Duration(days: 1));
    }
    return (start == null || !date.isBefore(start)) &&
        (end == null || date.isBefore(end));
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  bool get _filtered =>
      _query.trim().isNotEmpty ||
      _method != 'Semua Metode' ||
      _period != 'Semua Tanggal';

  void _resetFilters() {
    _search.clear();
    setState(() {
      _query = '';
      _method = 'Semua Metode';
      _period = 'Semua Tanggal';
      _range = null;
    });
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: TransactionHistory.instance,
    builder: (context, _) {
      final entries = TransactionHistory.instance.items
          .where(
            (item) =>
                item.id.toLowerCase().contains(
                  _query.trim().toLowerCase().replaceFirst('#', ''),
                ) &&
                (_method == 'Semua Metode' || item.method == _method) &&
                _matchesDate(item.date),
          )
          .toList();
      final groups = <DateTime, List<SaleTransaction>>{};
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final yesterday = DateTime(now.year, now.month, now.day - 1);
      for (final entry in entries) {
        final day = DateTime(entry.date.year, entry.date.month, entry.date.day);
        groups.putIfAbsent(day, () => []).add(entry);
      }
      return DefaultTabController(
        length: 2,
        child: Scaffold(
          backgroundColor: AppColors.surface,
          appBar: AppBar(
            title: const Text(
              'Transaksi',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
            backgroundColor: Colors.white,
            foregroundColor: AppColors.ink,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            bottom: TabBar(
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              labelColor: AppColors.background,
              unselectedLabelColor: AppColors.muted,
              indicatorColor: AppColors.background,
              onTap: (index) {
                FocusScope.of(context).unfocus();
                setState(() => _report = index == 1);
              },
              tabs: const [
                Tab(text: 'Riwayat'),
                Tab(text: 'Laporan Transaksi'),
              ],
            ),
          ),
          bottomNavigationBar: const NalaraNavigation(index: 3),
          body: _report
              ? const DailyTransactionReport()
              : SafeArea(
                  bottom: false,
                  child: SingleChildScrollView(
                    key: const PageStorageKey('transaction-history'),
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1040),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const Text(
                                'Pantau setiap penjualan, temukan setiap detail.',
                                style: TextStyle(
                                  color: AppColors.muted,
                                  fontSize: 13,
                                  height: 1.5,
                                ),
                              ),
                              const SizedBox(height: 20),
                              TransactionSummaryCard(
                                entries: entries,
                                filtered: _filtered,
                              ),
                              const SizedBox(height: 24),
                              _searchAndFilters(),
                              const SizedBox(height: 26),
                              Wrap(
                                alignment: WrapAlignment.spaceBetween,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                spacing: 12,
                                runSpacing: 8,
                                children: [
                                  const Text(
                                    'Daftar transaksi',
                                    style: TextStyle(
                                      color: AppColors.ink,
                                      fontSize: 17,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  Text(
                                    '${entries.length} hasil • Terbaru dahulu',
                                    style: const TextStyle(
                                      color: AppColors.muted,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                              if (entries.isEmpty)
                                TransactionHistoryEmpty(
                                  filtered: _filtered,
                                  onReset: _resetFilters,
                                ),
                              for (final group in groups.entries) ...[
                                const SizedBox(height: 22),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        group.key == today
                                            ? 'Hari ini'
                                            : group.key == yesterday
                                            ? 'Kemarin'
                                            : transactionDate(group.key),
                                        style: const TextStyle(
                                          color: AppColors.muted,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      '${group.value.length} transaksi',
                                      style: const TextStyle(
                                        color: AppColors.muted,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                ResponsiveColumns(
                                  gap: 12,
                                  children: [
                                    for (final transaction in group.value)
                                      TransactionHistoryCard(
                                        transaction: transaction,
                                        onTap: () => Navigator.of(context).push(
                                          MaterialPageRoute<void>(
                                            builder: (_) =>
                                                TransactionDetailScreen(
                                                  transaction: transaction,
                                                ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
        ),
      );
    },
  );

  Widget _searchAndFilters() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      TextField(
        controller: _search,
        onChanged: (value) => setState(() => _query = value),
        textInputAction: TextInputAction.search,
        onSubmitted: (_) => FocusScope.of(context).unfocus(),
        decoration: InputDecoration(
          hintText: 'Cari ID transaksi...',
          hintStyle: const TextStyle(color: AppColors.muted, fontSize: 13),
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: AppColors.muted,
            size: 22,
          ),
          suffixIcon: _query.isEmpty
              ? null
              : IconButton(
                  tooltip: 'Hapus pencarian',
                  onPressed: () {
                    _search.clear();
                    setState(() => _query = '');
                  },
                  icon: const Icon(Icons.close_rounded, size: 18),
                ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.logoBlue),
          ),
        ),
      ),
      const SizedBox(height: 12),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          _filterMenu(
            tooltip: 'Filter tanggal',
            label: _period,
            icon: Icons.calendar_today_outlined,
            selected: _period != 'Semua Tanggal',
            options: const [
              'Semua Tanggal',
              'Hari Ini',
              '7 Hari Terakhir',
              'Rentang Tanggal',
            ],
            onSelected: _choosePeriod,
          ),
          _filterMenu(
            tooltip: 'Filter metode',
            label: _method,
            icon: Icons.tune_rounded,
            selected: _method != 'Semua Metode',
            options: const ['Semua Metode', 'QRIS', 'Tunai'],
            onSelected: (value) => setState(() => _method = value),
          ),
          if (_filtered)
            TextButton(
              onPressed: _resetFilters,
              child: const Text('Reset filter'),
            ),
        ],
      ),
      if (_range != null) ...[
        const SizedBox(height: 10),
        Text(
          '${transactionDate(_range!.start)} – ${transactionDate(_range!.end)}',
          style: const TextStyle(color: AppColors.background, fontSize: 12),
        ),
      ],
    ],
  );

  Widget _filterMenu({
    required String tooltip,
    required String label,
    required IconData icon,
    required bool selected,
    required List<String> options,
    required ValueChanged<String> onSelected,
  }) => PopupMenuButton<String>(
    tooltip: tooltip,
    initialValue: label,
    onSelected: onSelected,
    color: Colors.white,
    surfaceTintColor: Colors.transparent,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    itemBuilder: (_) => options
        .map((value) => PopupMenuItem(value: value, child: Text(value)))
        .toList(),
    child: Container(
      constraints: const BoxConstraints(minHeight: 48),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: selected ? AppColors.softBlue : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: selected ? const Color(0xFFB9CEF7) : AppColors.border,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: selected ? AppColors.background : AppColors.muted,
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                color: selected
                    ? AppColors.background
                    : const Color(0xFF475569),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 8),
          const Icon(
            Icons.keyboard_arrow_down_rounded,
            size: 18,
            color: AppColors.muted,
          ),
        ],
      ),
    ),
  );
}

// Detail menggunakan snapshot transaksi yang sama dengan kartu riwayat.
class TransactionDetailScreen extends StatelessWidget {
  const TransactionDetailScreen({super.key, required this.transaction});
  final SaleTransaction transaction;

  Future<void> _receiptAction(BuildContext context, String action) async {
    try {
      await exportReceipt(
        transaction,
        StoreSession.instance.storeName,
        print: action.startsWith('Cetak'),
      );
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(firebaseMessage(error))));
      }
    }
  }

  @override
  Widget build(BuildContext context) => _TransactionPage(
    title: 'Detail Transaksi',
    children: [
      ResponsiveColumns(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _TransactionPanel(
                child: Column(
                  children: [
                    const CircleAvatar(
                      radius: 28,
                      backgroundColor: Color(0xFFE0F2F1),
                      child: Icon(
                        Icons.request_quote,
                        color: Color(0xFF0D9488),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Transaksi Berhasil',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '#${transaction.id} · ${transaction.method}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (transaction.points > 0)
                      Chip(
                        avatar: const Icon(
                          Icons.stars,
                          size: 16,
                          color: Colors.purple,
                        ),
                        label: Text('+${transaction.points} Poin Terkumpul'),
                        backgroundColor: AppColors.softBlue,
                        side: BorderSide.none,
                        labelStyle: const TextStyle(
                          color: AppColors.logoBlue,
                          fontSize: 11,
                        ),
                        shape: const StadiumBorder(),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _TransactionPanel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Metadata sejajar: label di kiri dan nilai di kanan.
                    _metadata(
                      'WAKTU TRANSAKSI',
                      '${transactionDate(transaction.date)}, ${transactionTime(transaction.date)}',
                    ),
                    const SizedBox(height: 12),
                    _metadata('METODE PEMBAYARAN', transaction.method),
                  ],
                ),
              ),
            ],
          ),
          _TransactionPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Row(
                  children: [
                    Icon(
                      Icons.receipt_long,
                      size: 16,
                      color: AppColors.logoBlue,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Daftar Pesanan',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                for (final item in transaction.items) ...[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.softBlue,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${item.quantity}×',
                          style: const TextStyle(
                            color: AppColors.logoBlue,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                            Text(
                              productRupiah(item.price),
                              style: const TextStyle(
                                color: AppColors.muted,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Kolom harga memenuhi sisa ruang agar ujung kanan sejajar total.
                      Expanded(
                        child: Text(
                          productRupiah(item.subtotal),
                          textAlign: TextAlign.right,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
                const Divider(),
                _amount('Subtotal', transaction.subtotal),
                const SizedBox(height: 12),
                _amount('Diskon Promo', -transaction.discount),
                const SizedBox(height: 16),
                _amount('Total Pembayaran', transaction.total, emphasis: true),
              ],
            ),
          ),
        ],
      ),
      const SizedBox(height: 24),
      // Kedua aksi membagi lebar yang tersedia tanpa ukuran tinggi kaku.
      Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => _receiptAction(context, 'Cetak struk'),
              child: const Text('Cetak Struk', textAlign: TextAlign.center),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: FilledButton.icon(
              onPressed: () => _receiptAction(context, 'Bagikan struk'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.background,
                foregroundColor: Colors.white,
              ),
              icon: const Icon(Icons.arrow_forward, size: 18),
              label: const Text('Bagikan'),
            ),
          ),
        ],
      ),
    ],
  );

  // Nilai panjang dapat membungkus sehingga metadata tetap rapi saat teks diperbesar.
  Widget _metadata(String label, String value) => Row(
    children: [
      Expanded(
        child: Text(
          label,
          style: const TextStyle(color: AppColors.muted, fontSize: 10),
        ),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Text(
          value,
          textAlign: TextAlign.right,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
      ),
    ],
  );
}

// Label dan nominal membagi ruang agar tetap terbaca pada layar sempit.
Widget _amount(String label, int value, {bool emphasis = false}) => Row(
  children: [
    Expanded(
      child: Text(
        label,
        style: TextStyle(
          color: emphasis ? AppColors.ink : AppColors.muted,
          fontWeight: emphasis ? FontWeight.bold : FontWeight.normal,
          fontSize: 12,
        ),
      ),
    ),
    const SizedBox(width: 8),
    Expanded(
      child: Text(
        value < 0 ? '-${productRupiah(-value)}' : productRupiah(value),
        textAlign: TextAlign.right,
        style: TextStyle(
          color: value < 0 ? AppColors.green : AppColors.background,
          fontWeight: FontWeight.bold,
        ),
      ),
    ),
  ],
);

// Kerangka layar memakai header penuh dan konten adaptif seperti halaman lain.
class _TransactionPage extends StatelessWidget {
  const _TransactionPage({required this.title, required this.children});
  final String title;
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.surface,
    appBar: NalaraHeader(title: title),
    body: SafeArea(
      child: SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth:
                  MediaQuery.orientationOf(context) == Orientation.landscape
                  ? 1100
                  : 560,
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: children,
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class _TransactionPanel extends StatelessWidget {
  const _TransactionPanel({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppColors.border),
    ),
    child: child,
  );
}
