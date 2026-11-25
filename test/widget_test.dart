import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nalara/screens/auth_screen.dart';
import 'package:nalara/screens/store_setup_screen.dart';

void main() {
  testWidgets('Empty login stays on login and validates credentials', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: AuthScreen()));
    await tester.ensureVisible(find.text('Masuk'));
    await tester.tap(find.text('Masuk'));
    await tester.pumpAndSettle();
    expect(find.text('Masukkan email.'), findsOneWidget);
    expect(find.text('Masukkan password Anda.'), findsOneWidget);
    expect(find.byType(AuthScreen), findsOneWidget);
  });
  testWidgets('Phone number is not accepted as email login', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: AuthScreen()));
    await tester.enterText(
      find.byKey(const ValueKey('identity')),
      '08123456789',
    );
    await tester.enterText(find.byKey(const ValueKey('password')), 'secret123');
    await tester.ensureVisible(find.text('Masuk'));
    await tester.tap(find.text('Masuk'));
    await tester.pumpAndSettle();
    expect(find.text('Email tidak valid.'), findsOneWidget);
  });
  testWidgets('Store setup has no prefilled example and rejects empty input', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: StoreSetupScreen()));
    expect(find.text('Kedai Tya'), findsNothing);
    await tester.ensureVisible(find.text('Mulai Kelola Bisnis'));
    await tester.tap(find.text('Mulai Kelola Bisnis'));
    await tester.pump();
    expect(
      find.text('Lengkapi nama, alamat, dan nomor telepon yang valid.'),
      findsOneWidget,
    );
    expect(find.byType(StoreSetupScreen), findsOneWidget);
  });
}
