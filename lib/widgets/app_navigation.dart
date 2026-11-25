// Header dan navbar bersama menjaga tema serta tujuan navigasi tetap konsisten.
import 'package:flutter/material.dart';

import '../colors.dart';
import '../screens/cashier_screen.dart';
import '../screens/products_screen.dart';
import '../screens/transactions_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/reports_screen.dart';

class NalaraHeader extends StatelessWidget implements PreferredSizeWidget {
  const NalaraHeader({super.key, required this.title, this.onBack});
  final String title;
  final VoidCallback? onBack;
  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
  @override
  Widget build(BuildContext context) => AppBar(
    leading: onBack != null || Navigator.of(context).canPop()
        ? IconButton(
            tooltip: 'Kembali',
            icon: const Icon(Icons.chevron_left),
            onPressed: onBack ?? () => Navigator.of(context).pop(),
          )
        : null,
    title: Text(
      title,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
    ),
    backgroundColor: AppColors.background,
    foregroundColor: Colors.white,
    surfaceTintColor: Colors.transparent,
    elevation: 0,
  );
}

class NalaraNavigation extends StatelessWidget {
  const NalaraNavigation({super.key, required this.index});
  final int index;

  // Menu diganti langsung tanpa animasi bertumpuk atau membuka Home di antaranya.
  void _navigate(BuildContext context, int selected) {
    if (selected == index) return;
    final navigator = Navigator.of(context);
    if (selected == 0) {
      navigator.popUntil((route) => route.isFirst);
      return;
    }
    final route = PageRouteBuilder<void>(
      transitionDuration: Duration.zero,
      reverseTransitionDuration: Duration.zero,
      pageBuilder: (_, animation, secondaryAnimation) => switch (selected) {
        1 => const CashierScreen(),
        2 => const ProductsScreen(),
        3 => const TransactionsScreen(),
        4 => const ReportsScreen(),
        _ => const ProfileScreen(),
      },
    );
    if (index == 0) {
      navigator.push(route);
    } else {
      navigator.pushReplacement(route);
    }
  }

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: const BoxDecoration(
      color: Colors.white,
      border: Border(top: BorderSide(color: Color(0xFFEDF1F7))),
    ),
    child: Padding(
      padding: const EdgeInsets.only(top: 6),
      child: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: index,
        backgroundColor: Colors.white,
        selectedItemColor: AppColors.background,
        unselectedItemColor: const Color(0xFF94A3B8),
        selectedFontSize: 10,
        unselectedFontSize: 10,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500),
        iconSize: 22,
        elevation: 0,
        onTap: (selected) => _navigate(context, selected),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.point_of_sale_rounded),
            label: 'Kasir',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.inventory_2_rounded),
            label: 'Produk',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long_rounded),
            label: 'Transaksi',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.show_chart_rounded),
            label: 'Laporan',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_rounded),
            label: 'Profil',
          ),
        ],
      ),
    ),
  );
}
