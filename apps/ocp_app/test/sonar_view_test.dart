import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ocp_app/widgets/sonar_view.dart';
import 'package:ocp_maps/ocp_maps.dart';

void main() {
  testWidgets('sonar view renders a projected scene and taps a blip',
      (tester) async {
    const projector = SonarProjector();
    final now = DateTime.utc(2026, 1, 1, 12);
    final scene = projector.project(
      self: const GeoPoint(latitude: 0, longitude: 0),
      samplesByNode: {
        'alpha': [
          SonarSample(
            nodeId: 'alpha',
            label: 'Alpha',
            position: const GeoPoint(latitude: 0.01, longitude: 0),
            timestamp: now,
          ),
        ],
      },
      center: const ScreenOffset(150, 150),
      radiusPixels: 140,
      now: now,
    );

    SonarBlip? tapped;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 300,
            height: 300,
            child: SonarView(
              viewModel: scene,
              onBlipTap: (blip) => tapped = blip,
            ),
          ),
        ),
      ),
    );

    expect(find.byType(CustomPaint), findsWidgets);

    final blip = scene.blips.single;
    await tester.tapAt(Offset(blip.position.dx, blip.position.dy));
    expect(tapped, isNotNull);
    expect(tapped!.nodeId, 'alpha');
  });
}
