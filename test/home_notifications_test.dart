import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nalara/products.dart';
import 'package:nalara/screens/home_screen.dart';
import 'package:nalara/screens/package_screen.dart';
import 'package:nalara/screens/products_screen.dart';
import 'package:nalara/screens/reports_screen.dart';
import 'package:nalara/session.dart';
import 'package:nalara/widgets/home_notifications_sheet.dart';
import 'package:nalara/widgets/premium_report_notice.dart';
import 'package:nalara/widgets/premium_report_pages.dart';

Widget _homeWithSessionNavigator() => MaterialApp(
  home: Navigator(
    onGenerateRoute: (_) =>
        MaterialPageRoute<void>(builder: (_) => const HomeScreen()),
  ),
);

Product _product(String id, int stock, {bool active = true}) => Product(
  id: id,
  name: 'Produk $id',
  price: 10000,
  cost: 5000,
  stock: stock,
  minimumStock: 5,
  active: active,
);

Future<void> _openNotifications(WidgetTester tester) async {
  await tester.ensureVisible(find.byTooltip('Notifikasi'));
  await tester.tap(find.byTooltip('Notifikasi'));
  await tester.pumpAndSettle();
}

Future<void> _openInsights(WidgetTester tester) async {
  await tester.ensureVisible(find.text('Lainnya'));
  await tester.tap(find.text('Lainnya'));
  await tester.pumpAndSettle();
}

void main() {
  setUp(() {
    ProductCatalog.instance.replace([]);
    StoreSession.instance.premium.value = false;
  });
  tearDown(() {
    ProductCatalog.instance.replace([]);
    StoreSession.instance.premium.value = false;
  });

  testWidgets('Notifications close without removing the nested Home route', (
    tester,
  ) async {
    await tester.pumpWidget(_homeWithSessionNavigator());
    for (var attempt = 0; attempt < 2; attempt++) {
      await _openNotifications(tester);
      expect(find.byType(HomeNotificationsSheet), findsOneWidget);
      expect(find.text('Tidak ada stok menipis.'), findsOneWidget);
      await tester.tap(find.byTooltip('Tutup'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byType(HomeNotificationsSheet), findsNothing);
      expect(find.byType(HomeScreen), findsOneWidget);
    }
  });

  testWidgets('Stock alerts prioritize empty stock and update while open', (
    tester,
  ) async {
    ProductCatalog.instance.replace([
      _product('low', 2),
      _product('empty', 0),
      _product('safe', 20),
      _product('inactive', 0, active: false),
    ]);
    await tester.pumpWidget(_homeWithSessionNavigator());
    await _openNotifications(tester);
    expect(find.text('2 produk perlu perhatian'), findsOneWidget);
    expect(find.text('1 stok habis'), findsOneWidget);
    expect(find.text('1 stok menipis'), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('Produk empty')).dy,
      lessThan(tester.getTopLeft(find.text('Produk low')).dy),
    );
    expect(find.text('Produk safe'), findsNothing);
    expect(find.text('Produk inactive'), findsNothing);
    ProductCatalog.instance.replace([
      _product('low', 10),
      _product('empty', 20),
    ]);
    await tester.pumpAndSettle();
    expect(find.text('Semua stok aman'), findsOneWidget);
    expect(find.text('2 produk perlu perhatian'), findsNothing);
  });

  testWidgets('Notification opens the selected product inside the session', (
    tester,
  ) async {
    ProductCatalog.instance.replace([_product('coffee', 0)]);
    await tester.pumpWidget(_homeWithSessionNavigator());
    await _openNotifications(tester);
    await tester.tap(find.text('Lihat produk'));
    await tester.pumpAndSettle();
    expect(find.byType(HomeNotificationsSheet), findsNothing);
    expect(
      tester.widget<ProductDetailScreen>(find.byType(ProductDetailScreen)).id,
      'coffee',
    );
    await tester.tap(find.byTooltip('Kembali'));
    await tester.pumpAndSettle();
    expect(find.byType(HomeScreen), findsOneWidget);
  });

  testWidgets(
    'Long notifications scroll with accessible close in small landscape',
    (tester) async {
      tester.view.physicalSize = const Size(640, 320);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      ProductCatalog.instance.replace(
        List.generate(50, (index) => _product('$index', 1)),
      );
      await tester.pumpWidget(_homeWithSessionNavigator());
      await _openNotifications(tester);
      expect(tester.takeException(), isNull);
      final scrollable = find.descendant(
        of: find.byType(HomeNotificationsSheet),
        matching: find.byType(Scrollable),
      );
      expect(scrollable, findsOneWidget);
      final state = tester.state<ScrollableState>(scrollable);
      expect(state.position.maxScrollExtent, greaterThan(0));
      await tester.drag(scrollable, const Offset(0, -300));
      await tester.pumpAndSettle();
      expect(state.position.pixels, greaterThan(0));
      expect(find.byTooltip('Tutup').hitTestable(), findsOneWidget);
      await tester.tap(find.byTooltip('Tutup'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byType(HomeScreen), findsOneWidget);
    },
  );

  testWidgets('Basic users see the premium requirement and can view packages', (
    tester,
  ) async {
    await tester.pumpWidget(_homeWithSessionNavigator());
    await _openInsights(tester);
    expect(find.byType(ReportsScreen), findsOneWidget);
    expect(find.byType(PremiumReportNotice), findsOneWidget);
    expect(find.byType(PremiumReportPage), findsNothing);
    expect(
      tester.widget<ReportsScreen>(find.byType(ReportsScreen)).view,
      ReportView.insights,
    );
    await tester.ensureVisible(find.text('Lihat Paket'));
    await tester.tap(find.text('Lihat Paket'));
    await tester.pumpAndSettle();
    expect(find.byType(PackageScreen), findsOneWidget);
  });

  testWidgets(
    'Premium users open insights; expiry immediately hides premium content',
    (tester) async {
      StoreSession.instance.premium.value = true;
      await tester.pumpWidget(_homeWithSessionNavigator());
      await _openInsights(tester);
      expect(find.byType(PremiumReportNotice), findsNothing);
      expect(
        tester.widget<PremiumReportPage>(find.byType(PremiumReportPage)).view,
        ReportView.insights,
      );
      StoreSession.instance.premium.value = false;
      await tester.pumpAndSettle();
      expect(find.byType(PremiumReportPage), findsNothing);
      expect(find.byType(PremiumReportNotice), findsOneWidget);
      StoreSession.instance.premium.value = true;
      await tester.pumpAndSettle();
      expect(find.byType(PremiumReportPage), findsOneWidget);
      await tester.tap(find.byTooltip('Kembali'));
      await tester.pumpAndSettle();
      expect(find.byType(HomeScreen), findsOneWidget);
    },
  );
}
