import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../colors.dart';
import '../products.dart';
import '../transactions.dart';

// Grafik memakai nilai transaksi asli; ketuk titik untuk melihat nominalnya.
class RevenueTrendChart extends StatefulWidget {
  const RevenueTrendChart({
    super.key,
    required this.values,
    required this.start,
  });
  final List<int> values;
  final DateTime start;

  @override
  State<RevenueTrendChart> createState() => _RevenueTrendChartState();
}

class _RevenueTrendChartState extends State<RevenueTrendChart> {
  int? _selected;

  @override
  void didUpdateWidget(RevenueTrendChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.start != widget.start ||
        oldWidget.values.length != widget.values.length) {
      _selected = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.textScalerOf(context).scale(10) / 10;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_selected != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              '${transactionDate(widget.start.add(Duration(days: _selected!)))} · ${productRupiah(widget.values[_selected!])}',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.background,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        Semantics(
          label:
              'Grafik omzet harian. ${[for (var i = 0; i < widget.values.length; i++) '${transactionDate(widget.start.add(Duration(days: i)))}: ${productRupiah(widget.values[i])}'].join('. ')}',
          child: LayoutBuilder(
            builder: (context, constraints) {
              final left = 48 * math.min(scale, 1.5);
              void select(double x) {
                if (widget.values.isEmpty) return;
                final width = constraints.maxWidth - left - 12;
                if (width <= 0) return;
                setState(
                  () => _selected =
                      ((x - left) / width * (widget.values.length - 1))
                          .round()
                          .clamp(0, widget.values.length - 1),
                );
              }

              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapDown: (details) => select(details.localPosition.dx),
                onHorizontalDragUpdate: (details) =>
                    select(details.localPosition.dx),
                child: SizedBox(
                  height: 200 + 20 * (scale - 1),
                  child: CustomPaint(
                    painter: _RevenuePainter(
                      values: widget.values,
                      start: widget.start,
                      selected: _selected,
                      scale: math.min(scale, 1.5),
                      textStyle:
                          Theme.of(context).textTheme.bodySmall ??
                          const TextStyle(),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _RevenuePainter extends CustomPainter {
  const _RevenuePainter({
    required this.values,
    required this.start,
    required this.selected,
    required this.scale,
    required this.textStyle,
  });
  final List<int> values;
  final DateTime start;
  final int? selected;
  final double scale;
  final TextStyle textStyle;

  String _amount(double amount) {
    if (amount >= 1000000000) {
      return 'Rp${(amount / 1000000000).toStringAsFixed(1)}M';
    }
    if (amount >= 1000000) {
      return 'Rp${(amount / 1000000).toStringAsFixed(1)}jt';
    }
    if (amount >= 1000) return 'Rp${(amount / 1000).toStringAsFixed(0)}rb';
    return 'Rp${amount.toStringAsFixed(0)}';
  }

  @override
  void paint(Canvas canvas, Size size) {
    final plot = Rect.fromLTRB(
      48 * scale,
      14,
      size.width - 12,
      size.height - 30 * scale,
    );
    if (plot.width <= 0 || plot.height <= 0) return;
    final largest = values.fold<int>(0, math.max);
    final maximum = largest == 0 ? 1000.0 : largest * 1.2;
    final grid = Paint()
      ..color = const Color(0xFFEEF2F8)
      ..strokeWidth = 1;
    for (var tick = 0; tick < 3; tick++) {
      final y = plot.bottom - plot.height * tick / 2;
      canvas.drawLine(Offset(plot.left, y), Offset(plot.right, y), grid);
      _text(
        canvas,
        _amount(maximum * tick / 2),
        Offset(plot.left - 7, y - 6),
        right: true,
      );
    }
    if (values.isEmpty) return;
    final points = [
      for (var i = 0; i < values.length; i++)
        Offset(
          values.length == 1
              ? plot.center.dx
              : plot.left + plot.width * i / (values.length - 1),
          plot.bottom - plot.height * values[i] / maximum,
        ),
    ];
    final line = Path()..moveTo(points.first.dx, points.first.dy);
    for (var i = 1; i < points.length; i++) {
      final middle = (points[i - 1].dx + points[i].dx) / 2;
      line.cubicTo(
        middle,
        points[i - 1].dy,
        middle,
        points[i].dy,
        points[i].dx,
        points[i].dy,
      );
    }
    if (points.length > 1) {
      final area = Path.from(line)
        ..lineTo(points.last.dx, plot.bottom)
        ..lineTo(points.first.dx, plot.bottom)
        ..close();
      canvas.drawPath(
        area,
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0x183B82F6), Color(0x033B82F6)],
          ).createShader(plot),
      );
      canvas.drawPath(
        line,
        Paint()
          ..color = const Color(0xFF233F91)
          ..strokeWidth = 2.2
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round,
      );
    }
    final stride = math.max(
      1,
      ((values.length - 1) / (plot.width < 220 ? 3 : 6)).ceil(),
    );
    const weekdays = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];
    for (var i = 0; i < points.length; i++) {
      if (values.length <= 7 || selected == i) {
        canvas.drawCircle(
          points[i],
          selected == i ? 4 : 2,
          Paint()..color = const Color(0xFF233F91),
        );
      }
      if (i % stride != 0) continue;
      final day = start.add(Duration(days: i));
      _text(
        canvas,
        values.length <= 7
            ? weekdays[day.weekday - 1]
            : '${day.day}/${day.month}',
        Offset(points[i].dx, plot.bottom + 10),
        centered: true,
      );
    }
    if (selected != null && selected! < points.length) {
      final point = points[selected!];
      canvas.drawLine(
        Offset(point.dx, plot.top),
        Offset(point.dx, plot.bottom),
        Paint()
          ..color = const Color(0x553B82F6)
          ..strokeWidth = 1,
      );
      canvas.drawCircle(point, 5, Paint()..color = Colors.white);
      canvas.drawCircle(point, 3, Paint()..color = AppColors.logoBlue);
    }
  }

  void _text(
    Canvas canvas,
    String value,
    Offset offset, {
    bool right = false,
    bool centered = false,
  }) {
    final painter = TextPainter(
      text: TextSpan(
        text: value,
        style: textStyle.copyWith(
          color: const Color(0xFF91A1BB),
          fontSize: 9 * scale,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(
      canvas,
      Offset(
        offset.dx -
            (right
                ? painter.width
                : centered
                ? painter.width / 2
                : 0),
        offset.dy,
      ),
    );
  }

  @override
  bool shouldRepaint(_RevenuePainter oldDelegate) => true;
}
