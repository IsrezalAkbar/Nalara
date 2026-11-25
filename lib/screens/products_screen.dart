// Katalog mengikuti data produk bersama dan menyediakan pencarian serta filter.
import 'dart:ui' show ImmutableBuffer, ImageDescriptor;

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../colors.dart';
import '../firebase_store.dart';
import '../widgets/app_navigation.dart';
import '../products.dart';
import '../widgets/responsive_columns.dart';
import '../widgets/product_list_card.dart';
import 'cashier_screen.dart';
import 'profile_screen.dart';

const _categories = ['Minuman', 'Makanan', 'Barang', 'Lainnya'];

// Daftar menyediakan pencarian dan filter kategori sebelum membuka detail.
class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});
  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  final _search = TextEditingController();
  String _query = '';
  String _category = 'Semua';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _addProduct() => Navigator.of(context)
      .push(MaterialPageRoute<void>(builder: (_) => const ProductFormScreen()));

  Widget _contentWidth(Widget child) => Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 680),
      child: SizedBox(width: double.infinity, child: child),
    ),
  );

  void _resetFilters() {
    _search.clear();
    setState(() {
      _query = '';
      _category = 'Semua';
    });
  }

  Widget _header() {
    final catalog = ProductCatalog.instance.items;
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.background, Color(0xFF3059B7)],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: _contentWidth(
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 16,
                runSpacing: 14,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'KATALOG TOKO',
                        style: TextStyle(
                          color: Color(0xFFD9E6FF),
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.5,
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        'Produk',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -.7,
                        ),
                      ),
                    ],
                  ),
                  FilledButton.icon(
                    onPressed: _addProduct,
                    icon: const Icon(Icons.add_rounded, size: 19),
                    label: const Text('Tambah Produk'),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.background,
                      minimumSize: const Size(48, 46),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      textStyle: Theme.of(context).textTheme.labelLarge
                          ?.copyWith(fontSize: 12, fontWeight: FontWeight.w700),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              const Text(
                'Kelola harga dan pantau stok toko Anda.',
                style: TextStyle(
                  color: Color(0xFFD9E6FF),
                  fontSize: 12,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 22),
              LayoutBuilder(
                builder: (context, constraints) {
                  final scale = MediaQuery.textScalerOf(context).scale(12) / 12;
                  final columns = constraints.maxWidth >= 300 * scale ? 3 : 1;
                  final width =
                      (constraints.maxWidth - (columns - 1) * 10) / columns;
                  return Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      SizedBox(
                        width: width,
                        child: _CatalogMetric(
                          label: 'Total produk',
                          value: catalog.length,
                          icon: Icons.inventory_2_outlined,
                        ),
                      ),
                      SizedBox(
                        width: width,
                        child: _CatalogMetric(
                          label: 'Menipis',
                          value: catalog
                              .where(
                                (item) =>
                                    item.stockStatus == ProductStockStatus.low,
                              )
                              .length,
                          icon: Icons.warning_amber_rounded,
                          color: const Color(0xFFFFDF9B),
                        ),
                      ),
                      SizedBox(
                        width: width,
                        child: _CatalogMetric(
                          label: 'Habis',
                          value: catalog
                              .where(
                                (item) =>
                                    item.stockStatus ==
                                    ProductStockStatus.empty,
                              )
                              .length,
                          icon: Icons.remove_shopping_cart_outlined,
                          color: const Color(0xFFFFC9CB),
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _search,
                onChanged: (value) => setState(() => _query = value),
                textInputAction: TextInputAction.search,
                style: const TextStyle(fontSize: 14, color: AppColors.ink),
                decoration: InputDecoration(
                  hintText: 'Cari produk...',
                  hintStyle: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 13,
                  ),
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    color: AppColors.background,
                    size: 22,
                  ),
                  suffixIcon: _query.isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'Hapus pencarian',
                          icon: const Icon(Icons.close_rounded, size: 18),
                          onPressed: () {
                            _search.clear();
                            setState(() => _query = '');
                          },
                        ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
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
      ),
    );
  }

  Widget _filters() => _contentWidth(
    SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
      child: Row(
        children: [
          for (final category in ['Semua', ..._categories])
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
                  fontSize: 12,
                  fontWeight: _category == category
                      ? FontWeight.w700
                      : FontWeight.w500,
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                side: BorderSide(
                  color: _category == category
                      ? const Color(0xFF233E91)
                      : const Color(0xFFE4EBF5),
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
  );

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: ProductCatalog.instance,
    builder: (context, _) {
      final products = ProductCatalog.instance.items
          .where(
            (item) =>
                item.name.toLowerCase().contains(_query.toLowerCase().trim()) &&
                (_category == 'Semua' || item.category == _category),
          )
          .toList();
      final emptyCatalog = ProductCatalog.instance.items.isEmpty;
      return Scaffold(
        backgroundColor: const Color(0xFFF7F9FC),
        bottomNavigationBar: const NalaraNavigation(index: 2),
        body: SafeArea(
          bottom: false,
          child: CustomScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            slivers: [
              SliverToBoxAdapter(child: _header()),
              SliverToBoxAdapter(child: _filters()),
              SliverToBoxAdapter(
                child: _contentWidth(
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                    child: Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 12,
                      runSpacing: 8,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Flexible(
                              child: Text(
                                _query.isNotEmpty || _category != 'Semua'
                                    ? 'Hasil pencarian'
                                    : 'Daftar produk',
                                style: const TextStyle(
                                  color: AppColors.ink,
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 9,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.softBlue,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '${products.length}',
                                style: const TextStyle(
                                  color: AppColors.background,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (_query.isNotEmpty || _category != 'Semua')
                          TextButton(
                            onPressed: _resetFilters,
                            child: const Text('Reset filter'),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              if (products.isEmpty)
                SliverToBoxAdapter(
                  child: _contentWidth(
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 48,
                      ),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: AppColors.softBlue,
                              borderRadius: BorderRadius.circular(28),
                            ),
                            child: Icon(
                              emptyCatalog
                                  ? Icons.inventory_2_outlined
                                  : Icons.search_off_rounded,
                              size: 44,
                              color: AppColors.background,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            emptyCatalog
                                ? 'Belum ada produk'
                                : 'Produk tidak ditemukan',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: AppColors.ink,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            emptyCatalog
                                ? 'Tambahkan produk pertama untuk mulai mengelola stok.'
                                : 'Coba kata kunci atau kategori lainnya.',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: AppColors.muted,
                              fontSize: 13,
                            ),
                          ),
                          if (emptyCatalog) ...[
                            const SizedBox(height: 16),
                            FilledButton.icon(
                              onPressed: _addProduct,
                              icon: const Icon(Icons.add_rounded),
                              label: const Text('Tambah Produk Pertama'),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  sliver: SliverList.builder(
                    itemCount: products.length,
                    itemBuilder: (context, index) {
                      final product = products[index];
                      return _contentWidth(
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
                          child: ProductListCard(
                            key: ValueKey(product.id),
                            product: product,
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) =>
                                    ProductDetailScreen(id: product.id),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      );
    },
  );
}

class _CatalogMetric extends StatelessWidget {
  const _CatalogMetric({
    required this.label,
    required this.value,
    required this.icon,
    this.color = Colors.white,
  });
  final String label;
  final int value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: .09),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: Colors.white.withValues(alpha: .12)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                '$value',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(width: 4),
            Icon(icon, color: color, size: 17),
          ],
        ),
        const SizedBox(height: 5),
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFFD9E6FF),
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    ),
  );
}

// Dialog penambahan stok dipakai oleh detail produk dan detail insight.
Future<void> showAddProductStock(BuildContext context, Product product) async {
  final controller = TextEditingController();
  final key = GlobalKey<FormState>();
  final quantity = await showDialog<int>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Tambah Stok'),
      content: Form(
        key: key,
        child: TextFormField(
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: const InputDecoration(labelText: 'Jumlah tambahan'),
          validator: (value) => (int.tryParse(value ?? '') ?? 0) > 0
              ? null
              : 'Masukkan jumlah lebih dari nol.',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        FilledButton(
          onPressed: () {
            if (key.currentState!.validate()) {
              Navigator.pop(context, int.parse(controller.text));
            }
          },
          child: const Text('Tambah'),
        ),
      ],
    ),
  );
  // Dialog selesai dianimasikan sebelum controller dilepas.
  await Future<void>.delayed(const Duration(milliseconds: 300));
  controller.dispose();
  if (quantity != null) {
    try {
      await ProductCatalog.instance.addStock(product.id, quantity);
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(firebaseMessage(error))));
      }
    }
  }
}

// Detail membaca ulang produk berdasarkan ID agar edit langsung terlihat.
class ProductDetailScreen extends StatelessWidget {
  const ProductDetailScreen({super.key, required this.id});
  final String id;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ProductCatalog.instance,
      builder: (context, _) {
        if (!ProductCatalog.instance.items.any((product) => product.id == id)) {
          return const _ProductPage(
            title: 'Detail Produk',
            children: [Text('Produk tidak ditemukan.')],
          );
        }
        final product = ProductCatalog.instance.byId(id);
        return Scaffold(
          backgroundColor: const Color(0xFFF6F8FC),
          appBar: AppBar(
            backgroundColor: Colors.white,
            foregroundColor: AppColors.ink,
            surfaceTintColor: Colors.transparent,
            toolbarHeight: 76,
            titleSpacing: 8,
            leadingWidth: 68,
            leading: Padding(
              padding: const EdgeInsets.only(left: 20, top: 16, bottom: 16),
              child: _DetailHeaderButton(
                icon: Icons.arrow_back_rounded,
                tooltip: 'Kembali',
                highlighted: true,
                onPressed: () => Navigator.maybePop(context),
              ),
            ),
            title: const Text(
              'Detail Produk',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            actions: [
              _DetailHeaderButton(
                icon: Icons.point_of_sale_rounded,
                tooltip: 'Kasir',
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => const CashierScreen(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _DetailHeaderButton(
                icon: Icons.manage_accounts_rounded,
                tooltip: 'Profil',
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => const ProfileScreen(),
                  ),
                ),
              ),
              const SizedBox(width: 20),
            ],
          ),
          bottomNavigationBar: _DetailActions(
            onAddStock: () => showAddProductStock(context, product),
            onEdit: () => Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (_) => ProductFormScreen(product: product),
              ),
            ),
          ),
          body: SafeArea(
            bottom: false,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth:
                        MediaQuery.orientationOf(context) ==
                            Orientation.landscape
                        ? 960
                        : 520,
                  ),
                  child: ResponsiveColumns(
                    gap: 16,
                    children: [
                      _DetailPhoto(product: product),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _DetailSummary(product: product),
                          const SizedBox(height: 16),
                          _DetailStatistics(product: product),
                          const SizedBox(height: 16),
                          _DetailProfit(product: product),
                          const SizedBox(height: 16),
                          _DetailMetadata(product: product),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _DetailHeaderButton extends StatelessWidget {
  const _DetailHeaderButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.highlighted = false,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final bool highlighted;

  @override
  Widget build(BuildContext context) => IconButton.outlined(
    tooltip: tooltip,
    onPressed: onPressed,
    icon: Icon(icon, size: 20),
    style: IconButton.styleFrom(
      minimumSize: const Size(44, 44),
      foregroundColor: highlighted ? AppColors.logoBlue : AppColors.ink,
      backgroundColor: highlighted ? AppColors.softBlue : Colors.white,
      side: BorderSide(
        color: highlighted ? const Color(0xFFDBEAFE) : const Color(0xFFEDF1F7),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
  );
}

class _DetailCard extends StatelessWidget {
  const _DetailCard({required this.child, this.padding = 20});
  final Widget child;
  final double padding;

  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.all(padding),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: const Color(0xFFEDF1F7)),
    ),
    child: child,
  );
}

class _DetailPhoto extends StatelessWidget {
  const _DetailPhoto({required this.product});
  final Product product;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.only(bottom: 20),
    clipBehavior: Clip.antiAlias,
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(28),
      border: Border.all(color: const Color(0xFFEDF1F7)),
    ),
    child: Stack(
      children: [
        AspectRatio(aspectRatio: 1, child: ProductPhoto(product: product)),
        Positioned(
          top: 16,
          right: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: product.active
                  ? const Color(0xFF0D9488)
                  : const Color(0xFF64748B),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  product.active
                      ? Icons.inventory_2_rounded
                      : Icons.pause_circle_filled_rounded,
                  size: 13,
                  color: Colors.white,
                ),
                const SizedBox(width: 5),
                Text(
                  product.active ? 'AKTIF' : 'NONAKTIF',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

class _DetailSummary extends StatelessWidget {
  const _DetailSummary({required this.product});
  final Product product;

  @override
  Widget build(BuildContext context) => _DetailCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.softBlue,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                product.category.toUpperCase(),
                style: const TextStyle(
                  color: AppColors.logoBlue,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.4,
                ),
              ),
            ),
            if (product.favorite)
              const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.star_rounded, size: 16, color: AppColors.orange),
                  SizedBox(width: 3),
                  Text(
                    'Favorit',
                    style: TextStyle(
                      color: AppColors.orange,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          product.name,
          style: const TextStyle(
            color: AppColors.ink,
            fontSize: 24,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.6,
          ),
        ),
        const SizedBox(height: 16),
        _DetailPair(
          first: _DetailPrice(label: 'HARGA JUAL', value: product.price),
          second: _DetailPrice(label: 'HARGA MODAL', value: product.cost),
        ),
      ],
    ),
  );
}

// Kartu berpasangan tetap terbaca pada layar sempit dan ukuran teks besar.
class _DetailPair extends StatelessWidget {
  const _DetailPair({required this.first, required this.second});
  final Widget first;
  final Widget second;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      if (constraints.maxWidth < 260 ||
          MediaQuery.textScalerOf(context).scale(14) > 20) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [first, const SizedBox(height: 12), second],
        );
      }
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: first),
          const SizedBox(width: 14),
          Expanded(child: second),
        ],
      );
    },
  );
}

class _DetailPrice extends StatelessWidget {
  const _DetailPrice({required this.label, required this.value});
  final String label;
  final int value;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: const Color(0xFFF7F9FC),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: const Color(0xFFF0F3F8)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 9,
            letterSpacing: 0.7,
            fontWeight: FontWeight.w500,
            color: AppColors.muted,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          productRupiah(value),
          style: const TextStyle(
            color: AppColors.ink,
            fontSize: 17,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    ),
  );
}

class _DetailStatistics extends StatelessWidget {
  const _DetailStatistics({required this.product});
  final Product product;

  @override
  Widget build(BuildContext context) => _DetailPair(
    first: _stat(
      icon: Icons.inventory_2_rounded,
      label: 'Stok',
      value: product.stock,
      note: 'Min. Stok ${product.minimumStock}',
      color: AppColors.logoBlue,
      background: AppColors.softBlue,
      noteColor: product.stock <= product.minimumStock
          ? AppColors.orange
          : AppColors.muted,
    ),
    second: _stat(
      icon: Icons.shopping_bag_rounded,
      label: 'Total Terjual',
      value: product.sold,
      note: 'Unit terjual',
      color: AppColors.orange,
      background: const Color(0xFFFFF4CC),
      noteColor: const Color(0xFF0D9488),
    ),
  );

  Widget _stat({
    required IconData icon,
    required String label,
    required int value,
    required String note,
    required Color color,
    required Color background,
    required Color noteColor,
  }) => _DetailCard(
    padding: 18,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: background,
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(icon, color: color, size: 17),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(fontSize: 11, color: AppColors.muted),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Text(
          '$value Unit',
          style: const TextStyle(
            fontSize: 20,
            color: AppColors.ink,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 5),
        Text(note, style: TextStyle(fontSize: 10, color: noteColor)),
      ],
    ),
  );
}

class _DetailProfit extends StatelessWidget {
  const _DetailProfit({required this.product});
  final Product product;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(22),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF233E91), Color(0xFF3B82F6)],
      ),
      borderRadius: BorderRadius.circular(24),
      boxShadow: const [
        BoxShadow(
          color: Color(0x302563EB),
          blurRadius: 12,
          offset: Offset(0, 5),
        ),
      ],
    ),
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'ESTIMASI KEUNTUNGAN / UNIT',
                style: TextStyle(
                  color: Color(0xFFDCE8FF),
                  fontSize: 9,
                  letterSpacing: 0.4,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                productRupiah(product.price - product.cost),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Container(
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            color: const Color(0xFF8075EE),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(
            Icons.account_balance_wallet_rounded,
            color: Color(0xFFF0ABFC),
            size: 24,
          ),
        ),
      ],
    ),
  );
}

class _DetailMetadata extends StatelessWidget {
  const _DetailMetadata({required this.product});
  final Product product;

  @override
  Widget build(BuildContext context) {
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
    final date = product.updatedAt.toLocal();
    return _DetailCard(
      child: Column(
        children: [
          _row(Icons.info_rounded, 'ID Produk', product.id, AppColors.logoBlue),
          const SizedBox(height: 16),
          _row(
            Icons.bar_chart_rounded,
            'Terakhir Diupdate',
            '${date.day} ${months[date.month - 1]} ${date.year}',
            AppColors.ink,
          ),
        ],
      ),
    );
  }

  Widget _row(IconData icon, String label, String value, Color color) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(icon, size: 17, color: color),
      const SizedBox(width: 9),
      Expanded(
        child: Text(
          label,
          style: const TextStyle(
            color: AppColors.ink,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      const SizedBox(width: 12),
      Flexible(
        child: SelectableText(
          value,
          textAlign: TextAlign.right,
          style: const TextStyle(color: AppColors.muted, fontSize: 12),
        ),
      ),
    ],
  );
}

class _DetailActions extends StatelessWidget {
  const _DetailActions({required this.onAddStock, required this.onEdit});
  final VoidCallback onAddStock;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) => Container(
    decoration: const BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      boxShadow: [
        BoxShadow(
          color: Color(0x060F172A),
          blurRadius: 20,
          offset: Offset(0, -4),
        ),
      ],
    ),
    child: SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
        child: Center(
          heightFactor: 1,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: _DetailPair(
              first: OutlinedButton.icon(
                onPressed: onAddStock,
                icon: const Icon(Icons.add_box_outlined, size: 19),
                label: const Text('Tambah Stok'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.logoBlue,
                  minimumSize: const Size.fromHeight(52),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 14,
                  ),
                  side: const BorderSide(color: Color(0xFFEDF1F7)),
                  textStyle: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
              second: FilledButton.icon(
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined, size: 19),
                label: const Text('Edit Produk'),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF233E91),
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(52),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 14,
                  ),
                  elevation: 3,
                  shadowColor: const Color(0x40233E91),
                  textStyle: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

// Form yang sama digunakan untuk tambah dan edit agar aturan input konsisten.
class ProductFormScreen extends StatefulWidget {
  const ProductFormScreen({super.key, this.product});
  final Product? product;
  @override
  State<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends State<ProductFormScreen> {
  final _key = GlobalKey<FormState>();
  late final TextEditingController _name, _price, _cost, _stock, _minimum;
  late String _category;
  late bool _active, _favorite;
  Uint8List? _photo;
  String? _asset;
  bool _selecting = false;
  bool _saving = false;
  bool _removePhoto = false;

  // Nilai awal diambil dari produk saat edit; produk baru dimulai dengan form kosong.
  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _name = TextEditingController(text: p?.name ?? '');
    _price = TextEditingController(text: p?.price.toString() ?? '');
    _cost = TextEditingController(text: p?.cost.toString() ?? '');
    _stock = TextEditingController(text: p?.stock.toString() ?? '0');
    _minimum = TextEditingController(text: p?.minimumStock.toString() ?? '0');
    _category = p?.category ?? 'Minuman';
    _active = p?.active ?? true;
    _favorite = p?.favorite ?? false;
    _photo = p?.photo;
    _asset = p?.assetPath;
  }

  @override
  void dispose() {
    for (final controller in [_name, _price, _cost, _stock, _minimum]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    setState(() => _selecting = true);
    try {
      final file = await openFile(
        acceptedTypeGroups: [
          const XTypeGroup(
            label: 'Foto produk',
            extensions: ['jpg', 'jpeg', 'png', 'webp'],
            mimeTypes: ['image/jpeg', 'image/png', 'image/webp'],
            uniformTypeIdentifiers: [
              'public.jpeg',
              'public.png',
              'org.webmproject.webp',
            ],
          ),
        ],
      );
      if (file == null) return;
      if (await file.length() > 5 * 1024 * 1024) {
        throw Exception('Ukuran foto maksimal 5 MB.');
      }
      final bytes = await file.readAsBytes();
      // Dekode memastikan file benar-benar gambar, bukan sekadar berekstensi gambar.
      final buffer = await ImmutableBuffer.fromUint8List(bytes);
      final descriptor = await ImageDescriptor.encoded(buffer);
      descriptor.dispose();
      buffer.dispose();
      if (mounted) {
        setState(() {
          _photo = bytes;
          _asset = null;
        });
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              error.toString().contains('5 MB')
                  ? 'Ukuran foto maksimal 5 MB.'
                  : 'Foto tidak dapat dibuka. Pilih gambar lain.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _selecting = false);
    }
  }

  // Simpan hanya ketika form valid; pembatalan tidak mengubah katalog.
  Future<void> _save() async {
    if (_saving) return;
    if (!_key.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    final previous = widget.product;
    setState(() => _saving = true);
    try {
      await ProductCatalog.instance.save(
        Product(
          id: previous?.id ?? accountRef.collection('products').doc().id,
          name: _name.text.trim(),
          category: _category,
          price: int.parse(_price.text),
          cost: int.parse(_cost.text),
          stock: int.parse(_stock.text),
          minimumStock: int.parse(_minimum.text),
          active: _active,
          favorite: _favorite,
          sold: previous?.sold ?? 0,
          photo: _photo,
          photoUrl: _removePhoto ? null : previous?.photoUrl,
          assetPath: _asset,
        ),
        previous: previous,
      );
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Produk berhasil disimpan.')),
      );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(firebaseMessage(error))));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _fieldLabel(String label, Widget field) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(
        label.toUpperCase(),
        style: const TextStyle(
          color: Color(0xFF526889),
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
        ),
      ),
      const SizedBox(height: 9),
      field,
    ],
  );

  InputDecoration _inputDecoration({
    String? hint,
    IconData? icon,
    bool money = false,
    bool warning = false,
    bool accent = false,
  }) {
    final color = warning ? AppColors.orange : AppColors.muted;
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(
        color: warning ? const Color(0xFFFDE9B5) : const Color(0xFFE5EBF4),
      ),
    );
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(
        color: Color(0xFF9AA9BE),
        fontWeight: FontWeight.w400,
      ),
      filled: true,
      fillColor: warning ? const Color(0xFFFFFBEB) : const Color(0xFFF7F9FC),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      prefixIcon: money
          ? Padding(
              padding: const EdgeInsets.only(left: 14, right: 8),
              child: Text(
                'Rp',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: accent ? AppColors.background : AppColors.muted,
                ),
              ),
            )
          : icon == null
          ? null
          : Icon(icon, size: 18, color: color),
      prefixIconConstraints: money ? const BoxConstraints(minWidth: 38) : null,
      border: border,
      enabledBorder: border,
      focusedBorder: border.copyWith(
        borderSide: const BorderSide(color: AppColors.logoBlue, width: 1.5),
      ),
      errorBorder: border.copyWith(
        borderSide: BorderSide(color: Theme.of(context).colorScheme.error),
      ),
      focusedErrorBorder: border.copyWith(
        borderSide: BorderSide(
          color: Theme.of(context).colorScheme.error,
          width: 1.5,
        ),
      ),
      errorMaxLines: 3,
    );
  }

  // Nilai tetap berupa angka bulat agar validasi dan penyimpanan konsisten.
  Widget _number(
    String label,
    TextEditingController controller, {
    bool price = false,
    bool positive = false,
    bool warning = false,
    IconData? icon,
    bool updateStock = false,
  }) => _fieldLabel(
    label,
    TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      textInputAction: TextInputAction.next,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      onChanged: updateStock ? (_) => setState(() {}) : null,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: warning
            ? AppColors.orange
            : positive
            ? AppColors.logoBlue
            : AppColors.ink,
      ),
      decoration: _inputDecoration(
        hint: '0',
        money: price,
        icon: icon,
        warning: warning,
        accent: positive,
      ),
      validator: (value) {
        final number = int.tryParse(value ?? '');
        if (number == null || number < (positive ? 1 : 0)) {
          return positive
              ? 'Masukkan nilai lebih dari nol.'
              : 'Masukkan angka nol atau lebih.';
        }
        return null;
      },
    ),
  );

  Widget _photoPicker(Product preview) {
    final hasPhoto =
        preview.photo != null ||
        preview.assetPath != null ||
        preview.photoUrl != null;
    return _fieldLabel(
      'Foto Produk',
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            button: true,
            label: hasPhoto ? 'Ganti foto produk' : 'Pilih foto produk',
            child: Material(
              color: const Color(0xFFF3F7FB),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: Color(0xFFD5DFED)),
              ),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: _selecting || _saving ? null : _pickPhoto,
                child: AspectRatio(
                  aspectRatio: 1.08,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (hasPhoto)
                        ProductPhoto(product: preview)
                      else
                        const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.add_photo_alternate_outlined,
                              size: 42,
                              color: AppColors.logoBlue,
                            ),
                            SizedBox(height: 12),
                            Text(
                              'Tambahkan foto produk',
                              style: TextStyle(
                                color: AppColors.background,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(height: 6),
                            Text(
                              'JPG, PNG, atau WebP · Maks. 5 MB',
                              style: TextStyle(
                                color: AppColors.muted,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      if (hasPhoto)
                        Positioned(
                          right: 10,
                          bottom: 10,
                          child: IgnorePointer(
                            child: Container(
                              padding: const EdgeInsets.all(9),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.95),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.camera_alt_outlined,
                                size: 20,
                                color: AppColors.background,
                              ),
                            ),
                          ),
                        ),
                      if (_selecting)
                        const ColoredBox(
                          color: Color(0xCCFFFFFF),
                          child: Center(child: CircularProgressIndicator()),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (hasPhoto)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: _saving || _selecting
                    ? null
                    : () => setState(() {
                        _photo = null;
                        _removePhoto = true;
                        _asset = null;
                      }),
                icon: const Icon(Icons.delete_outline, size: 16),
                label: const Text('Hapus Foto', style: TextStyle(fontSize: 12)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _stockStatus(bool safe) {
    final color = safe ? const Color(0xFF10B981) : AppColors.orange;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: safe ? const Color(0xFFF0FDF6) : const Color(0xFFFFFBEB),
        border: Border.all(
          color: safe ? const Color(0xFFD7F7E7) : const Color(0xFFFDE9B5),
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              safe ? Icons.check_rounded : Icons.priority_high_rounded,
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'STATUS STOK',
                  style: TextStyle(
                    color: color,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  safe ? 'Stok Aman' : 'Stok Menipis',
                  style: TextStyle(
                    color: safe
                        ? const Color(0xFF047857)
                        : const Color(0xFFB45309),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                safe ? 'AMAN' : 'MENIPIS',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final stock = int.tryParse(_stock.text) ?? 0;
    final minimum = int.tryParse(_minimum.text) ?? 0;
    final editing = widget.product != null;
    final preview = Product(
      id: '',
      name: '',
      price: 0,
      cost: 0,
      stock: 0,
      minimumStock: 0,
      category: _category,
      photo: _photo,
      photoUrl: _removePhoto ? null : widget.product?.photoUrl,
      assetPath: _asset,
    );
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      bottomNavigationBar: Container(
        color: Colors.white,
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
            child: Center(
              heightFactor: 1,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: FilledButton.icon(
                  onPressed: _selecting || _saving ? null : _save,
                  icon: _saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save_rounded, size: 18),
                  label: Text(_saving ? 'Menyimpan...' : 'Simpan Produk'),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF233E91),
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(52),
                    elevation: 4,
                    shadowColor: const Color(0x40233E91),
                    textStyle: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          Container(
            height: MediaQuery.paddingOf(context).top + 128,
            decoration: const BoxDecoration(
              color: Color(0xFF233E86),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
            ),
          ),
          SafeArea(
            bottom: false,
            child: SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth:
                        MediaQuery.orientationOf(context) ==
                            Orientation.landscape
                        ? 960
                        : 560,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          IconButton(
                            tooltip: 'Kembali',
                            onPressed: () => Navigator.maybePop(context),
                            icon: const Icon(Icons.chevron_left_rounded),
                            style: IconButton.styleFrom(
                              backgroundColor: const Color(0xFF3A5396),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  editing ? 'Edit Produk' : 'Tambah Produk',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  editing
                                      ? 'Perbarui detail produk Anda'
                                      : 'Lengkapi detail produk baru Anda',
                                  style: const TextStyle(
                                    color: Color(0xFFD8E3FF),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      _DetailCard(
                        padding: 24,
                        child: Form(
                          key: _key,
                          child: ResponsiveColumns(
                            gap: 24,
                            children: [
                              _photoPicker(preview),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  _fieldLabel(
                                    'Nama Produk',
                                    TextFormField(
                                      controller: _name,
                                      textCapitalization:
                                          TextCapitalization.words,
                                      textInputAction: TextInputAction.next,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.ink,
                                      ),
                                      decoration: _inputDecoration(
                                        hint: 'Masukkan nama produk',
                                        icon: Icons.inventory_2_rounded,
                                      ),
                                      validator: (value) =>
                                          value == null || value.trim().isEmpty
                                          ? 'Nama produk wajib diisi.'
                                          : null,
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  _fieldLabel(
                                    'Kategori',
                                    DropdownButtonFormField<String>(
                                      initialValue: _category,
                                      isExpanded: true,
                                      icon: const Icon(
                                        Icons.keyboard_arrow_down_rounded,
                                        size: 20,
                                        color: Color(0xFF9AA9BE),
                                      ),
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.ink,
                                      ),
                                      decoration: _inputDecoration(
                                        icon: Icons.sell_rounded,
                                      ),
                                      items: _categories
                                          .map(
                                            (value) => DropdownMenuItem(
                                              value: value,
                                              child: Text(value),
                                            ),
                                          )
                                          .toList(),
                                      onChanged: (value) => setState(
                                        () => _category = value ?? 'Minuman',
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  _DetailPair(
                                    first: _number(
                                      'Harga Jual',
                                      _price,
                                      price: true,
                                      positive: true,
                                    ),
                                    second: _number(
                                      'Harga Modal',
                                      _cost,
                                      price: true,
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  _DetailPair(
                                    first: _number(
                                      editing ? 'Stok' : 'Stok Awal',
                                      _stock,
                                      icon: Icons.layers_rounded,
                                      updateStock: true,
                                    ),
                                    second: _number(
                                      'Min. Stok',
                                      _minimum,
                                      icon: Icons.warning_rounded,
                                      warning: true,
                                      updateStock: true,
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  _stockStatus(stock > minimum),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Opsi lama tetap tersedia tanpa memenuhi form utama.
                      ExpansionTile(
                        tilePadding: const EdgeInsets.symmetric(horizontal: 16),
                        shape: const Border(),
                        collapsedShape: const Border(),
                        iconColor: AppColors.muted,
                        collapsedIconColor: AppColors.muted,
                        title: const Text(
                          'Pengaturan tambahan',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.muted,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        children: [
                          SwitchListTile(
                            title: const Text(
                              'Produk Aktif',
                              style: TextStyle(fontSize: 14),
                            ),
                            value: _active,
                            onChanged: _saving
                                ? null
                                : (value) => setState(() => _active = value),
                          ),
                          CheckboxListTile(
                            title: const Text(
                              'Favorit',
                              style: TextStyle(fontSize: 14),
                            ),
                            value: _favorite,
                            onChanged: _saving
                                ? null
                                : (value) => setState(
                                    () => _favorite = value ?? false,
                                  ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Kerangka bersama menjaga header penuh, ruang isi responsif, dan akses saat keyboard terbuka.
class _ProductPage extends StatelessWidget {
  const _ProductPage({required this.title, required this.children});
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
