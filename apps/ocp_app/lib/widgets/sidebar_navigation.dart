import 'package:flutter/material.dart';
import 'package:ocp_flutter_core/theme/ocp_colors.dart';
import 'package:ocp_flutter_core/theme/ocp_text_styles.dart';

class SidebarNavigation extends StatelessWidget {
  final int selectedIndex;
  final void Function(int) onTap;

  const SidebarNavigation({
    super.key,
    required this.selectedIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const items = [
      _SidebarItemData('Sonar', Icons.radar),
      _SidebarItemData('Messaging', Icons.chat),
      _SidebarItemData('Network', Icons.hub),
      _SidebarItemData('Devices', Icons.radio),
      _SidebarItemData('Spectrum', Icons.graphic_eq),
      _SidebarItemData('Map', Icons.map),
      _SidebarItemData('Settings', Icons.settings),
    ];

    return Container(
      width: 80,
      color: OcpColors.ocpPanel,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: List.generate(items.length, (index) {
          final item = items[index];
          final isActive = index == selectedIndex;
          return GestureDetector(
            onTap: () => onTap(index),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              color: isActive ? OcpColors.ocpAccent.withValues(alpha: 0.2) : Colors.transparent,
              child: Column(
                children: [
                  Icon(item.icon, color: isActive ? OcpColors.ocpAccent : OcpColors.ocpTextMuted),
                  const SizedBox(height: 4),
                  Text(
                    item.title,
                    style: OcpTextStyles.caption.copyWith(
                      color: isActive ? OcpColors.ocpAccent : OcpColors.ocpTextMuted,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _SidebarItemData {
  final String title;
  final IconData icon;
  const _SidebarItemData(this.title, this.icon);
}
