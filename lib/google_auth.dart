import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Keeps the Google SDK initialized once across login attempts and logout.
class GoogleAuth {
  GoogleAuth({GoogleSignIn? google, this.auth})
    : _google = google ?? GoogleSignIn.instance;

  static final instance = GoogleAuth();
  final GoogleSignIn _google;
  final FirebaseAuth? auth;
  Future<void>? _initialization;

  Future<UserCredential> signIn() async {
    await (_initialization ??= _google.initialize());
    if (!_google.supportsAuthenticate()) {
      throw StateError('Login Google belum didukung pada platform ini.');
    }
    final account = await _google.authenticate();
    final idToken = account.authentication.idToken;
    if (idToken == null || idToken.isEmpty) {
      throw StateError(
        'Google tidak mengirim token masuk. Periksa konfigurasi OAuth aplikasi.',
      );
    }
    return (auth ?? FirebaseAuth.instance).signInWithCredential(
      GoogleAuthProvider.credential(idToken: idToken),
    );
  }

  Future<void> signOut() async {
    if (_initialization == null) return;
    await _initialization;
    await _google.signOut();
  }
}

String googleAuthMessage(GoogleSignInException error) => switch (error.code) {
  GoogleSignInExceptionCode.canceled =>
    'Masuk dengan Google dibatalkan atau tidak selesai. Jika Anda tidak '
        'membatalkannya, minta pembuat APK memeriksa SHA-1/SHA-256 '
        'kunci build di Firebase, terutama jika aplikasi dibangun dari komputer lain.',
  GoogleSignInExceptionCode.clientConfigurationError =>
    'Konfigurasi Google belum sesuai. Periksa provider Google di Firebase, '
        'SHA-1/SHA-256 komputer pembuat APK, dan unduh ulang google-services.json.',
  GoogleSignInExceptionCode.providerConfigurationError =>
    'Layanan login Google tidak tersedia atau belum sesuai pada perangkat ini. '
        'Pastikan Google Play services terpasang, aktif, dan diperbarui.',
  GoogleSignInExceptionCode.uiUnavailable =>
    'Pemilih akun Google tidak dapat dibuka. Coba lagi saat aplikasi aktif.',
  GoogleSignInExceptionCode.interrupted =>
    'Proses masuk Google terputus. Silakan coba lagi.',
  _ =>
    'Masuk Google gagal (${error.code.name}). Periksa internet dan coba lagi.',
};
