import 'dart:math';
import 'package:flutter/material.dart';
import 'package:ocp_flutter_core/theme/ocp_colors.dart';
import '../models/blip.dart';

class SonarPPI extends StatefulWidget {
  final List<Blip> blips;
  final double sweepAngle; // radians
  final double rangeKm;
  final double sweepSpeed; // seconds per revolution
  final VoidCallback? onTap;
  final ValueChanged<Blip>? onBlipTap;

  const SonarPPI({
    super.key,
    this.blips = const [],
    this.sweepAngle = 0.0,
    this.rangeKm = 10.0,
    this.sweepSpeed = 4.0,
    this.onTap,
    this.onBlipTap,
  });

  @override
  State<SonarPPI> createState() => _SonarPPIState();
}

class _SonarPPIState extends State<SonarPPI>
    with SingleTickerProviderStateMixin {
  late AnimationController _sweepController;

  @override
  void initState() {
    super.initState();
    _sweepController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: (widget.sweepSpeed * 1000).round()),
    )..repeat();
  }

  @override
  void didUpdateWidget(SonarPPI oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.sweepSpeed != widget.sweepSpeed) {
      _sweepController.duration =
          Duration(milliseconds: (widget.sweepSpeed * 1000).round());
    }
  }

  @override
  void dispose() {
    _sweepController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _sweepController,
      builder: (context, _) {
        final sweepAngle =
            widget.sweepAngle + (_sweepController.value * 2 * pi);
        return GestureDetector(
          onTap: widget.onTap,
          child: CustomPaint(
            painter: _SonarPainter(
              blips: widget.blips,
              sweepAngle: sweepAngle,
              rangeKm: widget.rangeKm,
            ),
            size: Size.infinite,
          ),
        );
      },
    );
  }
}

class _SonarPainter extends CustomPainter {
  final List<Blip> blips;
  final double sweepAngle;
  final double rangeKm;

  _SonarPainter({
    required this.blips,
    required this.sweepAngle,
    required this.rangeKm,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2 - 20;

    // Background
    canvas.drawCircle(
        center, radius, Paint()..color = OcpColors.ocpBg);

    // Range rings
    final ringPaint = Paint()
      ..color = OcpColors.ocpBorder.withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    for (final frac in [0.25, 0.5, 0.75, 1.0]) {
      canvas.drawCircle(center, radius * frac, ringPaint);
    }

    // Bearing lines (every 30°)
    final bearingPaint = Paint()
      ..color = OcpColors.ocpBorder.withOpacity(0.3)
      ..strokeWidth = 1;

    const labels = ['N', '30', '60', 'E', '120', '150', 'S', '210', '240', 'W', '300', '330'];

    for (int i = 0; i < 12; i++) {
      final angle = i * 30.0 * pi / 180;
      final endX = center.dx + radius * sin(angle);
      final endY = center.dy - radius * cos(angle);
      canvas.drawLine(center, Offset(endX, endY), bearingPaint);

      // Labels
      final labelX = center.dx + (radius + 14) * sin(angle);
      final labelY = center.dy - (radius + 14) * cos(angle);
      final tp = TextPainter(
        text: TextSpan(
          text: labels[i],
          style: TextStyle(
            color: OcpColors.ocpTextMuted,
            fontSize: 10,
            fontFamily: 'JetBrainsMono',
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      tp.layout();
      tp.paint(canvas, Offset(labelX - tp.width / 2, labelY - tp.height / 2));
    }

    // Sweep arm with afterglow
    // Main sweep line
    final sweepEndX = center.dx + radius * sin(sweepAngle);
    final sweepEndY = center.dy - radius * cos(sweepAngle);

    final sweepPaint = Paint()
      ..color = OcpColors.ocpAccent
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(center, Offset(sweepEndX, sweepEndY), sweepPaint);

    // Afterglow arc (30° trail)
    const afterglowAngle = 30.0 * pi / 180;
    for (int i = 0; i < 15; i++) {
      final trailAngle = sweepAngle - afterglowAngle * (i / 15);
      final alpha = (1.0 - i / 15) * 0.3;
      final endX = center.dx + radius * sin(trailAngle);
      final endY = center.dy - radius * cos(trailAngle);
      canvas.drawLine(
        center,
        Offset(endX, endY),
        Paint()
          ..color = OcpColors.ocpAccent.withOpacity(alpha)
          ..strokeWidth = 1,
      );
    }

    // Blips
    for (final blip in blips) {
      final opacity = blip.opacity;
      if (opacity <= 0) continue;

      final blipAngle = blip.bearing * pi / 180;
      final blipX = center.dx + radius * blip.range * sin(blipAngle);
      final blipY = center.dy - radius * blip.range * cos(blipAngle);
      final blipRadius = blip.isHighlighted ? 6.0 : 4.0;

      // Glow
      canvas.drawCircle(
        Offset(blipX, blipY),
        blipRadius + 3,
        Paint()
          ..color = (blip.isHighlighted
                  ? OcpColors.ocpAmber
                  : OcpColors.ocpAccent)
              .withOpacity(opacity * 0.3),
      );

      // Dot
      canvas.drawCircle(
        Offset(blipX, blipY),
        blipRadius,
        Paint()
          ..color = (blip.isHighlighted
                  ? OcpColors.ocpAmber
                  : OcpColors.ocpAccent)
              .withOpacity(opacity),
      );

      // Label
      if (blip.label.isNotEmpty) {
        final tp = TextPainter(
          text: TextSpan(
            text: blip.label,
            style: TextStyle(
              color: OcpColors.ocpText.withOpacity(opacity),
              fontSize: 10,
              fontFamily: 'JetBrainsMono',
            ),
          ),
          textDirection: TextDirection.ltr,
        );
        tp.layout();
        tp.paint(canvas, Offset(blipX + 8, blipY - 8));
      }
    }

    // Range labels
    for (final frac in [0.25, 0.5, 0.75, 1.0]) {
      final km = (rangeKm * frac).toStringAsFixed(1);
      final tp = TextPainter(
        text: TextSpan(
          text: '${km}km',
          style: TextStyle(
            color: OcpColors.ocpTextMuted,
            fontSize: 9,
            fontFamily: 'JetBrainsMono',
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      tp.layout();
      tp.paint(
          canvas, Offset(center.dx + 4, center.dy - radius * frac - 12));
    }
  }

  @override
  bool shouldRepaint(_SonarPainter oldDelegate) =>
      blips != oldDelegate.blips ||
      sweepAngle != oldDelegate.sweepAngle ||
      rangeKm != oldDelegate.rangeKm;
}