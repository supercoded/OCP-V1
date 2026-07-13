import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ocp_flutter_core/ocp_flutter_core.dart';
import 'services/service_locator.dart';
import 'providers/connection_provider.dart';
import 'providers/sonar_provider.dart';
import 'providers/messaging_provider.dart';
import 'providers/network_provider.dart';
import 'providers/spectrum_provider.dart';
import 'widgets/ocp_scaffold.dart';

class OcpApp extends StatelessWidget {
  const OcpApp({super.key});

  @override
  Widget build(BuildContext context) {
    final platform = ServiceLocator.platform;

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ConnectionProvider(platformService: platform)),
        ChangeNotifierProvider(create: (_) => SonarProvider(platformService: platform)),
        ChangeNotifierProvider(create: (_) => MessagingProvider(platformService: platform)),
        ChangeNotifierProvider(create: (_) => NetworkProvider(platformService: platform)),
        ChangeNotifierProvider(create: (_) => SpectrumProvider(platformService: platform)),
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