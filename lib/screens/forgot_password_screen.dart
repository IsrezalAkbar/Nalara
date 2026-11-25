import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../colors.dart';
import '../firebase_store.dart';
import '../widgets/splash_logo.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key, this.initialEmail = '', this.auth});

  final String initialEmail;
  final FirebaseAuth? auth;

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _email = TextEditingController(text: widget.initialEmail);
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy || !_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _error = null;
    });
    final email = _email.text.trim();
    try {
      await _sendResetEmail(widget.auth ?? FirebaseAuth.instance, email);
      if (!mounted) return;
      Navigator.of(context).pushReplacement<void, void>(
        MaterialPageRoute(
          builder: (_) =>
              ResetPasswordWaitingScreen(email: email, auth: widget.auth),
        ),
      );
    } catch (error) {
      if (mounted) setState(() => _error = firebaseMessage(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => _PasswordResetLayout(
    title: 'Lupa password',
    icon: Icons.lock_reset_rounded,
    heading: 'Lupa password?',
    children: [
      const Text(
        'Masukkan email yang terdaftar di Nalara. Kami akan mengirimkan tautan untuk membuat password baru.',
        style: _descriptionStyle,
      ),
      const SizedBox(height: 28),
      Form(
        key: _formKey,
        child: TextFormField(
          key: const ValueKey('reset-email'),
          controller: _email,
          enabled: !_busy,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.done,
          autofillHints: const [AutofillHints.email],
          autocorrect: false,
          onFieldSubmitted: (_) => _submit(),
          decoration: InputDecoration(
            labelText: 'Email',
            hintText: 'Contoh: user@email.com',
            prefixIcon: const Icon(Icons.mail_outline_rounded),
            filled: true,
            fillColor: AppColors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: AppColors.border),
            ),
          ),
          validator: (value) {
            final email = value?.trim() ?? '';
            if (email.isEmpty) return 'Masukkan email Anda.';
            return RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email)
                ? null
                : 'Email tidak valid.';
          },
        ),
      ),
      if (_error != null) _ResetError(message: _error!),
      const SizedBox(height: 24),
      FilledButton(
        onPressed: _busy ? null : _submit,
        child: Text(_busy ? 'Mengirim...' : 'Kirim tautan reset'),
      ),
      const SizedBox(height: 12),
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: const Text('Kembali ke halaman masuk'),
      ),
    ],
  );
}

// Respons tetap sama untuk email yang tidak terdaftar.
Future<void> _sendResetEmail(FirebaseAuth auth, String email) async {
  try {
    await auth.sendPasswordResetEmail(email: email);
  } on FirebaseAuthException catch (error) {
    if (error.code != 'user-not-found') rethrow;
  }
}

class ResetPasswordWaitingScreen extends StatefulWidget {
  const ResetPasswordWaitingScreen({super.key, required this.email, this.auth});

  final String email;
  final FirebaseAuth? auth;

  @override
  State<ResetPasswordWaitingScreen> createState() =>
      _ResetPasswordWaitingScreenState();
}

class _ResetPasswordWaitingScreenState
    extends State<ResetPasswordWaitingScreen> {
  Timer? _timer;
  int _secondsRemaining = 60;
  bool _busy = false;
  bool _resent = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _startCooldown();
  }

  void _startCooldown() {
    _timer?.cancel();
    _secondsRemaining = 60;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        _secondsRemaining = (60 - timer.tick).clamp(0, 60);
      });
      if (_secondsRemaining == 0) timer.cancel();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _resend() async {
    if (_busy || _secondsRemaining > 0) return;
    setState(() {
      _busy = true;
      _resent = false;
      _error = null;
    });
    try {
      await _sendResetEmail(widget.auth ?? FirebaseAuth.instance, widget.email);
      if (!mounted) return;
      setState(() {
        _startCooldown();
        _resent = true;
      });
    } catch (error) {
      if (mounted) setState(() => _error = firebaseMessage(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => _PasswordResetLayout(
    title: 'Periksa email',
    icon: Icons.mark_email_unread_outlined,
    heading: 'Periksa email Anda',
    children: [
      const Text(
        'Jika email terdaftar, tautan reset password akan dikirim ke:',
        style: _descriptionStyle,
      ),
      const SizedBox(height: 12),
      Text(
        widget.email,
        style: const TextStyle(
          color: AppColors.background,
          fontSize: 17,
          fontWeight: FontWeight.w600,
        ),
      ),
      const SizedBox(height: 24),
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.softBlue,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.schedule_rounded, color: AppColors.logoBlue),
            SizedBox(height: 12),
            Text(
              'Menunggu Anda membuka tautan',
              style: TextStyle(
                color: AppColors.ink,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Buka email dan klik tautan untuk membuat password baru. Setelah selesai, kembali ke Nalara dan masuk dengan password baru Anda.',
              style: _descriptionStyle,
            ),
          ],
        ),
      ),
      const SizedBox(height: 20),
      const Text(
        'Belum menerima email? Periksa folder spam atau tunggu beberapa saat sebelum mengirim ulang.',
        style: _descriptionStyle,
      ),
      if (_resent)
        Padding(
          padding: const EdgeInsets.only(top: 16),
          child: Semantics(
            liveRegion: true,
            child: const Text(
              'Jika email terdaftar, tautan reset baru akan dikirim.',
              style: TextStyle(color: AppColors.background),
            ),
          ),
        ),
      if (_error != null) _ResetError(message: _error!),
      const SizedBox(height: 24),
      FilledButton(
        onPressed: () => Navigator.of(context).pop(),
        child: const Text('Sudah ubah password? Masuk'),
      ),
      const SizedBox(height: 12),
      OutlinedButton(
        onPressed: _busy || _secondsRemaining > 0 ? null : _resend,
        child: Text(
          _busy
              ? 'Mengirim...'
              : _secondsRemaining > 0
              ? 'Kirim ulang dalam $_secondsRemaining detik'
              : 'Kirim ulang email',
        ),
      ),
      const SizedBox(height: 8),
      TextButton(
        onPressed: _busy
            ? null
            : () => Navigator.of(context).pushReplacement<void, void>(
                MaterialPageRoute(
                  builder: (_) => ForgotPasswordScreen(
                    initialEmail: widget.email,
                    auth: widget.auth,
                  ),
                ),
              ),
        child: const Text('Gunakan email lain'),
      ),
    ],
  );
}

const _descriptionStyle = TextStyle(
  color: AppColors.muted,
  fontSize: 16,
  height: 1.5,
);

class _ResetError extends StatelessWidget {
  const _ResetError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 16),
    child: Semantics(
      liveRegion: true,
      child: Text(
        message,
        style: TextStyle(color: Theme.of(context).colorScheme.error),
      ),
    ),
  );
}

class _PasswordResetLayout extends StatelessWidget {
  const _PasswordResetLayout({
    required this.title,
    required this.icon,
    required this.heading,
    required this.children,
  });

  final String title;
  final IconData icon;
  final String heading;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.surface,
    appBar: AppBar(
      title: Text(title),
      backgroundColor: AppColors.surface,
      foregroundColor: AppColors.ink,
      surfaceTintColor: Colors.transparent,
    ),
    body: SafeArea(
      child: SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Row(
                  children: [
                    SplashLogo(size: 40),
                    SizedBox(width: 12),
                    Text(
                      'Nalara',
                      style: TextStyle(
                        color: AppColors.background,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                Align(
                  alignment: Alignment.centerLeft,
                  child: CircleAvatar(
                    radius: 36,
                    backgroundColor: AppColors.softBlue,
                    child: Icon(icon, size: 36, color: AppColors.background),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  heading,
                  style: const TextStyle(
                    color: AppColors.ink,
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                ...children,
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
