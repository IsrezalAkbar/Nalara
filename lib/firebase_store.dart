import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

DocumentReference<Map<String, dynamic>> get accountRef {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) throw StateError('Silakan masuk kembali.');
  return FirebaseFirestore.instance.collection('users').doc(user.uid);
}

String firebaseMessage(Object error) {
  if (error is TimeoutException) {
    return 'Koneksi terlalu lama. Periksa internet lalu coba lagi.';
  }
  if (error is FirebaseException) {
    return switch (error.code) {
      'invalid-credential' ||
      'wrong-password' ||
      'user-not-found' => 'Email atau password salah.',
      'email-already-in-use' => 'Email sudah terdaftar.',
      'invalid-email' => 'Alamat email tidak valid.',
      'weak-password' => 'Password terlalu lemah. Gunakan minimal 8 karakter.',
      'requires-recent-login' => 'Masuk ulang sebelum mengubah email.',
      'permission-denied' => 'Akses ditolak. Periksa aturan akses Firebase.',
      'unavailable' || 'network-request-failed' =>
        'Koneksi gagal. Periksa internet lalu coba lagi.',
      'operation-not-allowed' => 'Metode masuk belum diaktifkan di Firebase.',
      'too-many-requests' => 'Terlalu banyak percobaan. Coba lagi nanti.',
      _ => 'Operasi gagal (${error.code}). Silakan coba lagi.',
    };
  }
  return error is StateError
      ? error.message.toString()
      : 'Operasi gagal. Silakan coba lagi.';
}
