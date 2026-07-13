import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ocp_flutter_core/ocp_flutter_core.dart';
import 'providers/connection_provider.dart';
import 'providers/sonar_provider.dart';
import 'widgets/ocp_scaffold.dart';

class OcpApp extends StatelessWidget {
  const OcpApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ConnectionProvider()),
        ChangeNotifierProvider(create: (_) => SonarProvider()),
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
