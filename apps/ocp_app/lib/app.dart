import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ocp_flutter_core/ocp_flutter_core.dart';
import 'services/service_locator.dart';
import 'providers/connection_provider.dart';
import 'providers/sonar_provider.dart';
import 'providers/messaging_provider.dart';
import 'providers/network_provider.dart';
import 'providers/spectrum_provider.dart';
import 'providers/settings_provider.dart';
import 'widgets/ocp_scaffold.dart';

class OcpApp extends StatelessWidget {
  final SettingsProvider settingsProvider;

  const OcpApp({super.key, required this.settingsProvider});

  @override
  Widget build(BuildContext context) {
    final platform = ServiceLocator.platform;
    final storage = ServiceLocator.storage;

    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: settingsProvider),
        ChangeNotifierProvider(create: (_) => ConnectionProvider(platformService: platform, storageService: storage)),
        ChangeNotifierProvider(create: (_) => SonarProvider(platformService: platform)),
        ChangeNotifierProvider(create: (_) => MessagingProvider(platformService: platform, storageService: storage)),
        ChangeNotifierProvider(create: (_) => NetworkProvider(platformService: platform)),
        ChangeNotifierProvider(create: (_) => SpectrumProvider(platformService: platform, storageService: storage)),
      ],
      child: MaterialApp(
        title: 'OCP‑V1',
        theme: OcpTheme.darkTheme,
        home: const OcpScaffold(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}