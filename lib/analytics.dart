import 'transactions.dart';

class SalesAnalytics {
  SalesAnalytics(Iterable<SaleTransaction> history, this.start, this.end)
    : sales = history
          .where(
            (sale) => !sale.date.isBefore(start) && sale.date.isBefore(end),
          )
          .toList();
  final DateTime start;
  final DateTime end;
  final List<SaleTransaction> sales;
  int get revenue => sales.fold(0, (sum, sale) => sum + sale.total);
  int get cost => sales.fold(0, (sum, sale) => sum + sale.cost);
  int get profit => revenue - cost;
  int get quantity => sales.fold(0, (sum, sale) => sum + sale.quantity);
  Map<String, int> get sold {
    final result = <String, int>{};
    for (final sale in sales) {
      for (final item in sale.items) {
        result.update(
          item.name,
          (value) => value + item.quantity,
          ifAbsent: () => item.quantity,
        );
      }
    }
    return result;
  }

  List<MapEntry<String, int>> get ranking =>
      sold.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
  List<int> get dailyRevenue => List.generate(end.difference(start).inDays, (
    index,
  ) {
    final day = DateTime(start.year, start.month, start.day + index);
    final next = DateTime(day.year, day.month, day.day + 1);
    return sales
        .where((sale) => !sale.date.isBefore(day) && sale.date.isBefore(next))
        .fold(0, (sum, sale) => sum + sale.total);
  });
}
