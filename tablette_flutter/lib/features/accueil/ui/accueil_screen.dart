import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/textes.dart';
import '../../jeu_emotions/controller.dart';

class AccueilScreen extends ConsumerWidget {
  const AccueilScreen({super.key});

  static const double _hauteurBoutonTactile = 96;
  static const double _largeurBoutonTactile = 360;
  static const double _espacementEntreBoutons = 24;
  static const double _espacementTitreBoutons = 64;

  void _afficherSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 3)),
    );
  }

  Future<void> _ouvrirNouveauPatient(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final ouvrirScanner = ref.read(scannerQrProvider);
    final valeurScannee = await ouvrirScanner(context);
    if (valeurScannee == null) return;
    if (!context.mounted) return;

    final routage = await ref
        .read(controleurReceptionQrProvider.notifier)
        .traiter(valeurScannee);
    if (!context.mounted) return;

    switch (routage) {
      case RoutageAppairage():
        context.go('/appairage');
      case RoutageConfirmationPatient():
        context.go('/confirmation-patient');
      case RoutageErreur(:final message):
        _afficherSnackBar(context, message);
    }
  }

  void _lancerModeDemo(BuildContext context, WidgetRef ref) {
    ref.read(sessionEnCoursProvider.notifier).chargerDemo();
    context.go('/choix-planche');
  }

  Widget _construireBoutonTactile({
    required BuildContext context,
    required String libelle,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: _largeurBoutonTactile,
      height: _hauteurBoutonTactile,
      child: ElevatedButton(
        onPressed: onPressed,
        child: Text(libelle, style: Theme.of(context).textTheme.titleLarge),
      ),
    );
  }

  Widget _construireBoutonDemo({
    required BuildContext context,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: _largeurBoutonTactile,
      height: _hauteurBoutonTactile,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: const Icon(Icons.science_outlined, color: Colors.deepOrange),
        label: Text(
          Textes.boutonModeDemo,
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(color: Colors.deepOrange),
        ),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Colors.deepOrange, width: 2),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeTextes = Theme.of(context).textTheme;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  Textes.titreAccueil,
                  style: themeTextes.displayMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: _espacementTitreBoutons),
                _construireBoutonTactile(
                  context: context,
                  libelle: Textes.boutonNouveauPatient,
                  onPressed: () => _ouvrirNouveauPatient(context, ref),
                ),
                const SizedBox(height: _espacementEntreBoutons),
                _construireBoutonTactile(
                  context: context,
                  libelle: Textes.boutonPatientExistant,
                  onPressed: () =>
                      _afficherSnackBar(context, Textes.boutonPatientExistant),
                ),
                const SizedBox(height: _espacementEntreBoutons),
                _construireBoutonTactile(
                  context: context,
                  libelle: Textes.boutonParametres,
                  onPressed: () =>
                      _afficherSnackBar(context, Textes.boutonParametres),
                ),
                const SizedBox(height: _espacementEntreBoutons),
                _construireBoutonDemo(
                  context: context,
                  onPressed: () => _lancerModeDemo(context, ref),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
