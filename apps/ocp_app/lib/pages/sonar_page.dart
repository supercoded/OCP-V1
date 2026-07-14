import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ocp_flutter_core/theme/ocp_colors.dart';
import '../providers/sonar_provider.dart';
import '../widgets/sonar_ppi.dart';

class SonarPage extends StatelessWidget {
  const SonarPage({super.key});

  @override
  Widget build(BuildContext context) {
    final sonar = context.watch<SonarProvider>();

    return Column(
      children: [
        Expanded(
          child: Center(
            child: AspectRatio(
              aspectRatio: 1,
              child: SonarPPI(
                blips: sonar.blips,
                sweepAngle: sonar.sweepAngle,
                rangeKm: sonar.rangeKm,
                sweepSpeed: sonar.sweepSpeed,
              ),
            ),
          ),
        ),
        _buildControls(context, sonar),
      ],
    );
  }

  Widget _buildControls(BuildContext context, SonarProvider sonar) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: OcpColors.ocpPanel,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _controlChip('Range: ${sonar.rangeKm.toStringAsFixed(1)} km'),
          _controlChip('Speed: ${sonar.sweepSpeed.toStringAsFixed(1)} s/rev'),
          _controlChip('Blips: ${sonar.blips.length}'),
        ],
      ),
    );
  }

  Widget _controlChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: OcpColors.ocpPanel2,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: OcpColors.ocpBorder),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontFamily: 'JetBrainsMono',
          fontSize: 12,
          color: OcpColors.ocpBright,
        ),
      ),
    );
  }
}