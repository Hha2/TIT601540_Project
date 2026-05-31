import 'package:flutter/material.dart';

class MoodLineChart extends StatelessWidget {
  final List<double> data; // values 0-4
  final dynamic theme;

  const MoodLineChart({super.key, required this.data, required this.theme});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) return const SizedBox.shrink();
    return CustomPaint(
      painter: _MoodChartPainter(data: data, theme: theme),
      child: const SizedBox.expand(),
    );
  }
}

class _MoodChartPainter extends CustomPainter {
  final List<double> data;
  final dynamic theme;

  _MoodChartPainter({required this.data, required this.theme});

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    const minVal = 0.0;
    const maxVal = 4.0;
    final range = maxVal - minVal;
    final w = size.width;
    final h = size.height;
    final n = data.length;

    // Grid lines
    final gridPaint = Paint()
      ..color = (theme.border as Color).withValues(alpha: 0.5)
      ..strokeWidth = 1;

    for (int i = 0; i <= 4; i++) {
      final y = h - (i / 4) * h;
      canvas.drawLine(Offset(0, y), Offset(w, y), gridPaint);
    }

    // Build points
    final points = <Offset>[];
    for (int i = 0; i < n; i++) {
      final x = n == 1 ? w / 2 : i / (n - 1) * w;
      final normalised = ((data[i] - minVal) / range).clamp(0.0, 1.0);
      final y = h - normalised * h * 0.85 - h * 0.075;
      points.add(Offset(x, y));
    }

    // Gradient fill
    final fillPath = Path()..moveTo(points.first.dx, h);
    for (final p in points) {
      fillPath.lineTo(p.dx, p.dy);
    }
    fillPath.lineTo(points.last.dx, h);
    fillPath.close();

    final accentColor = theme.accent as Color;
    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          accentColor.withValues(alpha: 0.3),
          accentColor.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawPath(fillPath, fillPaint);

    // Smooth line using cubic bezier
    final linePath = Path()..moveTo(points.first.dx, points.first.dy);
    for (int i = 1; i < points.length; i++) {
      final prev = points[i - 1];
      final curr = points[i];
      final midX = (prev.dx + curr.dx) / 2;
      linePath.cubicTo(midX, prev.dy, midX, curr.dy, curr.dx, curr.dy);
    }

    final linePaint = Paint()
      ..color = accentColor
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(linePath, linePaint);

    // Dots
    final dotPaint = Paint()..color = accentColor;
    final dotBgPaint = Paint()
      ..color = theme.card as Color
      ..style = PaintingStyle.fill;

    for (final p in points) {
      canvas.drawCircle(p, 5, dotBgPaint);
      canvas.drawCircle(p, 4, dotPaint);
    }
  }

  @override
  bool shouldRepaint(_MoodChartPainter old) =>
      old.data != data || old.theme != theme;
}
