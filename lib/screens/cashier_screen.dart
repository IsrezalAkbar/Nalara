import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../colors.dart';
import '../firebase_store.dart';
import '../widgets/app_navigation.dart';
import '../products.dart';
import '../transactions.dart';
import '../session.dart';
import '../widgets/cashier_product_card.dart';
import '../widgets/cashier_cart_item.dart';
import '../widgets/cash_amount_input.dart';
import 'transactions_screen.dart';

// Pemilihan produk hingga struk berada dalam satu halaman agar struktur tetap sederhana.
enum _CashierStep { selection, cart, payment, success }

class CashierScreen extends StatefulWidget {
  const CashierScreen({super.key});

  @override
  State<CashierScreen> createState() => _CashierScreenState();
}

class _CashierScreenState extends State<CashierScreen> {
  // Snapshot produk aktif dari katalog bersama saat kasir dibuka.
  late var _products = ProductCatalog.instance.items
      .where((p) => p.active)
      .toList();

  _CashierStep _step = _CashierStep.selection;
  late List<int> _quantities = List.filled(_products.length, 0);
  final _searchController = TextEditingController();
  String _category = 'Semua';
  bool _paying = false;
  SaleTransaction? _sale;
  String? _checkoutId;
  String _paymentMethod = 'Tunai';
  bool _qrisConfirmed = false;
  final _cashController = TextEditingController();
  DateTime? _paidAt;

  // Semua nominal dihitung dalam rupiah bulat agar struk sesuai dengan keranjang.
  int get _subtotal => List.generate(
    _products.length,
    (index) => _products[index].price * _quantities[index],
  ).fold(0, (sum, value) => sum + value);
  int get _discount => 0;
  int get _total => _sale?.total ?? _subtotal - _discount;
  int get _cash => int.tryParse(_cashController.text.replaceAll('.', '')) ?? 0;
  bool get _canPay =>
      !_paying &&
      _menuCount > 0 &&
      _total > 0 &&
      StoreSession.instance.methods[_paymentMethod] == true &&
      (_paymentMethod == 'Tunai' ? _cash >= _total : _qrisConfirmed);
  int get _menuCount => _quantities.where((quantity) => quantity > 0).length;
  int get _itemCount => _quantities.fold(0, (sum, quantity) => sum + quantity);
  int get _points => _sale?.points ?? 0;
  String get _transactionId => _sale?.id ?? _checkoutId ?? '';

  // Pemformat rupiah sederhana tanpa package tambahan.
  String _rupiah(int amount) {
    final digits = amount.toString();
    final formatted = digits.replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+$)'),
      (match) => '${match[1]}.',
    );
    return 'Rp$formatted';
  }

  // Waktu transaksi dicatat sekali ketika tombol Bayar ditekan.
  String get _timeLabel {
    final time = _paidAt;
    if (time == null) return '-';
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];
    return '${time.day} ${months[time.month - 1]} ${time.year}, ${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  @override
  void initState() {
    super.initState();
    ProductCatalog.instance.addListener(_refreshProducts);
    StoreSession.instance.addListener(_refreshPaymentMethods);
    _refreshPaymentMethods();
  }

  void _refreshPaymentMethods() {
    if (!mounted || _paying) return;
    setState(() {
      final methods = StoreSession.instance.methods;
      if (methods[_paymentMethod] != true) {
        _paymentMethod = methods['Tunai']! ? 'Tunai' : 'QRIS';
        _qrisConfirmed = false;
      }
    });
  }

  void _refreshProducts() {
    if (!mounted || _step != _CashierStep.selection || _paying) return;
    final quantities = {
      for (var i = 0; i < _products.length; i++)
        _products[i].id: _quantities[i],
    };
    setState(() {
      _products = ProductCatalog.instance.items.where((p) => p.active).toList();
      _quantities = [
        for (final product in _products)
          (quantities[product.id] ?? 0).clamp(
            0,
            product.stock < 0 ? 0 : product.stock,
          ),
      ];
    });
  }

  void _changeQuantity(int index, int delta) {
    final next = _quantities[index] + delta;
    if (next < 0 || next > _products[index].stock) return;
    setState(() => _quantities[index] = next);
  }

  // Melepaskan controller ketika pengguna meninggalkan menu kasir.
  @override
  void dispose() {
    ProductCatalog.instance.removeListener(_refreshProducts);
    StoreSession.instance.removeListener(_refreshPaymentMethods);
    _cashController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // Mengganti tahap dan menutup keyboard; scroll baru dimulai dari bagian atas.
  void _goTo(_CashierStep step) {
    FocusScope.of(context).unfocus();
    setState(() {
      _step = step;
      if (step == _CashierStep.payment) _qrisConfirmed = false;
    });
  }

  // Kembali dari pembayaran mempertahankan keranjang; struk kembali ke sukses.
  void _back() {
    if (_paying) return;
    if (_step == _CashierStep.selection || _step == _CashierStep.success) {
      Navigator.of(context).pop();
    } else {
      _goTo(switch (_step) {
        _CashierStep.cart => _CashierStep.selection,
        _ => _CashierStep.cart,
      });
    }
  }

  // QRIS hanya mencatat pembayaran yang sudah dikonfirmasi oleh kasir.
  Future<void> _pay() async {
    if (!_canPay) return;
    setState(() => _paying = true);
    try {
      _checkoutId ??= accountRef.collection('transactions').doc().id;
      final sale = await TransactionHistory.instance.checkout(
        id: _checkoutId!,
        cash: _paymentMethod == 'Tunai' ? _cash : 0,
        method: _paymentMethod,
        items: [
          for (var i = 0; i < _products.length; i++)
            if (_quantities[i] > 0)
              TransactionItem(
                _products[i].name,
                _products[i].price,
                _quantities[i],
                productId: _products[i].id,
                cost: _products[i].cost,
              ),
        ],
      );
      if (!mounted) return;
      _sale = sale;
      _paidAt = sale.date;
      _goTo(_CashierStep.success);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(firebaseMessage(error))));
      }
    } finally {
      if (mounted) setState(() => _paying = false);
    }
  }

  // Memulai keranjang baru; riwayat sebelumnya tetap di memori selama aplikasi berjalan.
  void _newTransaction() {
    setState(() {
      _quantities = List.filled(_products.length, 0);
      _products = ProductCatalog.instance.items.where((p) => p.active).toList();
      _quantities = List.filled(_products.length, 0);
      _sale = null;
      _checkoutId = null;
      _paymentMethod = StoreSession.instance.methods['Tunai']!
          ? 'Tunai'
          : 'QRIS';
      _qrisConfirmed = false;
      _paidAt = null;
      _cashController.clear();
      _searchController.clear();
      _category = 'Semua';
      _step = _CashierStep.selection;
    });
  }

  // Kedua menu membuka detail yang sama dari snapshot transaksi selesai.
  void _openReceipt() {
    final transaction = _sale;
    if (transaction == null) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => TransactionDetailScreen(transaction: transaction),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final selecting = _step == _CashierStep.selection;
    // Pada landscape footer ikut scroll agar layar pendek tidak tertutup tombol.
    final landscape =
        MediaQuery.orientationOf(context) == Orientation.landscape;
    final scrollFooter =
        landscape ||
        (selecting &&
            (MediaQuery.sizeOf(context).height < 640 ||
                MediaQuery.textScalerOf(context).scale(14) > 20 ||
                MediaQuery.viewInsetsOf(context).bottom > 0)) ||
        ((_step == _CashierStep.cart || _step == _CashierStep.payment) &&
            (MediaQuery.sizeOf(context).height < 640 ||
                MediaQuery.textScalerOf(context).scale(14) > 20 ||
                MediaQuery.viewInsetsOf(context).bottom > 0));
    // Tombol kembali sistem mengikuti urutan tahap, bukan langsung keluar dari kasir.
    return PopScope(
      canPop:
          !_paying &&
          (_step == _CashierStep.selection || _step == _CashierStep.success),
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _back();
      },
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle(
          statusBarColor: AppColors.background,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
          systemNavigationBarColor: AppColors.white,
          systemNavigationBarIconBrightness: Brightness.dark,
        ),
        child: AbsorbPointer(
          absorbing: _paying,
          child: Scaffold(
            appBar: selecting || _step == _CashierStep.success
                ? null
                : _checkoutHeader(
                    _step == _CashierStep.cart ? 'Keranjang' : 'Pembayaran',
                  ),
            backgroundColor: const Color(0xFFF7F9FC),
            // Header, isi, dan footer responsif; isi tetap dapat di-scroll saat keyboard muncul.
            body: SafeArea(
              bottom: false,
              child: SingleChildScrollView(
                key: ValueKey(_step),
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header ikut bergulir agar teks besar tidak mengurangi ruang isi.
                    Center(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: landscape && selecting ? 1000 : 560,
                        ),
                        child: switch (_step) {
                          _CashierStep.selection => _catalog(),
                          _CashierStep.cart => _cart(),
                          _CashierStep.payment => _payment(),
                          _CashierStep.success => _success(),
                        },
                      ),
                    ),
                    if (scrollFooter) _footer(),
                  ],
                ),
              ),
            ),
            // Footer menyesuaikan tinggi teks tanpa ukuran tinggi yang kaku.
            bottomNavigationBar: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!scrollFooter) _footer(),
                const NalaraNavigation(index: 1),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Pencarian dan kategori hanya menyaring tampilan; pilihan keranjang tetap disimpan.
  Widget _catalog() {
    final query = _searchController.text.trim().toLowerCase();
    final categories = <String>{
      'Semua',
      'Makanan',
      'Minuman',
      'Lainnya',
      'Barang',
      for (final product in _products)
        if (product.category.isNotEmpty) product.category,
    };
    final indices = List.generate(_products.length, (index) => index)
        .where(
          (index) =>
              _products[index].name.toLowerCase().contains(query) &&
              (_category == 'Semua' || _products[index].category == _category),
        )
        .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.background, Color(0xFF3059B7)],
            ),
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  IconButton(
                    tooltip: Navigator.of(context).canPop() ? 'Kembali' : null,
                    onPressed: Navigator.of(context).canPop() ? _back : null,
                    icon: Icon(
                      Navigator.of(context).canPop()
                          ? Icons.chevron_left_rounded
                          : Icons.point_of_sale_rounded,
                      size: 24,
                    ),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white.withValues(alpha: .14),
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.white.withValues(
                        alpha: .14,
                      ),
                      disabledForegroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'PENJUALAN',
                          style: TextStyle(
                            color: Color(0xFFD9E6FF),
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.5,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Kasir',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 27,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -.6,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                'Pilih produk, siapkan pesanan pelanggan.',
                style: TextStyle(
                  color: Color(0xFFD9E6FF),
                  fontSize: 12,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _searchController,
                onChanged: (_) => setState(() {}),
                textInputAction: TextInputAction.search,
                style: const TextStyle(fontSize: 13, color: AppColors.ink),
                decoration: InputDecoration(
                  hintText: 'Cari produk...',
                  hintStyle: const TextStyle(
                    color: Color(0xFFA5B2C5),
                    fontSize: 12,
                  ),
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    color: AppColors.background,
                    size: 21,
                  ),
                  suffixIcon: query.isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'Hapus pencarian',
                          icon: const Icon(Icons.close_rounded, size: 18),
                          onPressed: () =>
                              setState(() => _searchController.clear()),
                        ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(
                      color: Color(0xFFAFCBFF),
                      width: 2,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        Container(
          color: Colors.transparent,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
            child: Row(
              children: [
                for (final category in categories)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(category),
                      selected: _category == category,
                      onSelected: (_) => setState(() => _category = category),
                      showCheckmark: false,
                      selectedColor: const Color(0xFF233E91),
                      backgroundColor: Colors.white,
                      labelStyle: TextStyle(
                        color: _category == category
                            ? Colors.white
                            : const Color(0xFF64748B),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      side: BorderSide(
                        color: _category == category
                            ? const Color(0xFF233E91)
                            : const Color(0xFFF0F3F8),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      materialTapTargetSize: MaterialTapTargetSize.padded,
                    ),
                  ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
          child: Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 8,
            children: [
              Text(
                query.isEmpty && _category == 'Semua'
                    ? 'Pilih produk'
                    : 'Hasil pencarian',
                style: const TextStyle(
                  color: AppColors.ink,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                '${indices.length} produk',
                style: const TextStyle(color: AppColors.muted, fontSize: 12),
              ),
            ],
          ),
        ),
        if (indices.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: AppColors.softBlue,
                    borderRadius: BorderRadius.circular(26),
                  ),
                  child: Icon(
                    _products.isEmpty
                        ? Icons.shopping_bag_outlined
                        : Icons.search_off_rounded,
                    size: 40,
                    color: AppColors.background,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  _products.isEmpty
                      ? 'Produk belum tersedia'
                      : 'Produk tidak ditemukan',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.ink,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _products.isEmpty
                      ? 'Tambahkan produk aktif dari menu Produk.'
                      : 'Coba kata kunci atau kategori lainnya.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.muted, fontSize: 12),
                ),
                if (query.isNotEmpty || _category != 'Semua') ...[
                  const SizedBox(height: 16),
                  TextButton.icon(
                    onPressed: () => setState(() {
                      _searchController.clear();
                      _category = 'Semua';
                    }),
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    label: const Text('Reset filter'),
                  ),
                ],
              ],
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.all(20),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final scale = MediaQuery.textScalerOf(context).scale(14) / 14;
                final columns =
                    ((constraints.maxWidth + 16) / (132 * scale + 16))
                        .floor()
                        .clamp(1, 4);
                final width =
                    (constraints.maxWidth - (columns - 1) * 16) / columns;
                return Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    for (final index in indices)
                      SizedBox(
                        width: width,
                        child: CashierProductCard(
                          key: ValueKey(_products[index].id),
                          product: _products[index],
                          quantity: _quantities[index],
                          onAdd: () => _changeQuantity(index, 1),
                          onRemove: () => _changeQuantity(index, -1),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _orderBar() => SafeArea(
    top: false,
    bottom: false,
    child: Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
      child: Center(
        heightFactor: 1,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.background, Color(0xFF3059B7)],
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x30233E91),
                  blurRadius: 12,
                  offset: Offset(0, 5),
                ),
              ],
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final summary = Row(
                  children: [
                    Badge(
                      isLabelVisible: _itemCount > 0,
                      label: Text('$_itemCount'),
                      backgroundColor: Colors.white,
                      textColor: AppColors.background,
                      child: Container(
                        padding: const EdgeInsets.all(11),
                        decoration: BoxDecoration(
                          color: const Color(0xFF3A539E),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.shopping_cart_rounded,
                          color: Colors.white,
                          size: 21,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _itemCount == 0
                                ? 'Belum ada pilihan'
                                : '$_itemCount item dipilih',
                            style: const TextStyle(
                              color: Color(0xFFCCD9F7),
                              fontSize: 11,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            _rupiah(_subtotal),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
                final next = FilledButton(
                  onPressed: _menuCount == 0
                      ? null
                      : () => _goTo(_CashierStep.cart),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF233E91),
                    disabledBackgroundColor: const Color(0xFF7084B7),
                    disabledForegroundColor: const Color(0xFFDAE2F2),
                    minimumSize: const Size(0, 46),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          'Lanjutkan',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      SizedBox(width: 8),
                      Icon(Icons.arrow_forward_rounded, size: 18),
                    ],
                  ),
                );
                if (constraints.maxWidth < 290 ||
                    MediaQuery.textScalerOf(context).scale(14) > 20) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [summary, const SizedBox(height: 12), next],
                  );
                }
                return Row(
                  children: [
                    Expanded(child: summary),
                    const SizedBox(width: 12),
                    next,
                  ],
                );
              },
            ),
          ),
        ),
      ),
    ),
  );
  PreferredSizeWidget _checkoutHeader(String title) => AppBar(
    toolbarHeight: 88,
    backgroundColor: const Color(0xFF233E91),
    foregroundColor: Colors.white,
    surfaceTintColor: Colors.transparent,
    elevation: 0,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
    ),
    flexibleSpace: Container(
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF304B92), Color(0xFF1F3C8C), Color(0xFF294FA6)],
        ),
      ),
    ),
    leadingWidth: 70,
    leading: Padding(
      padding: const EdgeInsets.fromLTRB(20, 23, 8, 23),
      child: IconButton(
        tooltip: _step == _CashierStep.cart
            ? 'Kembali ke kasir'
            : 'Kembali ke keranjang',
        onPressed: _back,
        icon: const Icon(Icons.chevron_left_rounded, size: 22),
        style: IconButton.styleFrom(
          padding: EdgeInsets.zero,
          foregroundColor: Colors.white,
          backgroundColor: const Color(0xFF415A9C),
          side: const BorderSide(color: Color(0xFF6980B7)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(11),
          ),
        ),
      ),
    ),
    titleSpacing: 4,
    title: Text(
      title,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
      ),
    ),
    actions: [
      IconButton(
        tooltip: 'Tambah Produk',
        onPressed: () => _goTo(_CashierStep.selection),
        icon: const Icon(Icons.point_of_sale_rounded, size: 20),
        style: IconButton.styleFrom(
          foregroundColor: Colors.white,
          backgroundColor: const Color(0xFF415FA6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      const SizedBox(width: 20),
    ],
  );

  Widget _cart() => Padding(
    padding: const EdgeInsets.fromLTRB(20, 22, 20, 16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_menuCount > 0) ...[
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 8,
            children: [
              const Text(
                'Pesanan pelanggan',
                style: TextStyle(
                  color: AppColors.ink,
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.softBlue,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Text(
                  '$_itemCount item',
                  style: const TextStyle(
                    color: AppColors.background,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Periksa jumlah produk sebelum pembayaran.',
            style: TextStyle(color: AppColors.muted, fontSize: 12, height: 1.5),
          ),
          const SizedBox(height: 20),
        ],
        if (_menuCount == 0)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 32),
            child: Column(
              children: [
                const Icon(
                  Icons.shopping_cart_outlined,
                  size: 44,
                  color: Color(0xFF94A3B8),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Keranjang kosong',
                  style: TextStyle(
                    color: AppColors.ink,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Pilih produk untuk memulai pesanan.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.muted, fontSize: 12),
                ),
                const SizedBox(height: 12),
                TextButton.icon(
                  onPressed: () => _goTo(_CashierStep.selection),
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Tambah Produk'),
                ),
              ],
            ),
          ),
        for (var index = 0; index < _products.length; index++)
          if (_quantities[index] > 0)
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: CashierCartItem(
                key: ValueKey('cart-${_products[index].id}'),
                product: _products[index],
                quantity: _quantities[index],
                onRemove: () => _changeQuantity(index, -1),
                onAdd: _quantities[index] >= _products[index].stock
                    ? null
                    : () => _changeQuantity(index, 1),
              ),
            ),
        if (_menuCount > 0)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
            decoration: BoxDecoration(
              color: AppColors.softBlue,
              border: Border.all(color: const Color(0xFFC7DBFF)),
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Row(
              children: [
                Icon(
                  Icons.local_offer_outlined,
                  size: 19,
                  color: AppColors.logoBlue,
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Promo',
                    style: TextStyle(
                      color: AppColors.background,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Flexible(
                  child: Text(
                    'Belum ada promo aktif',
                    textAlign: TextAlign.right,
                    style: TextStyle(color: AppColors.muted, fontSize: 11),
                  ),
                ),
              ],
            ),
          ),
      ],
    ),
  );

  Widget _cartSummary() => Container(
    padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
    decoration: const BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      boxShadow: [
        BoxShadow(
          color: Color(0x040F172A),
          blurRadius: 18,
          offset: Offset(0, -4),
        ),
      ],
    ),
    child: Center(
      heightFactor: 1,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Row(
              children: [
                Icon(
                  Icons.receipt_long_outlined,
                  color: AppColors.background,
                  size: 19,
                ),
                SizedBox(width: 9),
                Expanded(
                  child: Text(
                    'Ringkasan belanja',
                    style: TextStyle(
                      color: AppColors.ink,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            _cartAmount('Subtotal', _rupiah(_subtotal)),
            const SizedBox(height: 14),
            _cartAmount(
              'Diskon',
              '- ${_rupiah(_discount)}',
              color: const Color(0xFF0DADA4),
            ),
            const Divider(color: Color(0xFFF0F3F8), height: 28),
            _cartAmount('Total', _rupiah(_total), total: true),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _menuCount == 0
                  ? null
                  : () => _goTo(_CashierStep.payment),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF233E91),
                foregroundColor: Colors.white,
                disabledBackgroundColor: const Color(0xFFE7ECF5),
                disabledForegroundColor: const Color(0xFF94A3B8),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 13,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                elevation: 3,
                shadowColor: const Color(0x40233E91),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'CHECKOUT SEKARANG',
                          style: TextStyle(
                            color: _menuCount == 0
                                ? const Color(0xFF94A3B8)
                                : const Color(0xFFC5D5FA),
                            fontSize: 9,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Lanjut Pembayaran',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),
                  Container(
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(
                      color: _menuCount == 0
                          ? const Color(0xFFDDE4F0)
                          : const Color(0xFF3E59A2),
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: const Icon(Icons.arrow_forward_rounded, size: 19),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _cartAmount(
    String label,
    String value, {
    bool total = false,
    Color? color,
  }) => Row(
    children: [
      Expanded(
        child: Text(
          label,
          style: TextStyle(
            color: total ? AppColors.ink : const Color(0xFF8A9DBB),
            fontSize: total ? 17 : 13,
            fontWeight: total ? FontWeight.w700 : FontWeight.w400,
          ),
        ),
      ),
      const SizedBox(width: 16),
      Flexible(
        child: Text(
          value,
          textAlign: TextAlign.right,
          style: TextStyle(
            color: color ?? (total ? const Color(0xFF233E91) : AppColors.ink),
            fontSize: total ? 22 : 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    ],
  );
  void _setCashAmount(int amount) {
    FocusScope.of(context).unfocus();
    final text = _rupiah(amount).substring(2);
    setState(
      () => _cashController.value = TextEditingValue(
        text: text,
        selection: TextSelection.collapsed(offset: text.length),
      ),
    );
  }

  Widget _payment() => Padding(
    padding: const EdgeInsets.fromLTRB(20, 22, 20, 24),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(
                      color: AppColors.softBlue,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.receipt_long_rounded,
                      color: AppColors.logoBlue,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Ringkasan Pesanan',
                      style: TextStyle(
                        color: AppColors.ink,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _detail('$_menuCount Menu terpilih', _rupiah(_subtotal)),
              _detail(
                'Diskon Promo',
                '- ${_rupiah(_discount)}',
                color: const Color(0xFF0DADA4),
              ),
              const Divider(color: Color(0xFFF0F3F8), height: 24),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.background, Color(0xFF3059B7)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Total Pembayaran',
                      style: TextStyle(color: Color(0xFFD9E6FF), fontSize: 12),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _rupiah(_total),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '$_itemCount item dalam pesanan',
                      style: const TextStyle(
                        color: Color(0xFFD9E6FF),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'Pilih Metode Pembayaran',
          style: TextStyle(
            color: AppColors.ink,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 14),
        _method(
          'Tunai',
          'Bayar langsung di kasir',
          Icons.payments_rounded,
          const Color(0xFF087F6D),
          available: StoreSession.instance.methods['Tunai']!,
        ),
        _method(
          'QRIS',
          'Catat pembayaran QRIS di luar aplikasi',
          Icons.qr_code_2_rounded,
          AppColors.logoBlue,
          available: StoreSession.instance.methods['QRIS']!,
        ),
        const SizedBox(height: 8),
        if (_paymentMethod == 'Tunai')
          CashAmountInput(
            controller: _cashController,
            total: _total,
            onChanged: () => setState(() {}),
            onAmountSelected: _setCashAmount,
          ),
        if (_paymentMethod == 'QRIS')
          _panel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Pencatatan QRIS manual',
                  style: TextStyle(
                    color: AppColors.background,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Pelanggan membayar melalui QRIS toko di luar Nalara. Periksa pembayaran yang diterima, lalu catat transaksi di sini.',
                  style: TextStyle(
                    color: AppColors.muted,
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 12),
                Material(
                  color: Colors.transparent,
                  child: CheckboxListTile(
                    key: const ValueKey('qris-confirmed'),
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                    title: const Text(
                      'Saya sudah menerima pembayaran QRIS',
                      style: TextStyle(fontSize: 13),
                    ),
                    value: _qrisConfirmed,
                    onChanged: (value) =>
                        setState(() => _qrisConfirmed = value ?? false),
                  ),
                ),
              ],
            ),
          ),
      ],
    ),
  );

  // Preferensi toko menentukan metode yang dapat dipilih.
  Widget _method(
    String name,
    String subtitle,
    IconData icon,
    Color color, {
    bool available = true,
  }) {
    final selected = available && _paymentMethod == name;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Semantics(
        selected: selected,
        enabled: available,
        button: true,
        child: Material(
          color: selected ? const Color(0xFFF0F6FF) : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(17),
            side: BorderSide(
              color: selected ? AppColors.logoBlue : const Color(0xFFEDF1F7),
              width: selected ? 1.5 : 1,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            key: ValueKey('payment-method-$name'),
            onTap: available
                ? () => setState(() {
                    if (_paymentMethod != name) _qrisConfirmed = false;
                    _paymentMethod = name;
                  })
                : null,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(11),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Icon(
                      icon,
                      color: available ? color : color.withValues(alpha: 0.45),
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 7,
                          runSpacing: 4,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(
                              name,
                              style: TextStyle(
                                color: available
                                    ? AppColors.ink
                                    : AppColors.muted,
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                            ),
                            if (!available)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(5),
                                ),
                                child: const Text(
                                  'Dinonaktifkan',
                                  style: TextStyle(
                                    color: Color(0xFF94A3B8),
                                    fontSize: 8,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: const TextStyle(
                            color: Color(0xFF94A3B8),
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    selected
                        ? Icons.check_circle_rounded
                        : available
                        ? Icons.radio_button_unchecked_rounded
                        : Icons.lock_outline_rounded,
                    color: selected
                        ? AppColors.logoBlue
                        : const Color(0xFFCBD5E1),
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _paymentFooter() {
    final selected = [
      for (var i = 0; i < _products.length; i++)
        if (_quantities[i] > 0) _products[i],
    ];
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Color(0x050F172A),
            blurRadius: 18,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: Center(
        heightFactor: 1,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'TOTAL PEMBAYARAN',
                          style: TextStyle(
                            color: Color(0xFF94A3B8),
                            fontSize: 10,
                            letterSpacing: 0.6,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          _rupiah(_total),
                          style: const TextStyle(
                            color: Color(0xFF233E91),
                            fontSize: 23,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  for (final product in selected.take(2))
                    Padding(
                      padding: const EdgeInsets.only(left: 4),
                      child: ClipOval(
                        child: SizedBox(
                          width: 30,
                          height: 30,
                          child: ProductPhoto(product: product),
                        ),
                      ),
                    ),
                  if (selected.length > 2)
                    Padding(
                      padding: const EdgeInsets.only(left: 4),
                      child: CircleAvatar(
                        radius: 15,
                        backgroundColor: AppColors.background,
                        child: Text(
                          '+${selected.length - 2}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              FilledButton(
                key: ValueKey(
                  _paymentMethod == 'Tunai' ? 'pay-cash' : 'pay-qris',
                ),
                onPressed: _canPay ? _pay : null,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF233E91),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: const Color(0xFFE6ECF6),
                  disabledForegroundColor: const Color(0xFF94A3B8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 12,
                  ),
                  elevation: 3,
                  shadowColor: const Color(0x40233E91),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _paying
                            ? 'Menyimpan...'
                            : _paymentMethod == 'QRIS'
                            ? 'Catat QRIS ${_rupiah(_total)}'
                            : 'Bayar ${_rupiah(_total)}',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _canPay
                            ? const Color(0xFF3E59A2)
                            : const Color(0xFFD9E2F0),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: _paying
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.arrow_forward_rounded, size: 18),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Halaman sukses menampilkan hasil simulasi, jumlah bayar, dan identitas transaksi.
  Widget _success() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(24, 36, 24, 44),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF304D94), AppColors.background],
            ),
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
          ),
          child: Column(
            children: [
              // Kembali meninggalkan kasir tanpa menghapus riwayat transaksi selesai.
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    tooltip: 'Kembali',
                    onPressed: _back,
                    icon: const Icon(
                      Icons.chevron_left,
                      color: AppColors.white,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Lihat struk',
                    onPressed: _openReceipt,
                    icon: const Icon(
                      Icons.receipt_long,
                      color: AppColors.white,
                    ),
                  ),
                ],
              ),
              Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  color: const Color(0xFF0D9488),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF2DD4BF), width: 3),
                ),
                child: const Icon(
                  Icons.check,
                  color: AppColors.white,
                  size: 42,
                ),
              ),
              const SizedBox(height: 22),
              const Text(
                'Transaksi Berhasil',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Pembayaran ${_sale?.method ?? _paymentMethod} berhasil dicatat',
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.tagline, fontSize: 12),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _panel(
                child: Column(
                  children: [
                    const Text(
                      'TOTAL PEMBAYARAN',
                      style: TextStyle(
                        color: AppColors.muted,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _rupiah(_total),
                      style: const TextStyle(
                        color: AppColors.background,
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Divider(color: AppColors.border, height: 32),
                    _transactionDetails(),
                    if (_paymentMethod == 'Tunai')
                      _detail(
                        'Kembalian',
                        _rupiah(_cash - _total),
                        color: AppColors.green,
                      ),
                    const SizedBox(height: 18),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              if (_points > 0)
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFA855F7), AppColors.background],
                    ),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.stars, color: AppColors.white),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Poin Nalara Bertambah!',
                              style: TextStyle(
                                color: AppColors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            Text(
                              'Anda mendapatkan +$_points poin',
                              style: const TextStyle(
                                color: AppColors.tagline,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  // Detail transaksi dipakai bersama pada halaman sukses dan struk.
  Widget _transactionDetails() {
    return Column(
      children: [
        _detail('ID Transaksi', '#$_transactionId'),
        _detail('Tanggal & Waktu', _timeLabel),
        _detail('Metode Pembayaran', _sale?.method ?? _paymentMethod),
      ],
    );
  }

  // Footer berubah sesuai tahap: checkout, bayar, transaksi baru, atau berbagi/cetak.
  Widget _footer() {
    if (_step == _CashierStep.selection) return _orderBar();
    if (_step == _CashierStep.cart) return _cartSummary();
    if (_step == _CashierStep.payment) return _paymentFooter();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Center(
        heightFactor: 1,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_step == _CashierStep.payment) ...[
                const Text(
                  'TOTAL PEMBAYARAN',
                  style: TextStyle(color: AppColors.muted, fontSize: 10),
                ),
                Text(
                  _rupiah(_total),
                  style: const TextStyle(
                    color: AppColors.background,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 14),
              ],
              switch (_step) {
                _CashierStep.selection => _orderBar(),
                _CashierStep.cart => _primaryButton(
                  'Lanjut Pembayaran',
                  _menuCount == 0 ? null : () => _goTo(_CashierStep.payment),
                  Icons.arrow_forward,
                ),
                _CashierStep.payment => _primaryButton(
                  _paying ? 'Menyimpan...' : 'Bayar ${_rupiah(_total)}',
                  _paying ? null : _pay,
                  Icons.arrow_forward,
                ),
                // Aksi sukses berbagi lebar; teks dapat membungkus pada layar kecil.
                _CashierStep.success => Row(
                  children: [
                    Expanded(
                      child: _primaryButton(
                        'Transaksi Baru',
                        _newTransaction,
                        Icons.add_shopping_cart,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _openReceipt,
                        icon: const Icon(Icons.receipt_long, size: 18),
                        label: const Text('Lihat Struk'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.background,
                          side: const BorderSide(color: AppColors.border),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 16,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              },
            ],
          ),
        ),
      ),
    );
  }

  // Satu gaya tombol utama digunakan oleh keempat tahap kasir.
  Widget _primaryButton(String label, VoidCallback? onPressed, IconData icon) {
    return FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(width: 12),
          Icon(icon, size: 20),
        ],
      ),
    );
  }

  // Kolom fleksibel mencegah label dan nominal saling bertumpuk.
  Widget _detail(
    String label,
    String value, {
    Color color = AppColors.ink,
    bool bold = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: bold ? AppColors.ink : AppColors.muted,
                fontSize: bold ? 14 : 11,
                fontWeight: bold ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                color: color,
                fontSize: bold ? 16 : 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Gaya kartu menggunakan sudut, latar putih, dan bayangan yang seragam.
  Widget _panel({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.background.withValues(alpha: 0.03),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: child,
    );
  }
}
