import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../core/textes.dart';
import '../controller.dart';
import '../domain.dart';

class AppairageScreen extends ConsumerWidget {
  const AppairageScreen({super.key});

  static const double _largeurBoutonTactile = 360;
  static const double _hauteurBoutonTactile = 96;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final etat = ref.watch(controleurAppairageProvider);

    return Scaffold(
      appBar: AppBar(title: const Text(Textes.titreAppairage)),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: switch (etat) {
              EtatAppairage.initial => _vueInitiale(context, ref),
              EtatAppairage.enCours => _vueEnCours(),
              EtatAppairage.reussi => _vueReussi(context, ref),
              EtatAppairage.echec => _vueEchec(context, ref),
            },
          ),
        ),
      ),
    );
  }

  Widget _vueInitiale(BuildContext context, WidgetRef ref) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          Textes.consigneAppairage,
          style: Theme.of(context).textTheme.titleLarge,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 48),
        SizedBox(
          width: _largeurBoutonTactile,
          height: _hauteurBoutonTactile,
          child: ElevatedButton(
            onPressed: () => _ouvrirScanner(context, ref),
            child: const Text(
              Textes.boutonScannerQRPC,
              style: TextStyle(fontSize: 22),
            ),
          ),
        ),
      ],
    );
  }

  Widget _vueEnCours() {
    return const Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircularProgressIndicator(),
        SizedBox(height: 24),
        Text(Textes.messageAppairageEnCours),
      ],
    );
  }

  Widget _vueReussi(BuildContext context, WidgetRef ref) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.check_circle, color: Colors.green, size: 96),
        const SizedBox(height: 24),
        Text(
          Textes.messageAppairageReussi,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 48),
        SizedBox(
          width: _largeurBoutonTactile,
          height: _hauteurBoutonTactile,
          child: ElevatedButton(
            onPressed: () {
              ref.read(controleurAppairageProvider.notifier).reinitialiser();
              context.go('/');
            },
            child: const Text(
              Textes.boutonRetourAccueil,
              style: TextStyle(fontSize: 22),
            ),
          ),
        ),
      ],
    );
  }

  Widget _vueEchec(BuildContext context, WidgetRef ref) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.error, color: Colors.red, size: 96),
        const SizedBox(height: 24),
        Text(
          Textes.messageAppairageEchec,
          style: Theme.of(context).textTheme.headlineSmall,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 48),
        SizedBox(
          width: _largeurBoutonTactile,
          height: _hauteurBoutonTactile,
          child: ElevatedButton(
            onPressed: () {
              ref.read(controleurAppairageProvider.notifier).reinitialiser();
            },
            child: const Text(
              Textes.boutonReessayer,
              style: TextStyle(fontSize: 22),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _ouvrirScanner(BuildContext context, WidgetRef ref) async {
    final valeurScannee = await Navigator.of(context).push<String>(
      MaterialPageRoute<String>(builder: (_) => const _PageScanner()),
    );
    if (valeurScannee == null) return;
    if (!context.mounted) return;
    await ref
        .read(controleurAppairageProvider.notifier)
        .traiterScan(valeurScannee);
  }
}

class _PageScanner extends StatefulWidget {
  const _PageScanner();

  @override
  State<_PageScanner> createState() => _PageScannerState();
}

class _PageScannerState extends State<_PageScanner> {
  bool _detectionEffectuee = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(Textes.titreScanner)),
      body: MobileScanner(
        onDetect: (capture) {
          if (_detectionEffectuee) return;
          if (capture.barcodes.isEmpty) return;
          final valeur = capture.barcodes.first.rawValue;
          if (valeur == null) return;
          _detectionEffectuee = true;
          Navigator.of(context).pop(valeur);
        },
      ),
    );
  }
}
