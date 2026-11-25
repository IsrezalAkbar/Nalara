import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nalara/screens/auth_screen.dart';
import 'package:nalara/screens/home_screen.dart';
import 'package:nalara/screens/profile_screen.dart';
import 'package:nalara/screens/reports_screen.dart';
import 'package:nalara/screens/store_setup_screen.dart';
import 'package:nalara/screens/cashier_screen.dart';
import 'package:nalara/screens/products_screen.dart';
import 'package:nalara/widgets/responsive_columns.dart';

void main() {
  testWidgets('Responsive columns preserve readable text at large scale', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(900, 400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ResponsiveColumns(children: [Text('Pertama'), Text('Kedua')]),
        ),
      ),
    );
    expect(
      tester.getTopLeft(find.text('Pertama')).dy,
      tester.getTopLeft(find.text('Kedua')).dy,
    );
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpAndSettle();
    expect(
      tester.getTopLeft(find.text('Kedua')).dy,
      greaterThan(tester.getTopLeft(find.text('Pertama')).dy),
    );
  });
  testWidgets('Pages with empty real data adapt to small landscape', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(640, 320);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    for (final page in [
      const AuthScreen(),
      const StoreSetupScreen(),
      const HomeScreen(),
      const ProfileScreen(),
      const ReportsScreen(),
      const CashierScreen(),
      const ProductsScreen(),
    ]) {
      await tester.pumpWidget(MaterialApp(home: page));
      await tester.pumpAndSettle();
      expect(
        tester.takeException(),
        isNull,
        reason: page.runtimeType.toString(),
      );
    }
  });
  testWidgets('Rotation preserves login input', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const MaterialApp(home: AuthScreen()));
    await tester.enterText(
      find.byKey(const ValueKey('identity')),
      'user@example.com',
    );
    tester.view.physicalSize = const Size(844, 390);
    await tester.pumpAndSettle();
    expect(find.text('user@example.com'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
