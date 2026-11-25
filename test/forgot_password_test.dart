import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nalara/screens/auth_screen.dart';
import 'package:nalara/screens/forgot_password_screen.dart';

class ResetAuth extends Fake implements FirebaseAuth {
  final emails = <String>[];
  FirebaseAuthException? failure;
  Completer<void>? pending;

  @override
  Future<void> sendPasswordResetEmail({
    required String email,
    ActionCodeSettings? actionCodeSettings,
  }) async {
    emails.add(email);
    if (pending != null) await pending!.future;
    if (failure != null) throw failure!;
  }
}

Future<void> tapText(WidgetTester tester, String text) async {
  await tester.ensureVisible(find.text(text));
  await tester.tap(find.text(text));
  await tester.pumpAndSettle();
}

Future<void> openReset(WidgetTester tester, ResetAuth auth) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () => Navigator.of(context).push<void>(
              MaterialPageRoute(
                builder: (_) => ForgotPasswordScreen(auth: auth),
              ),
            ),
            child: const Text('Login'),
          ),
        ),
      ),
    ),
  );
  await tapText(tester, 'Login');
}

void main() {
  testWidgets(
    'Login opens a separate reset form without requiring a password',
    (tester) async {
      await tester.pumpWidget(const MaterialApp(home: AuthScreen()));
      await tapText(tester, 'Lupa password?');
      expect(find.byType(ForgotPasswordScreen), findsOneWidget);
      expect(find.byType(TextFormField), findsOneWidget);
      await tapText(tester, 'Kembali ke halaman masuk');
      expect(find.byType(AuthScreen), findsOneWidget);

      await tester.enterText(find.byKey(const ValueKey('identity')), 'a@b.com');
      await tapText(tester, 'Lupa password?');
      expect(find.text('a@b.com'), findsOneWidget);
    },
  );

  testWidgets('Invalid email never sends a reset request', (tester) async {
    final auth = ResetAuth();
    await openReset(tester, auth);
    await tapText(tester, 'Kirim tautan reset');
    expect(find.text('Masukkan email Anda.'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField), 'invalid');
    await tapText(tester, 'Kirim tautan reset');
    expect(find.text('Email tidak valid.'), findsOneWidget);
    expect(auth.emails, isEmpty);
  });

  testWidgets(
    'Send waits for Firebase, prevents duplicates, and returns to login',
    (tester) async {
      final auth = ResetAuth()..pending = Completer<void>();
      await openReset(tester, auth);
      await tester.enterText(
        find.byType(TextFormField),
        '  user@example.com  ',
      );
      await tapText(tester, 'Kirim tautan reset');
      expect(find.byType(ResetPasswordWaitingScreen), findsNothing);
      expect(
        tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNull,
      );
      await tapText(tester, 'Mengirim...');
      expect(auth.emails, ['user@example.com']);
      auth.pending!.complete();
      await tester.pumpAndSettle();
      expect(find.text('Periksa email Anda'), findsOneWidget);
      expect(find.text('user@example.com'), findsOneWidget);
      await tapText(tester, 'Sudah ubah password? Masuk');
      expect(find.text('Login'), findsOneWidget);
      expect(find.byType(ForgotPasswordScreen), findsNothing);
    },
  );

  testWidgets('Send failure stays on form and allows retry', (tester) async {
    final auth = ResetAuth()
      ..failure = FirebaseAuthException(code: 'network-request-failed');
    await openReset(tester, auth);
    await tester.enterText(find.byType(TextFormField), 'user@example.com');
    await tapText(tester, 'Kirim tautan reset');
    expect(
      find.text('Koneksi gagal. Periksa internet lalu coba lagi.'),
      findsOneWidget,
    );
    expect(find.byType(ResetPasswordWaitingScreen), findsNothing);
    auth.failure = null;
    await tapText(tester, 'Kirim tautan reset');
    expect(find.byType(ResetPasswordWaitingScreen), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
    'Resend respects cooldown, shows errors, and supports changing email',
    (tester) async {
      final auth = ResetAuth();
      await openReset(tester, auth);
      await tester.enterText(find.byType(TextFormField), 'first@example.com');
      await tapText(tester, 'Kirim tautan reset');
      expect(
        tester.widget<OutlinedButton>(find.byType(OutlinedButton)).onPressed,
        isNull,
      );
      await tester.pump(const Duration(seconds: 60));
      auth.failure = FirebaseAuthException(code: 'too-many-requests');
      await tapText(tester, 'Kirim ulang email');
      expect(
        find.text('Terlalu banyak percobaan. Coba lagi nanti.'),
        findsOneWidget,
      );
      auth.failure = null;
      await tapText(tester, 'Kirim ulang email');
      expect(auth.emails, List.filled(3, 'first@example.com'));
      expect(
        tester.widget<OutlinedButton>(find.byType(OutlinedButton)).onPressed,
        isNull,
      );
      await tapText(tester, 'Gunakan email lain');
      expect(find.text('first@example.com'), findsOneWidget);
      await tester.enterText(find.byType(TextFormField), 'second@example.com');
      await tapText(tester, 'Kirim tautan reset');
      expect(find.text('second@example.com'), findsOneWidget);
      expect(auth.emails.last, 'second@example.com');
      await tapText(tester, 'Sudah ubah password? Masuk');
      expect(find.text('Login'), findsOneWidget);
    },
  );

  testWidgets('Unknown email gets the same waiting page', (tester) async {
    final auth = ResetAuth()
      ..failure = FirebaseAuthException(code: 'user-not-found');
    await openReset(tester, auth);
    await tester.enterText(find.byType(TextFormField), 'unknown@example.com');
    await tapText(tester, 'Kirim tautan reset');
    expect(find.byType(ResetPasswordWaitingScreen), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('Leaving during a request safely ignores its completion', (
    tester,
  ) async {
    final auth = ResetAuth()..pending = Completer<void>();
    await openReset(tester, auth);
    await tester.enterText(find.byType(TextFormField), 'user@example.com');
    await tapText(tester, 'Kirim tautan reset');
    await tapText(tester, 'Kembali ke halaman masuk');
    auth.pending!.complete();
    await tester.pumpAndSettle();
    expect(find.text('Login'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Reset pages remain usable on small landscape with large text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(640, 320);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final auth = ResetAuth();
    await openReset(tester, auth);
    await tester.enterText(find.byType(TextFormField), 'user@example.com');
    await tapText(tester, 'Kirim tautan reset');
    expect(find.byType(ResetPasswordWaitingScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tapText(tester, 'Sudah ubah password? Masuk');
    expect(find.text('Login'), findsOneWidget);
  });
}
