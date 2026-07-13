import 'package:flutter/material.dart';
import 'package:ocp_flutter_core/theme/ocp_theme.dart';
import 'package:ocp_flutter_core/theme/ocp_text_styles.dart';
import 'package:provider/provider.dart';
import '../providers/connection_provider.dart';
import '../widgets/sidebar_navigation.dart';
import '../widgets/ocp_scaffold.dart';
import '../pages/sonar_page.dart';
import '../pages/messaging_page.dart';
import '../pages/network_page.dart';
import '../pages/devices_page.dart';
import '../pages/spectrum_page.dart';
import '../pages/map_page.dart';
import '../pages/settings_page.dart';

class OcpScaffold extends StatefulWidget {
  const OcpScaffold({super.key});

  @override
  State<OcpScaffold> createState() => _OcpScaffoldState();
}

class _OcpScaffoldState extends State<OcpScaffold> {
  int _selectedIndex = 0;

  static const List<Widget> _pages = [
    SonarPage(),
    MessagingPage(),
    NetworkPage(),
    DevicesPage(),
    SpectrumPage(),
    MapPage(),
    SettingsPage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final connection = Provider.of<ConnectionProvider>(context);
    return Scaffold(
      backgroundColor: OcpColors.ocpBg,
      body: Row(
        children: [
          SidebarNavigation(selectedIndex: _selectedIndex, onTap: _onItemTapper),
          Expanded(
            child: IndexedStack(
              index: _selectedIndex,
              children: _pages,
            ),
          ),
        ],
      ),
    );
  }

  void _onItemTapper(int index) => _onItemTapped(index);
}
