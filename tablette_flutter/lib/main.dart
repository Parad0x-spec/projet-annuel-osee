import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/router.dart';
import 'core/stockage.dart';
import 'core/textes.dart';
import 'features/appairage/controller.dart';
import 'features/jeu_emotions/controller.dart';
import 'features/jeu_emotions/data.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations(<DeviceOrientation>[
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  final stockage = await Stockage.ouvrir();
  final contexteRestaure = await DepotContexteSession(stockage).lire();

  runApp(
    ProviderScope(
      overrides: [
        stockageProvider.overrideWith((ref) async {
          ref.onDispose(() async => stockage.fermer());
          return stockage;
        }),
        if (contexteRestaure != null)
          contexteSessionInitialProvider.overrideWithValue(contexteRestaure),
      ],
      child: ApplicationTablette(sessionRestauree: contexteRestaure != null),
    ),
  );
}

class ApplicationTablette extends StatelessWidget {
  final bool sessionRestauree;

  const ApplicationTablette({super.key, this.sessionRestauree = false});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: Textes.titreApplication,
      debugShowCheckedModeBanner: false,
      routerConfig: creerRouteurApplication(
        initialLocation: sessionRestauree ? '/configuration-partie' : '/',
      ),
    );
  }
}
