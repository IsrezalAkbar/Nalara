// Mengimpor komponen tampilan, warna bersama, dan tujuan setelah setup selesai.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../colors.dart';
import '../session.dart';
import '../firebase_store.dart';
import '../widgets/responsive_columns.dart';
import 'home_screen.dart';

// Halaman pelengkap detail toko setelah pengguna menekan Daftar.
class StoreSetupScreen extends StatefulWidget {
  const StoreSetupScreen({super.key});

  @override
  State<StoreSetupScreen> createState() => _StoreSetupScreenState();
}

class _StoreSetupScreenState extends State<StoreSetupScreen> {
  // Pilihan jenis usaha disimpan sementara selama halaman ini terbuka.
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _address = TextEditingController();
  bool _busy = false;
  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _address.dispose();
    super.dispose();
  }

  String _businessType = 'Makanan & Minuman';
  static const _businessTypes = [
    'Makanan & Minuman',
    'Retail & Toko',
    'Jasa',
    'Lainnya',
  ];

  Future<void> _startBusiness() async {
    if (_busy) return;
    if (_name.text.trim().isEmpty ||
        _address.text.trim().isEmpty ||
        !RegExp(r'^\+?[0-9]{8,15}$').hasMatch(_phone.text.trim())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lengkapi nama, alamat, dan nomor telepon yang valid.'),
        ),
      );
      return;
    }
    setState(() => _busy = true);
    try {
      await StoreSession.instance.saveProfile({
        'storeName': _name.text.trim(),
        'category': _businessType,
        'phone': _phone.text.trim(),
        'address': _address.text.trim(),
      });
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute<void>(builder: (_) => const HomeScreen()),
        (_) => false,
      );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(firebaseMessage(error))));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  // Gaya input seragam dengan ikon kiri dan garis pembatas yang lembut.
  InputDecoration _decoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFF9AA6BB), fontSize: 14),
      prefixIcon: Icon(icon, size: 19, color: const Color(0xFF94A3B8)),
      filled: true,
      fillColor: AppColors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.border),
      ),
    );
  }

  // Label huruf kapital ditempatkan di atas setiap input seperti pada referensi.
  Widget _label(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.muted,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // Tautan kebijakan membuka dialog; dokumen resmi belum ditambahkan.
  Future<void> _showPolicy() async {
    String content;
    try {
      final document = await FirebaseFirestore.instance
          .collection('configuration')
          .doc('legal')
          .get();
      content =
          document.data()?['text'] as String? ??
          'Dokumen syarat, ketentuan, dan kebijakan privasi belum tersedia.';
    } catch (error) {
      content = firebaseMessage(error);
    }
    if (!mounted) return;
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Syarat & Ketentuan'),
        content: SingleChildScrollView(child: Text(content)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final landscape =
        MediaQuery.orientationOf(context) == Orientation.landscape;
    // Batas lebar mengikuti orientasi; form tetap dapat digulir saat keyboard muncul.
    // Warna bilah sistem mengikuti header biru dan latar form yang terang.
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: AppColors.background,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: AppColors.surface,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: AppColors.surface,
        // Scroll memberi ruang ketika keyboard terbuka atau teks diperbesar.
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: landscape ? 1000 : 480,
                    ),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Header dan ilustrasi toko bertumpuk seperti desain Figma.
                          _buildHeader(),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(24, 32, 24, 0),
                            child: ResponsiveColumns(
                              gap: 24,
                              children: [
                                Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    _label('NAMA USAHA'),
                                    TextFormField(
                                      key: const ValueKey('store_name'),
                                      controller: _name,
                                      textCapitalization:
                                          TextCapitalization.words,
                                      textInputAction: TextInputAction.next,
                                      decoration: _decoration(
                                        'Nama usaha Anda',
                                        Icons.home_rounded,
                                      ),
                                    ),
                                  ],
                                ),
                                // Dropdown jenis usaha memperbarui pilihan pada UI.
                                Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    _label('JENIS USAHA'),
                                    DropdownButtonFormField<String>(
                                      key: const ValueKey('business_type'),
                                      initialValue: _businessType,
                                      isExpanded: true,
                                      // Tinggi menu mengikuti teks; pilihan terpilih cukup satu baris.
                                      itemHeight: null,
                                      selectedItemBuilder: (context) =>
                                          _businessTypes
                                              .map(
                                                (type) => Align(
                                                  alignment:
                                                      Alignment.centerLeft,
                                                  child: Text(
                                                    type,
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              )
                                              .toList(),
                                      icon: const Icon(
                                        Icons.keyboard_arrow_down,
                                        color: Color(0xFF94A3B8),
                                        size: 20,
                                      ),
                                      decoration: _decoration(
                                        '',
                                        Icons.work_rounded,
                                      ),
                                      style: const TextStyle(
                                        color: AppColors.ink,
                                        fontSize: 14,
                                      ),
                                      items: _businessTypes
                                          .map(
                                            (type) => DropdownMenuItem(
                                              value: type,
                                              child: Text(type),
                                            ),
                                          )
                                          .toList(),
                                      onChanged: (value) {
                                        if (value != null) {
                                          setState(() => _businessType = value);
                                        }
                                      },
                                    ),
                                  ],
                                ),
                                // Keyboard telepon memudahkan pengisian nomor usaha.
                                Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    _label('NOMOR HP USAHA'),
                                    TextFormField(
                                      key: const ValueKey('store_phone'),
                                      controller: _phone,
                                      keyboardType: TextInputType.phone,
                                      textInputAction: TextInputAction.next,
                                      decoration: _decoration(
                                        '08xx xxxx xxxx',
                                        Icons.phone_rounded,
                                      ),
                                    ),
                                  ],
                                ),
                                // Alamat memiliki beberapa baris dan tetap bisa bertambah tinggi.
                                Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    _label('ALAMAT USAHA'),
                                    TextFormField(
                                      key: const ValueKey('store_address'),
                                      controller: _address,
                                      minLines: 2,
                                      maxLines: 4,
                                      keyboardType: TextInputType.multiline,
                                      textCapitalization:
                                          TextCapitalization.sentences,
                                      decoration:
                                          _decoration(
                                            'Masukkan alamat lengkap usaha kamu',
                                            Icons.location_on_rounded,
                                          ).copyWith(
                                            prefixIconConstraints:
                                                const BoxConstraints(
                                                  minWidth: 48,
                                                  minHeight: 48,
                                                ),
                                          ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 40),
                          // Tombol mengikuti form sehingga tetap terjangkau melalui scroll.
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: FilledButton(
                              onPressed: _busy ? null : _startBusiness,
                              style: FilledButton.styleFrom(
                                backgroundColor: AppColors.background,
                                foregroundColor: AppColors.white,
                                minimumSize: const Size.fromHeight(54),
                                elevation: 4,
                                shadowColor: AppColors.background.withValues(
                                  alpha: 0.3,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Flexible(
                                    child: Text(
                                      'Mulai Kelola Bisnis',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 12),
                                  Icon(Icons.arrow_forward, size: 18),
                                ],
                              ),
                            ),
                          ),
                          // Catatan kebijakan berada di bawah tombol dan dapat ditekan.
                          Padding(
                            padding: const EdgeInsets.fromLTRB(32, 16, 32, 24),
                            child: InkWell(
                              onTap: _showPolicy,
                              child: const Text.rich(
                                TextSpan(
                                  children: [
                                    TextSpan(
                                      text:
                                          'Dengan mendaftar, kamu menyetujui ',
                                    ),
                                    TextSpan(
                                      text: 'Syarat & Ketentuan',
                                      style: TextStyle(
                                        color: AppColors.logoBlue,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    TextSpan(
                                      text: ' serta Kebijakan Privasi kami.',
                                    ),
                                  ],
                                ),
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Color(0xFF94A3B8),
                                  fontSize: 10,
                                  height: 1.5,
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
            },
          ),
        ),
      ),
    );
  }

  // Header biru dengan sudut bawah membulat; tinggi menyesuaikan isi teks.
  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          width: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF2D488F), AppColors.background],
            ),
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(36)),
          ),
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 80),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Kembali mempertahankan halaman daftar di bawah halaman setup.
              DecoratedBox(
                decoration: BoxDecoration(
                  color: AppColors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.white.withValues(alpha: 0.2),
                  ),
                ),
                child: IconButton(
                  tooltip: 'Kembali ke daftar',
                  onPressed: () => Navigator.of(context).maybePop(),
                  icon: const Icon(Icons.chevron_left, color: AppColors.white),
                  constraints: const BoxConstraints(
                    minWidth: 40,
                    minHeight: 40,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Lengkapi Toko Kamu',
                style: TextStyle(
                  color: AppColors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Sedikit lagi untuk mulai mengelola bisnis kamu dengan lebih mudah.',
                style: TextStyle(
                  color: Color(0xFFD6E0FA),
                  fontSize: 14,
                  height: 1.6,
                ),
              ),
            ],
          ),
        ),
        // Ilustrasi toko digambar dengan Canvas agar tampil konsisten antarperangkat.
        // Transform menumpuk ilustrasi pada header; Align mengurangi ruang sisanya.
        Transform.translate(
          offset: const Offset(0, -40),
          child: Align(
            heightFactor: 0.7,
            alignment: Alignment.topCenter,
            child: Container(
              width: 144,
              height: 144,
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.background.withValues(alpha: 0.05),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Semantics(
                label: 'Ilustrasi toko',
                image: true,
                child: const Center(
                  child: SizedBox(
                    width: 110,
                    height: 100,
                    child: CustomPaint(painter: _StoreIllustrationPainter()),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// Ilustrasi fasad toko biru: atap, kanopi, jendela, pintu, dan alas.
class _StoreIllustrationPainter extends CustomPainter {
  const _StoreIllustrationPainter();

  @override
  void paint(Canvas canvas, Size size) {
    // Koordinat menggunakan bidang 110 x 100 agar semua bagian mudah dipahami.
    canvas.save();
    canvas.scale(size.width / 110, size.height / 100);

    // Alas lembut di bawah toko dan dinding utama berwarna biru pucat.
    canvas.drawOval(
      const Rect.fromLTWH(4, 88, 102, 6),
      Paint()..color = const Color(0xFFE0F2FE),
    );
    canvas.drawRect(
      const Rect.fromLTWH(22, 30, 68, 58),
      Paint()..color = const Color(0xFF91B5D6),
    );
    canvas.drawRect(
      const Rect.fromLTWH(27, 35, 58, 53),
      Paint()..color = const Color(0xFFBED8E9),
    );

    // Atap etage biru dengan tepian terang seperti gambar referensi.
    canvas.drawRect(
      const Rect.fromLTWH(19, 17, 74, 7),
      Paint()..color = const Color(0xFF93C5E8),
    );
    canvas.drawRect(
      const Rect.fromLTWH(21, 24, 70, 5),
      Paint()..color = const Color(0xFF3E6F9C),
    );

    // Kanopi bergaris biru-putih dengan ujung membulat.
    for (var index = 0; index < 6; index++) {
      final x = 22.0 + index * 11;
      final color = index.isEven
          ? const Color(0xFF5799BD)
          : const Color(0xFFEAF6FB);
      final stripe = Path()
        ..moveTo(x + 2, 29)
        ..lineTo(x + 10, 29)
        ..lineTo(x + 11, 37)
        ..lineTo(x, 37)
        ..close();
      canvas.drawPath(stripe, Paint()..color = color);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, 35, 11, 6),
          const Radius.circular(3),
        ),
        Paint()..color = color,
      );
    }

    // Dua etalase mengapit pintu; rak berisi bentuk produk berwarna.
    for (final x in [29.0, 69.0]) {
      canvas.drawRect(
        Rect.fromLTWH(x, 46, 14, 35),
        Paint()..color = const Color(0xFF536392),
      );
      canvas.drawRect(
        Rect.fromLTWH(x + 2, 48, 10, 31),
        Paint()..color = const Color(0xFFCAE8F3),
      );
      for (var row = 0; row < 3; row++) {
        final y = 51.0 + row * 9;
        canvas.drawRect(
          Rect.fromLTWH(x + 3, y, 3, 6),
          Paint()..color = const Color(0xFF9B83BC),
        );
        canvas.drawRect(
          Rect.fromLTWH(x + 8, y, 3, 6),
          Paint()..color = const Color(0xFF649BC0),
        );
        canvas.drawRect(
          Rect.fromLTWH(x + 1, y + 6, 12, 2),
          Paint()..color = const Color(0xFF536392),
        );
      }
    }

    // Pintu kaca dan anak tangga berada di tengah fasad toko.
    canvas.drawRect(
      const Rect.fromLTWH(48, 45, 16, 40),
      Paint()..color = const Color(0xFF536392),
    );
    canvas.drawRect(
      const Rect.fromLTWH(51, 48, 10, 34),
      Paint()..color = const Color(0xFFE5F5FA),
    );
    canvas.drawRect(
      const Rect.fromLTWH(55, 49, 2, 32),
      Paint()..color = const Color(0xFF8BB6CF),
    );
    canvas.drawCircle(
      const Offset(59, 68),
      1,
      Paint()..color = const Color(0xFF536392),
    );
    canvas.drawRect(
      const Rect.fromLTWH(45, 85, 22, 3),
      Paint()..color = const Color(0xFF709DBA),
    );
    canvas.drawRect(
      const Rect.fromLTWH(20, 88, 73, 3),
      Paint()..color = const Color(0xFF91B5D6),
    );
    canvas.restore();
  }

  // Ilustrasi tetap sehingga tidak perlu digambar ulang saat form berubah.
  @override
  bool shouldRepaint(covariant _StoreIllustrationPainter oldDelegate) => false;
}
