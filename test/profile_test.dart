import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nalara/session.dart';
import 'package:nalara/screens/profile_screen.dart';

void main() {
  testWidgets(
    'Profile uses the active account profile without example identity',
    (tester) async {
      StoreSession.instance.profile = {
        'name': 'Pemilik Uji',
        'storeName': 'Toko Uji',
      };
      addTearDown(() => StoreSession.instance.profile = {});
      await tester.pumpWidget(const MaterialApp(home: ProfileScreen()));
      expect(find.text('Pemilik Uji'), findsOneWidget);
      expect(find.text('Toko Uji'), findsOneWidget);
      expect(find.text('Tya'), findsNothing);
      await tester.tap(find.byTooltip('Edit Profil'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField).first, '');
      await tester.ensureVisible(find.text('Simpan Perubahan'));
      await tester.tap(find.text('Simpan Perubahan'));
      await tester.pumpAndSettle();
      expect(find.text('Nama wajib diisi.'), findsOneWidget);
    },
  );

  testWidgets(
    'Profile settings can open and cancel on small screens with large text',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetViewInsets);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      for (final size in [const Size(360, 800), const Size(640, 320)]) {
        tester.view.physicalSize = size;
        for (final menu in [
          'Informasi Toko',
          'Pengaturan Akun',
          'Metode Pembayaran',
          'Notifikasi',
          'Bantuan',
          'Logout',
        ]) {
          await tester.pumpWidget(
            MaterialApp(
              key: ValueKey('$size-$menu'),
              home: const ProfileScreen(),
            ),
          );
          await tester.ensureVisible(find.text(menu));
          await tester.tap(find.text(menu));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull, reason: '$menu at $size');
          if (menu == 'Bantuan') {
            tester.view.viewInsets = const FakeViewPadding(bottom: 160);
            await tester.pumpAndSettle();
            await tester.ensureVisible(find.text('Kirim'));
            await tester.tap(find.text('Kirim'));
            await tester.pumpAndSettle();
            expect(
              find.text('Tuliskan kendala Anda terlebih dahulu.'),
              findsOneWidget,
            );
            expect(tester.takeException(), isNull);
            tester.view.resetViewInsets();
            await tester.pumpAndSettle();
          }
          if (menu == 'Informasi Toko' || menu == 'Pengaturan Akun') {
            await tester.tap(find.byTooltip('Kembali'));
          } else {
            final close = find.text(menu == 'Notifikasi' ? 'Selesai' : 'Batal');
            await tester.ensureVisible(close);
            await tester.tap(close);
          }
          await tester.pumpAndSettle();
          await tester.pump(const Duration(milliseconds: 300));
          expect(find.byType(ProfileScreen), findsOneWidget);
          expect(find.byType(AlertDialog), findsNothing);
          expect(tester.takeException(), isNull, reason: 'Closing $menu');
        }
      }
    },
  );
}
