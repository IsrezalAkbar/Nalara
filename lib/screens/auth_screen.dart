// Mengimpor widget, pengaturan bilah sistem, dan komponen bersama.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../colors.dart';
import '../widgets/responsive_columns.dart';
import '../widgets/splash_logo.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../firebase_store.dart';
import '../google_auth.dart';
import 'forgot_password_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  // Menyimpan status form, mode daftar, dan visibilitas password.
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;
  bool _googleBusy = false;
  bool _register = false;
  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  bool _hidePassword = true;

  // Menampilkan hasil atau kegagalan autentikasi kepada pengguna.
  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _submit() async {
    if (_busy || !_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _busy = true);
    final name = _name.text.trim();
    final email = _email.text.trim();
    final password = _password.text;
    try {
      if (_register) {
        final credential = await FirebaseAuth.instance
            .createUserWithEmailAndPassword(email: email, password: password);
        await credential.user!.updateDisplayName(name);
        // SessionGate observes this update and syncs name/email to Firestore.
      } else {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
      }
    } catch (error) {
      if (mounted) _showMessage(firebaseMessage(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _resetPassword() async {
    if (_busy) return;
    FocusScope.of(context).unfocus();
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => ForgotPasswordScreen(initialEmail: _email.text.trim()),
      ),
    );
  }

  Future<void> _google() async {
    if (_busy) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _googleBusy = true;
    });
    try {
      await GoogleAuth.instance.signIn();
    } on GoogleSignInException catch (error) {
      if (mounted) _showMessage(googleAuthMessage(error));
    } catch (error) {
      if (mounted) _showMessage(firebaseMessage(error));
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
          _googleBusy = false;
        });
      }
    }
  }

  // Menyamakan bentuk, warna, dan jarak semua kolom input.
  InputDecoration _decoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFF9AAAC2), fontSize: 15),
      prefixIcon: Icon(icon, size: 19, color: const Color(0xFF94A3B8)),
      filled: true,
      fillColor: AppColors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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

  // Label diletakkan di atas input agar sesuai dengan desain Figma.
  Widget _label(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          color: Color(0xFF475569),
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Form sedikit lebih lebar dan jarak atas lebih ringkas saat layar diputar.
    final landscape =
        MediaQuery.orientationOf(context) == Orientation.landscape;
    // Menyesuaikan warna bilah status dan navigasi Android dengan halaman.
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: AppColors.surface,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: AppColors.surface,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: AppColors.surface,
        // SafeArea melindungi konten dari notch; scroll mengakomodasi keyboard.
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                // Membatasi lebar form pada layar besar dan memenuhi layar pendek.
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: landscape ? 1000 : 440,
                    ),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      // Tanpa IntrinsicHeight agar grid input bisa mengukur ruang tersedia.
                      child: SizedBox(
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(
                            24,
                            landscape ? 20 : 46,
                            24,
                            32,
                          ),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Identitas Nalara di bagian atas form.
                                const Row(
                                  children: [
                                    SplashLogo(size: 40),
                                    SizedBox(width: 12),
                                    Flexible(
                                      child: Text(
                                        'Nalara',
                                        style: TextStyle(
                                          color: AppColors.background,
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 32),
                                // Judul dan pengantar berubah sesuai mode login/daftar.
                                Text(
                                  _register
                                      ? 'Daftar ke Nalara'
                                      : 'Masuk ke Nalara',
                                  style: const TextStyle(
                                    color: AppColors.ink,
                                    fontSize: 30,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _register
                                      ? 'Buat akun untuk memulai pencatatan keuangan Anda.'
                                      : 'Silakan masuk untuk melanjutkan\npencatatan keuangan Anda.',
                                  style: const TextStyle(
                                    color: AppColors.muted,
                                    fontSize: 16,
                                    height: 1.5,
                                  ),
                                ),
                                const SizedBox(height: 24),
                                // Input nama hanya muncul ketika pengguna memilih daftar.
                                if (_register) ...[
                                  _label('Nama'),
                                  TextFormField(
                                    key: const ValueKey('name'),
                                    controller: _name,
                                    textCapitalization:
                                        TextCapitalization.words,
                                    textInputAction: TextInputAction.next,
                                    decoration: _decoration(
                                      'Nama lengkap Anda',
                                      Icons.person,
                                    ),
                                    validator: (value) =>
                                        value == null || value.trim().isEmpty
                                        ? 'Masukkan nama Anda.'
                                        : null,
                                  ),
                                  const SizedBox(height: 20),
                                ],
                                // Input identitas; validator siap digunakan saat API ditambahkan.
                                // Kedua input berdampingan hanya jika tersedia ruang yang cukup.
                                ResponsiveColumns(
                                  gap: 20,
                                  children: [
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        _label('Email'),
                                        TextFormField(
                                          key: const ValueKey('identity'),
                                          controller: _email,
                                          keyboardType:
                                              TextInputType.emailAddress,
                                          textInputAction: TextInputAction.next,
                                          autocorrect: false,
                                          decoration: _decoration(
                                            'Contoh: user@email.com',
                                            Icons.person,
                                          ),
                                          validator: (value) {
                                            final identity =
                                                value?.trim() ?? '';
                                            if (identity.isEmpty) {
                                              return 'Masukkan email.';
                                            }
                                            final email = RegExp(
                                              r'^[^\s@]+@[^\s@]+\.[^\s@]+$',
                                            );
                                            return email.hasMatch(identity)
                                                ? null
                                                : 'Email tidak valid.';
                                          },
                                        ),
                                      ],
                                    ),
                                    // Input password dilengkapi tombol tampil/sembunyikan.
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        _label('Password'),
                                        TextFormField(
                                          key: const ValueKey('password'),
                                          controller: _password,
                                          obscureText: _hidePassword,
                                          autocorrect: false,
                                          enableSuggestions: false,
                                          onFieldSubmitted: (_) => _submit(),
                                          decoration:
                                              _decoration(
                                                'Masukkan password Anda',
                                                Icons.lock,
                                              ).copyWith(
                                                suffixIcon: IconButton(
                                                  tooltip: _hidePassword
                                                      ? 'Tampilkan password'
                                                      : 'Sembunyikan password',
                                                  icon: Icon(
                                                    _hidePassword
                                                        ? Icons
                                                              .visibility_off_outlined
                                                        : Icons
                                                              .visibility_outlined,
                                                    size: 19,
                                                    color: const Color(
                                                      0xFF94A3B8,
                                                    ),
                                                  ),
                                                  onPressed: () => setState(
                                                    () => _hidePassword =
                                                        !_hidePassword,
                                                  ),
                                                ),
                                              ),
                                          validator: (value) {
                                            if (value == null ||
                                                value.isEmpty) {
                                              return 'Masukkan password Anda.';
                                            }
                                            if (_register && value.length < 8) {
                                              return 'Gunakan minimal 8 karakter.';
                                            }
                                            return null;
                                          },
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                if (!_register)
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: TextButton(
                                      onPressed: _busy ? null : _resetPassword,
                                      child: const Text('Lupa password?'),
                                    ),
                                  )
                                else
                                  const SizedBox(height: 24),
                                const SizedBox(height: 12),
                                // Tombol utama menjalankan alur sesuai mode form.
                                FilledButton(
                                  onPressed: _busy ? null : _submit,
                                  style: FilledButton.styleFrom(
                                    backgroundColor: AppColors.background,
                                    foregroundColor: AppColors.white,
                                    minimumSize: const Size.fromHeight(56),
                                    elevation: 4,
                                    shadowColor: AppColors.background
                                        .withValues(alpha: 0.3),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: Text(
                                    _busy
                                        ? 'Memproses...'
                                        : _register
                                        ? 'Daftar'
                                        : 'Masuk',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 28),
                                // Pembatas visual antara login biasa dan Google.
                                const Row(
                                  children: [
                                    Expanded(
                                      child: Divider(color: AppColors.border),
                                    ),
                                    Padding(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 16,
                                      ),
                                      child: Text(
                                        'ATAU',
                                        style: TextStyle(
                                          color: Color(0xFF94A3B8),
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: Divider(color: AppColors.border),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 24),
                                OutlinedButton(
                                  onPressed: _busy ? null : _google,
                                  style: OutlinedButton.styleFrom(
                                    backgroundColor: AppColors.white,
                                    foregroundColor: const Color(0xFF475569),
                                    minimumSize: const Size.fromHeight(56),
                                    side: const BorderSide(
                                      color: AppColors.border,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      if (_googleBusy)
                                        const SizedBox(
                                          width: 23,
                                          height: 23,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        )
                                      else
                                        const Text(
                                          'G',
                                          style: TextStyle(
                                            color: Color(0xFFEA4335),
                                            fontSize: 23,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      const SizedBox(width: 12),
                                      Flexible(
                                        child: Text(
                                          _googleBusy
                                              ? 'Menghubungkan Google...'
                                              : _register
                                              ? 'Daftar dengan Google'
                                              : 'Masuk dengan Google',
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 48),
                                const SizedBox(height: 24),
                                // Tautan bawah mengganti mode dan membersihkan isi form.
                                Wrap(
                                  alignment: WrapAlignment.center,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: [
                                    Text(
                                      _register
                                          ? 'Sudah punya akun?'
                                          : 'Belum punya akun?',
                                      style: const TextStyle(
                                        color: AppColors.muted,
                                        fontSize: 16,
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: _busy
                                          ? null
                                          : () {
                                              _formKey.currentState?.reset();
                                              setState(() {
                                                _register = !_register;
                                                _hidePassword = true;
                                              });
                                            },
                                      child: Text(
                                        _register ? 'Masuk' : 'Daftar',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
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
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
