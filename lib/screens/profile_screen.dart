import 'package:flutter/material.dart';

import '../colors.dart';
import '../widgets/app_navigation.dart';
import '../widgets/responsive_columns.dart';
import '../widgets/profile_components.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../session.dart';
import '../firebase_store.dart';
import 'package_screen.dart';
import 'shifts_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _session = StoreSession.instance;
  String get _name => _session.name;
  String get _email => _session.email;
  String get _store => _session.storeName;
  String get _category => _session.profile['category'] as String? ?? '';
  String get _address => _session.profile['address'] as String? ?? '';
  String get _phone => _session.profile['phone'] as String? ?? '';
  @override
  void initState() {
    super.initState();
    _session.addListener(_refresh);
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _session.removeListener(_refresh);
    super.dispose();
  }

  Future<void> _edit({bool store = false}) async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => _ProfileForm(
          store: store,
          values: store
              ? [_store, _category, _address, _phone]
              : [_name, _email],
        ),
      ),
    );
  }

  Future<void> _notificationsDialog() async {
    var enabled = _session.notifications;
    var busy = false;
    String? error;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, update) => ProfileDialog(
          icon: Icons.notifications_outlined,
          description:
              'Atur pemberitahuan untuk membantu memantau aktivitas toko Anda.',
          title: const Text('Notifikasi'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text(
                  'Aktifkan Notifikasi',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                ),
                subtitle: Text(
                  enabled ? 'Notifikasi aktif' : 'Notifikasi nonaktif',
                  style: const TextStyle(fontSize: 12, color: AppColors.muted),
                ),
                value: enabled,
                onChanged: busy
                    ? null
                    : (value) async {
                        update(() {
                          busy = true;
                          error = null;
                        });
                        try {
                          await _session.setNotifications(value);
                          if (context.mounted) update(() => enabled = value);
                        } catch (failure) {
                          if (context.mounted) {
                            update(() => error = firebaseMessage(failure));
                          }
                        } finally {
                          if (context.mounted) update(() => busy = false);
                        }
                      },
              ),
              if (busy) const LinearProgressIndicator(),
              if (error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    error!,
                    style: const TextStyle(color: Color(0xFFD64550)),
                  ),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: busy ? null : () => Navigator.pop(context),
              child: const Text('Selesai'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _help() async {
    final controller = TextEditingController();
    var busy = false;
    String? error;
    await showDialog<void>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, update) => ProfileDialog(
          icon: Icons.support_agent_rounded,
          description: 'Ceritakan kendala yang Anda temui. Pesan akan disimpan sebagai tiket bantuan.',
          title: const Text('Bantuan'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                minLines: 3,
                maxLines: 6,
                maxLength: 2000,
                decoration: profileInput('Jelaskan kendala Anda'),
              ),
              if (error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    error!,
                    style: const TextStyle(color: Color(0xFFD64550)),
                  ),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: busy ? null : () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: busy
                  ? null
                  : () async {
                      if (controller.text.trim().isEmpty) {
                        update(
                          () =>
                              error = 'Tuliskan kendala Anda terlebih dahulu.',
                        );
                        return;
                      }
                      update(() {
                        busy = true;
                        error = null;
                      });
                      try {
                        await accountRef.collection('supportTickets').add({
                          'message': controller.text.trim(),
                          'status': 'open',
                          'createdAt': FieldValue.serverTimestamp(),
                        });
                        if (context.mounted) Navigator.pop(context);
                        if (mounted) {
                          _information(
                            'Bantuan',
                            'Tiket bantuan berhasil disimpan.',
                          );
                        }
                      } catch (failure) {
                        if (context.mounted) {
                          update(() {
                            busy = false;
                            error = firebaseMessage(failure);
                          });
                        }
                      }
                    },
              child: Text(busy ? 'Menyimpan...' : 'Kirim'),
            ),
          ],
        ),
      ),
    );
    await Future<void>.delayed(const Duration(milliseconds: 300));
    controller.dispose();
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => ProfileDialog(
        icon: Icons.logout_rounded,
        danger: true,
        title: const Text('Keluar dari Nalara?'),
        content: const Text('Anda akan kembali ke halaman masuk.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );
    if (!mounted || confirm != true) return;
    try {
      await _session.signOut();
    } catch (error) {
      if (mounted) _information('Gagal keluar', firebaseMessage(error));
    }
  }

  // Pengaturan menentukan metode pencatatan yang tersedia di kasir.
  Future<void> _payments() async {
    var enabled = _session.methods['Tunai']!;
    var qrisEnabled = _session.methods['QRIS']!;
    var busy = false;
    String? error;
    await showDialog<void>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, update) => ProfileDialog(
          icon: Icons.account_balance_wallet_outlined,
          description: 'Pilih metode pembayaran yang dapat digunakan di kasir.',
          title: const Text('Metode Pembayaran'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                secondary: const Icon(
                  Icons.payments_outlined,
                  color: AppColors.background,
                ),
                title: const Text(
                  'Tunai',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                ),
                subtitle: const Text(
                  'Pembayaran langsung di kasir',
                  style: TextStyle(fontSize: 12, color: AppColors.muted),
                ),
                value: enabled,
                onChanged: busy
                    ? null
                    : (value) => update(() => enabled = value),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                secondary: const Icon(
                  Icons.qr_code_rounded,
                  color: AppColors.background,
                ),
                title: const Text(
                  'QRIS',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                ),
                subtitle: const Text(
                  'Catat pembayaran QRIS yang diterima di luar aplikasi',
                  style: TextStyle(fontSize: 12, color: AppColors.muted),
                ),
                value: qrisEnabled,
                onChanged: busy
                    ? null
                    : (value) => update(() => qrisEnabled = value),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.softBlue,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Text(
                  'QRIS dicatat secara manual. Pastikan pembayaran sudah diterima sebelum menyelesaikan transaksi.',
                ),
              ),
              if (error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    error!,
                    style: const TextStyle(color: Color(0xFFD64550)),
                  ),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: busy ? null : () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: busy
                  ? null
                  : () async {
                      update(() => busy = true);
                      try {
                        await _session.saveProfile({
                          'paymentMethods': {
                            'Tunai': enabled,
                            'QRIS': qrisEnabled,
                          },
                        });
                        if (context.mounted) Navigator.pop(context);
                      } catch (failure) {
                        if (context.mounted) {
                          update(() {
                            busy = false;
                            error = firebaseMessage(failure);
                          });
                        }
                      }
                    },
              child: Text(busy ? 'Menyimpan...' : 'Simpan'),
            ),
          ],
        ),
      ),
    );
  }

  // Dialog informasi tidak mengklaim paket berbayar atau dukungan sudah terhubung.
  void _information(String title, String message) => showDialog<void>(
    context: context,
    builder: (context) => ProfileDialog(
      icon: Icons.info_outline_rounded,
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Tutup'),
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF7F9FC),
    appBar: const ProfileHeader(title: 'Profil'),
    bottomNavigationBar: const NalaraNavigation(index: 5),
    body: SafeArea(
      top: false,
      bottom: false,
      child: SingleChildScrollView(
        child: Stack(
          children: [
            Container(
              height: 100,
              decoration: const BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(32),
                ),
              ),
            ),
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 640),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ProfileCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 56,
                                  height: 56,
                                  decoration: BoxDecoration(
                                    color: AppColors.softBlue,
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                  child: Center(
                                    child: Text(
                                      _name.isEmpty
                                          ? 'N'
                                          : _name.characters.first
                                                .toUpperCase(),
                                      style: const TextStyle(
                                        color: AppColors.background,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 24,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _name.isEmpty ? 'Profil Anda' : _name,
                                        style: const TextStyle(
                                          color: AppColors.ink,
                                          fontSize: 18,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                      if (_email.isNotEmpty) ...[
                                        const SizedBox(height: 5),
                                        Text(
                                          _email,
                                          style: const TextStyle(
                                            color: AppColors.muted,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                IconButton(
                                  tooltip: 'Edit Profil',
                                  onPressed: _edit,
                                  style: IconButton.styleFrom(
                                    backgroundColor: AppColors.softBlue,
                                    foregroundColor: AppColors.background,
                                  ),
                                  icon: const Icon(
                                    Icons.edit_outlined,
                                    size: 20,
                                  ),
                                ),
                              ],
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 16),
                              child: Divider(
                                height: 1,
                                color: Color(0xFFEDF1F7),
                              ),
                            ),
                            Row(
                              children: [
                                const Icon(
                                  Icons.storefront_outlined,
                                  size: 18,
                                  color: AppColors.background,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _store.isEmpty
                                        ? 'Informasi toko belum dilengkapi'
                                        : _store,
                                    style: const TextStyle(
                                      color: AppColors.muted,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      _packageCard(),
                      const SizedBox(height: 24),
                      _sectionTitle('Operasional kasir'),
                      ProfileCard(
                        padding: EdgeInsets.zero,
                        child: _menu(
                          'Shift Kasir',
                          'Modal awal, tutup kas, dan riwayat shift',
                          Icons.work_history_outlined,
                          () => Navigator.push<void>(
                            context,
                            MaterialPageRoute(builder: (_) => const ShiftsScreen()),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      _sectionTitle('Kelola akun & toko'),
                      ProfileCard(
                        padding: EdgeInsets.zero,
                        child: Column(
                          children: [
                            _menu(
                              'Informasi Toko',
                              'Nama, alamat, dan kontak usaha',
                              Icons.storefront_outlined,
                              () => _edit(store: true),
                            ),
                            _divider(),
                            _menu(
                              'Pengaturan Akun',
                              'Nama dan email akun Anda',
                              Icons.manage_accounts_outlined,
                              _edit,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      _sectionTitle('Preferensi'),
                      ProfileCard(
                        padding: EdgeInsets.zero,
                        child: Column(
                          children: [
                            _menu(
                              'Metode Pembayaran',
                              'Atur pembayaran di kasir',
                              Icons.account_balance_wallet_outlined,
                              _payments,
                            ),
                            _divider(),
                            _menu(
                              'Notifikasi',
                              _session.notifications
                                  ? 'Notifikasi aktif'
                                  : 'Notifikasi nonaktif',
                              Icons.notifications_outlined,
                              _notificationsDialog,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      _sectionTitle('Bantuan & sesi'),
                      ProfileCard(
                        padding: EdgeInsets.zero,
                        child: Column(
                          children: [
                            _menu(
                              'Bantuan',
                              'Sampaikan kendala penggunaan',
                              Icons.help_outline_rounded,
                              _help,
                            ),
                            _divider(),
                            _menu(
                              'Logout',
                              'Keluar dari akun di perangkat ini',
                              Icons.logout_rounded,
                              _logout,
                              danger: true,
                            ),
                          ],
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
    ),
  );

  Widget _sectionTitle(String text) => Padding(
    padding: const EdgeInsets.only(left: 4, bottom: 10),
    child: Text(
      text,
      style: const TextStyle(
        color: AppColors.muted,
        fontSize: 12,
        fontWeight: FontWeight.w700,
      ),
    ),
  );
  Widget _divider() => const Padding(
    padding: EdgeInsets.only(left: 72, right: 16),
    child: Divider(height: 1, color: Color(0xFFEDF1F7)),
  );

  Widget _menu(
    String label,
    String description,
    IconData icon,
    VoidCallback action, {
    bool danger = false,
  }) {
    final color = danger ? const Color(0xFFD64550) : AppColors.background;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(24),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: action,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: .06),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(icon, color: color, size: 21),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        color: danger ? color : AppColors.ink,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.chevron_right_rounded,
                color: Color(0xFFA3B1C6),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _packageCard() => ValueListenableBuilder<bool>(
    valueListenable: NalaraPackage.premium,
    builder: (context, premium, _) => Material(
      color: AppColors.background,
      borderRadius: BorderRadius.circular(24),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute<void>(builder: (_) => const PackageScreen()),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .12),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Icon(
                  Icons.workspace_premium_rounded,
                  color: Color(0xFFFFDB8B),
                  size: 25,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Paket Nalara',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      premium ? 'PREMIUM AKTIF' : 'BASIC \u2022 LIHAT PREMIUM',
                      style: const TextStyle(
                        color: Color(0xFFCDDAFF),
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        letterSpacing: .5,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_rounded,
                color: Colors.white,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

// Form bersama menyediakan validasi sederhana untuk informasi toko dan akun.
class _ProfileForm extends StatefulWidget {
  const _ProfileForm({required this.store, required this.values});
  final bool store;
  final List<String> values;
  @override
  State<_ProfileForm> createState() => _ProfileFormState();
}

class _ProfileFormState extends State<_ProfileForm> {
  final _key = GlobalKey<FormState>();
  bool _saving = false;
  Future<void> _save() async {
    if (_saving || !_key.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final values = _controllers.map((c) => c.text.trim()).toList();
      var emailPending = false;
      if (widget.store) {
        await StoreSession.instance.saveProfile({
          'storeName': values[0],
          'category': values[1],
          'address': values[2],
          'phone': values[3],
        });
      } else {
        final user = FirebaseAuth.instance.currentUser!;
        if (values[1] != user.email) {
          await user.verifyBeforeUpdateEmail(values[1]);
          emailPending = true;
        }
        await user.updateDisplayName(values[0]);
        await StoreSession.instance.saveProfile({'name': values[0]});
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            emailPending
                ? 'Profil disimpan. Buka tautan verifikasi pada email baru untuk mengganti email login.'
                : 'Perubahan disimpan.',
          ),
        ),
      );
      Navigator.pop(context);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(firebaseMessage(error))));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  late final List<TextEditingController> _controllers;
  @override
  void initState() {
    super.initState();
    _controllers = widget.values
        .map((value) => TextEditingController(text: value))
        .toList();
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final labels = widget.store
        ? ['Nama Usaha', 'Jenis Usaha', 'Alamat Toko', 'Nomor HP / WhatsApp']
        : ['Nama', 'Email'];
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: ProfileHeader(
        title: widget.store ? 'Informasi Toko' : 'Pengaturan Akun',
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _key,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ProfileIntro(
                        icon: widget.store
                            ? Icons.storefront_outlined
                            : Icons.manage_accounts_outlined,
                        title: widget.store
                            ? 'Identitas usaha'
                            : 'Informasi pribadi',
                        description: widget.store
                            ? 'Lengkapi informasi agar toko Anda mudah dikenali.'
                            : 'Kelola nama dan email yang terhubung ke akun Anda.',
                      ),
                      const SizedBox(height: 24),
                      ProfileCard(
                        child: ResponsiveColumns(
                          children: [
                            for (var index = 0; index < labels.length; index++)
                              TextFormField(
                                controller: _controllers[index],
                                minLines: widget.store && index == 2 ? 2 : 1,
                                maxLines: widget.store && index == 2 ? 4 : 1,
                                enabled: !_saving,
                                keyboardType: widget.store && index == 3
                                    ? TextInputType.phone
                                    : !widget.store && index == 1
                                    ? TextInputType.emailAddress
                                    : widget.store && index == 2
                                    ? TextInputType.multiline
                                    : TextInputType.text,
                                textCapitalization:
                                    (widget.store && index != 3) ||
                                        (!widget.store && index == 0)
                                    ? TextCapitalization.words
                                    : TextCapitalization.none,
                                decoration: profileInput(
                                  labels[index],
                                  icon: widget.store
                                      ? [
                                          Icons.storefront_outlined,
                                          Icons.category_outlined,
                                          Icons.location_on_outlined,
                                          Icons.phone_outlined,
                                        ][index]
                                      : [
                                          Icons.person_outline_rounded,
                                          Icons.mail_outline_rounded,
                                        ][index],
                                ),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return '${labels[index]} wajib diisi.';
                                  }
                                  if (!widget.store &&
                                      index == 1 &&
                                      !RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$')
                                          .hasMatch(value.trim())) {
                                    return 'Email tidak valid.';
                                  }
                                  if (widget.store &&
                                      index == 3 &&
                                      !RegExp(r'^\+?[0-9]{8,15}$')
                                          .hasMatch(value.trim())) {
                                    return 'Nomor telepon tidak valid.';
                                  }
                                  return null;
                                },
                              ),
                          ],
                        ),
                      ),
                      if (!widget.store) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.softBlue,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Text(
                            'Perubahan email memerlukan verifikasi melalui email baru Anda.',
                            style: TextStyle(
                              color: AppColors.muted,
                              fontSize: 12,
                              height: 1.6,
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),
                      FilledButton.icon(
                        onPressed: _saving ? null : _save,
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.background,
                          foregroundColor: Colors.white,
                          minimumSize: const Size.fromHeight(52),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        icon: _saving
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.check_rounded, size: 20),
                        label: Text(
                          _saving ? 'Menyimpan...' : 'Simpan Perubahan',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
