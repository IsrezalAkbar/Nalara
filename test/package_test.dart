import 'dart:async';

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nalara/screens/package_screen.dart';
import 'package:nalara/screens/profile_screen.dart';
import 'package:nalara/screens/reports_screen.dart';
import 'package:nalara/subscriptions.dart';

void main() {
  setUp(() => NalaraPackage.premium.setExpiry(null));
  tearDown(() => NalaraPackage.premium.setExpiry(null));

  testWidgets('Basic retains current features and displays the monthly price', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: PackageScreen()));
    expect(find.text('Paket Anda: Basic'), findsOneWidget);
    expect(find.text('Rp30.000'), findsOneWidget);
    expect(find.text('Basic'), findsOneWidget);
    expect(find.text('Kasir digital dan struk transaksi'), findsOneWidget);
    expect(find.text('Ekspor laporan PDF dan CSV'), findsOneWidget);
    expect(find.text('Aktifkan Premium Demo'), findsOneWidget);
    expect(NalaraPackage.premium.value, isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Profile opens the package page and returns without removing Profile',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Navigator(
            onGenerateRoute: (_) =>
                MaterialPageRoute<void>(builder: (_) => const ProfileScreen()),
          ),
        ),
      );
      await tester.ensureVisible(find.text('Paket Nalara'));
      await tester.tap(find.text('Paket Nalara'));
      await tester.pumpAndSettle();
      expect(find.byType(PackageScreen), findsOneWidget);
      expect(find.text('Aktifkan Premium Demo'), findsOneWidget);
      expect(NalaraPackage.premium.value, isFalse);
      await tester.tap(find.byTooltip('Kembali'));
      await tester.pumpAndSettle();
      expect(find.byType(ProfileScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('An active subscription opens premium analytics', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: PackageScreen()));
    NalaraPackage.premium.value = true;
    await tester.pumpAndSettle();
    expect(find.text('Paket Anda: Premium'), findsOneWidget);
    expect(find.text('Aktifkan Premium Demo'), findsNothing);
    await tester.ensureVisible(find.text('Buka Analitik Premium'));
    await tester.tap(find.text('Buka Analitik Premium'));
    await tester.pumpAndSettle();
    expect(find.byType(ReportsScreen), findsOneWidget);
    expect(find.text('TOTAL MODAL'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Profile package status follows subscription changes', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: ProfileScreen()));
    expect(find.text('BASIC • LIHAT PREMIUM'), findsOneWidget);
    NalaraPackage.premium.value = true;
    await tester.pump();
    expect(find.text('PREMIUM AKTIF'), findsOneWidget);
    NalaraPackage.premium.value = false;
    await tester.pump();
    expect(find.text('BASIC • LIHAT PREMIUM'), findsOneWidget);
  });

  testWidgets(
    'Package and activation support small screens and large text',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      for (final size in [const Size(360, 800), const Size(640, 320)]) {
        tester.view.physicalSize = size;
        NalaraPackage.premium.setExpiry(null);
        await tester.pumpWidget(MaterialApp(home: PackageScreen(
          onActivateDemo: () async {
            NalaraPackage.premium.setExpiry(
              DateTime.now().add(const Duration(days: 30)),
            );
          },
        )));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await tester.ensureVisible(find.text('Aktifkan Premium Demo'));
        await tester.tap(find.text('Aktifkan Premium Demo'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.text('Buka Analitik Premium'), findsOneWidget);
        expect(tester.takeException(), isNull);
      }
      NalaraPackage.premium.setExpiry(null);
      await tester.pump();
    },
  );

  testWidgets('Activation saves a period and updates access without a payment dialog',
      (tester) async {
    final ref = FakeFirebaseFirestore().collection('users').doc('owner')
        .collection('subscription').doc('current');
    await tester.pumpWidget(MaterialApp(home: PackageScreen(
      onActivateDemo: () async {
        NalaraPackage.premium.setExpiry(await activateDemoSubscription(ref));
      },
    )));
    await tester.ensureVisible(find.text('Aktifkan Premium Demo'));
    await tester.tap(find.text('Aktifkan Premium Demo'));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
    expect(find.text('Paket Anda: Premium'), findsOneWidget);
    expect(find.textContaining('Aktif sampai'), findsNWidgets(2));
    expect(NalaraPackage.premium.value, isTrue);
    final saved = (await ref.get()).data()!;
    expect(subscriptionExpiry(saved), NalaraPackage.premium.expiresAt);
    NalaraPackage.premium.setExpiry(null);
    await tester.pump();
  });

  testWidgets('Activation prevents repeated taps and lets failures retry', (
    tester,
  ) async {
    final pending = Completer<void>();
    var attempts = 0;
    await tester.pumpWidget(MaterialApp(home: PackageScreen(
      onActivateDemo: () {
        attempts++;
        return pending.future;
      },
    )));
    await tester.ensureVisible(find.text('Aktifkan Premium Demo'));
    await tester.tap(find.text('Aktifkan Premium Demo'));
    await tester.pump();
    expect(find.text('Mengaktifkan...'), findsOneWidget);
    await tester.tap(find.text('Mengaktifkan...'));
    expect(attempts, 1);
    pending.completeError(StateError('Koneksi terputus. Coba lagi.'));
    await tester.pumpAndSettle();
    expect(find.text('Koneksi terputus. Coba lagi.'), findsOneWidget);
    expect(find.text('Aktifkan Premium Demo'), findsOneWidget);
    expect(NalaraPackage.premium.value, isFalse);
  });
}
