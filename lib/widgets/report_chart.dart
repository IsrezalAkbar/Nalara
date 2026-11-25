import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../colors.dart';
import '../products.dart';

class ReportChart extends StatefulWidget {
  const ReportChart({
    super.key,
    required this.values,
    required this.labels,
    this.secondary,
    this.bars = false,
    this.money = false,
    this.color = AppColors.background,
    required this.description,
  });
  final List<double> values;
  final List<double>? secondary;
  final List<String> labels;
  final bool bars, money;
  final Color color;
  final String description;

  @override
  State<ReportChart> createState() => _ReportChartState();
}

class _ReportChartState extends State<ReportChart> {
  int? _selected;
  @override
  void didUpdateWidget(ReportChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.values != widget.values) _selected = null;
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      if (_selected != null && _selected! < widget.values.length)
        Text(
          '${widget.labels[_selected!]}: ${widget.money ? productRupiah(widget.values[_selected!].round()) : widget.values[_selected!].toStringAsFixed(0)}',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
      Semantics(
        label:
            '${widget.description}. ${[for (var i = 0; i < widget.values.length; i++) '${widget.labels[i]}: ${widget.values[i].round()}'].join(', ')}',
        image: true,
        child: LayoutBuilder(
          builder: (context, constraints) => GestureDetector(
            onTapDown: (event) {
              if (widget.values.isEmpty || constraints.maxWidth <= 60) return;
              setState(
                () => _selected =
                    ((event.localPosition.dx - 44) /
                            (constraints.maxWidth - 56) *
                            widget.values.length)
                        .floor()
                        .clamp(0, widget.values.length - 1),
              );
            },
            child: SizedBox(
              height: 190,
              width: double.infinity,
              child: CustomPaint(
                painter: _ReportPainter(
                  widget,
                  _selected,
                  Theme.of(context).textTheme.bodySmall ?? const TextStyle(),
                ),
              ),
            ),
          ),
        ),
      ),
    ],
  );
}

class _ReportPainter extends CustomPainter {
  _ReportPainter(this.chart, this.selected, this.textStyle);
  final ReportChart chart;
  final int? selected;
  final TextStyle textStyle;

  String amount(double value) {
    final prefix = chart.money ? 'Rp' : '';
    if (value.abs() >= 1000000) {
      return '$prefix${(value / 1000000).toStringAsFixed(1)}jt';
    }
    if (value.abs() >= 1000) {
      return '$prefix${(value / 1000).toStringAsFixed(0)}rb';
    }
    return '$prefix${value.round()}';
  }

  void text(
    Canvas canvas,
    String value,
    Offset position, {
    bool right = false,
  }) {
    final painter = TextPainter(
      text: TextSpan(
        text: value,
        style: textStyle.copyWith(color: const Color(0xFF91A1BB), fontSize: 9),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(
      canvas,
      Offset(
        position.dx - (right ? painter.width : painter.width / 2),
        position.dy,
      ),
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    final plot = Rect.fromLTRB(44, 18, size.width - 10, size.height - 30);
    if (plot.width <= 0 || chart.values.isEmpty) return;
    final all = [...chart.values, ...?chart.secondary];
    final minValue = math.min(0.0, all.reduce(math.min));
    final maxValue = math.max(1.0, all.reduce(math.max)) * 1.15;
    final span = maxValue - minValue;
    double y(double value) =>
        plot.bottom - (value - minValue) / span * plot.height;
    final grid = Paint()
      ..color = const Color(0xFFEEF2F8)
      ..strokeWidth = 1;
    for (var i = 0; i <= 4; i++) {
      final value = minValue + span * i / 4;
      canvas.drawLine(
        Offset(plot.left, y(value)),
        Offset(plot.right, y(value)),
        grid,
      );
      text(
        canvas,
        amount(value),
        Offset(plot.left - 7, y(value) - 5),
        right: true,
      );
    }
    final step = plot.width / chart.values.length;
    Offset point(int i, double value) =>
        Offset(plot.left + step * (i + .5), y(value));
    if (chart.bars) {
      for (var i = 0; i < chart.values.length; i++) {
        final p = point(i, chart.values[i]);
        final last = i == chart.values.length - 1;
        final color = selected == i || last
            ? chart.color
            : i >= chart.values.length - 3
            ? AppColors.logoBlue
            : const Color(0xFFDDE5F2);
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTRB(
              p.dx - step * .28,
              math.min(y(0), p.dy),
              p.dx + step * .28,
              math.max(y(0), p.dy),
            ),
            const Radius.circular(3),
          ),
          Paint()..color = color,
        );
      }
    } else {
      void line(List<double> values, Color color, {bool dotted = false}) {
        final paint = Paint()
          ..color = color
          ..strokeWidth = 2.5
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round;
        for (var i = 1; i < values.length; i++) {
          final a = point(i - 1, values[i - 1]), b = point(i, values[i]);
          if (dotted) {
            final length = (b - a).distance;
            for (double d = 0; d < length; d += 8) {
              canvas.drawLine(
                Offset.lerp(a, b, d / length)!,
                Offset.lerp(a, b, math.min(d + 3, length) / length)!,
                paint,
              );
            }
          } else {
            canvas.drawLine(a, b, paint);
          }
        }
        if (values.length == 1) {
          canvas.drawCircle(point(0, values[0]), 3, Paint()..color = color);
        }
      }

      line(chart.values, chart.color);
      if (chart.secondary != null) {
        line(chart.secondary!, AppColors.logoBlue, dotted: true);
      }
    }
    final labelCount = math.max(2, (plot.width / 38).floor());
    final stride = math.max(1, (chart.values.length / labelCount).ceil());
    for (var i = 0; i < chart.values.length; i++) {
      if ((i % stride == 0 && i < chart.values.length - stride) ||
          i == chart.values.length - 1) {
        text(canvas, chart.labels[i], Offset(point(i, 0).dx, plot.bottom + 10));
      }
    }
    if (selected != null && selected! < chart.values.length) {
      final p = point(selected!, chart.values[selected!]);
      canvas.drawCircle(p, 4, Paint()..color = chart.color);
    }
  }

  @override
  bool shouldRepaint(covariant _ReportPainter oldDelegate) => true;
}
