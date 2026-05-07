import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/router.dart';
import 'core/textes.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations(<DeviceOrientation>[
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  runApp(const ProviderScope(child: ApplicationTablette()));
}

class ApplicationTablette extends StatelessWidget {
  const ApplicationTablette({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: Textes.titreApplication,
      debugShowCheckedModeBanner: false,
      routerConfig: routeurApplication,
    );
  }
}
