import 'package:flutter/material.dart';

import '../core/textes.dart';

class AccueilScreen extends StatelessWidget {
  const AccueilScreen({super.key});

  static const double _hauteurBoutonTactile = 96;
  static const double _largeurBoutonTactile = 360;
  static const double _espacementEntreBoutons = 24;
  static const double _espacementTitreBoutons = 64;

  void _afficherSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Widget _construireBouton(
    BuildContext context,
    String libelle,
  ) {
    return SizedBox(
      width: _largeurBoutonTactile,
      height: _hauteurBoutonTactile,
      child: ElevatedButton(
        onPressed: () => _afficherSnackBar(context, libelle),
        child: Text(
          libelle,
          style: Theme.of(context).textTheme.titleLarge,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeTextes = Theme.of(context).textTheme;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                Textes.titreAccueil,
                style: themeTextes.displayMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: _espacementTitreBoutons),
              _construireBouton(context, Textes.boutonNouveauPatient),
              const SizedBox(height: _espacementEntreBoutons),
              _construireBouton(context, Textes.boutonPatientExistant),
              const SizedBox(height: _espacementEntreBoutons),
              _construireBouton(context, Textes.boutonParametres),
            ],
          ),
        ),
      ),
    );
  }
}
