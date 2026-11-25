import 'analytics.dart';

class ProductPerformance {
  ProductPerformance(this.id, this.name);
  final String id;
  final String name;
  int quantity = 0;
  int revenue = 0;
  int cost = 0;
  int get profit => revenue - cost;
  double get margin => revenue == 0 ? 0 : profit / revenue * 100;
}

/// Uses transaction snapshots, with discounts allocated once across each sale.
List<ProductPerformance> productPerformance(SalesAnalytics analytics) {
  final products = <String, ProductPerformance>{};
  for (final sale in analytics.sales) {
    var subtotalSoFar = 0;
    var allocatedDiscount = 0;
    for (var i = 0; i < sale.items.length; i++) {
      final item = sale.items[i];
      subtotalSoFar += item.subtotal;
      // Cumulative allocation prevents rounding remainders from overwhelming
      // a small final item while preserving the transaction's exact discount.
      final discountSoFar = i == sale.items.length - 1
          ? sale.discount
          : sale.subtotal == 0
          ? 0
          : sale.discount * subtotalSoFar ~/ sale.subtotal;
      final discount = discountSoFar - allocatedDiscount;
      allocatedDiscount = discountSoFar;
      final key = item.productId.isEmpty ? 'name:${item.name}' : item.productId;
      final product = products.putIfAbsent(
        key,
        () => ProductPerformance(item.productId, item.name),
      );
      product.quantity += item.quantity;
      product.revenue += item.subtotal - discount;
      product.cost += item.cost * item.quantity;
    }
  }
  return products.values.toList()
    ..sort((a, b) => b.quantity.compareTo(a.quantity));
}

double? percentageChange(num current, num previous) =>
    previous <= 0 ? null : (current - previous) / previous * 100;
