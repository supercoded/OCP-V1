import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:ocp_maps/ocp_maps.dart';

/// Presentation-only sonar/radar renderer.
///
/// Takes a fully-projected [SonarViewModel] from `ocp_maps` and paints it: all
/// geometry and classification decisions live in the projector, this widget
/// only draws. Tapping a blip invokes [onBlipTap].
class SonarView extends StatelessWidget {
  const SonarView({
    required this.viewModel,
    this.onBlipTap,
    super.key,
  });

  final SonarViewModel viewModel;
  final void Function(SonarBlip blip)? onBlipTap;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return GestureDetector(
          onTapUp: onBlipTap == null
              ? null
              : (details) {
                  final blip = _hitTest(details.localPosition);
                  if (blip != null) onBlipTap!(blip);
                },
          child: CustomPaint(
            size: Size(constraints.maxWidth, constraints.maxHeight),
            painter: _SonarPainter(viewModel),
          ),
        );
      },
    );
  }

  SonarBlip? _hitTest(Offset point) {
    const hitRadius = 22.0;
    SonarBlip? best;
    var bestDistance = hitRadius;
    for (final blip in viewModel.blips) {
      final dx = blip.position.dx - point.dx;
      final dy = blip.position.dy - point.dy;
      final distance = math.sqrt(dx * dx + dy * dy);
      if (distance <= bestDistance) {
        bestDistance = distance;
        best = blip;
      }
    }
    return best;
  }
}

class _SonarPainter extends CustomPainter {
  _SonarPainter(this.vm);

  final SonarViewModel vm;

  static const _active = Color(0xFF39FF14);
  static const _stale = Color(0xFF6B7A5A);
  static const _grid = Color(0xFF1F3D1F);
  static const _self = Color(0xFF7FDBFF);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(vm.center.dx, vm.center.dy);

    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xFF06120A),
    );

    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = _grid;
    for (final radius in vm.ringRadiiPixels) {
      canvas.drawCircle(center, radius, ringPaint);
    }

    // Cross-hairs.
    canvas.drawLine(
      Offset(center.dx, center.dy - vm.radiusPixels),
      Offset(center.dx, center.dy + vm.radiusPixels),
      ringPaint,
    );
    canvas.drawLine(
      Offset(center.dx - vm.radiusPixels, center.dy),
      Offset(center.dx + vm.radiusPixels, center.dy),
      ringPaint,
    );

    _paintRingLabels(canvas, center);

    // Self marker.
    canvas.drawCircle(center, 4, Paint()..color = _self);

    for (final blip in vm.blips) {
      _paintBlip(canvas, blip);
    }
  }

  void _paintRingLabels(Canvas canvas, Offset center) {
    for (var i = 0; i < vm.ringRangeMeters.length; i++) {
      final radius = vm.ringRadiiPixels[i];
      final label = _formatRange(vm.ringRangeMeters[i]);
      final tp = TextPainter(
        text: TextSpan(
          text: label,
          style: const TextStyle(color: _stale, fontSize: 10),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(center.dx + 3, center.dy - radius - tp.height));
    }
  }

  void _paintBlip(Canvas canvas, SonarBlip blip) {
    final position = Offset(blip.position.dx, blip.position.dy);
    final color = blip.activity == BlipActivity.active ? _active : _stale;

    final motion = blip.motion;
    if (motion != null && motion.trail.length >= 2) {
      final trailPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = color.withValues(alpha: 0.5);
      final path = Path()
        ..moveTo(motion.trail.first.dx, motion.trail.first.dy);
      for (final point in motion.trail.skip(1)) {
        path.lineTo(point.dx, point.dy);
      }
      canvas.drawPath(path, trailPaint);
    }

    canvas.drawCircle(position, blip.clamped ? 5 : 6, Paint()..color = color);

    final tp = TextPainter(
      text: TextSpan(
        text: blip.label,
        style: TextStyle(color: color, fontSize: 11),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, position + const Offset(8, -6));
  }

  static String _formatRange(double meters) {
    if (meters >= 1000) {
      return '${(meters / 1000).toStringAsFixed(meters % 1000 == 0 ? 0 : 1)} km';
    }
    return '${meters.toStringAsFixed(0)} m';
  }

  @override
  bool shouldRepaint(covariant _SonarPainter oldDelegate) =>
      oldDelegate.vm != vm;
}
