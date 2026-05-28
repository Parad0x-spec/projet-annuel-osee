import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/textes.dart';
import '../controller.dart';

class ConfirmationPatientScreen extends ConsumerWidget {
  const ConfirmationPatientScreen({super.key});

  static const double _largeurBoutonTactile = 360;
  static const double _hauteurBoutonTactile = 96;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final etat = ref.watch(sessionEnCoursProvider);

    return Scaffold(
      appBar: AppBar(title: const Text(Textes.titreConfirmationPatient)),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: switch (etat) {
              AucunPatientCharge() => _vueAucunPatient(context),
              PatientCharge(:final session) => _vuePatientCharge(
                context,
                ref,
                session.patient.patientInitiales,
              ),
            },
          ),
        ),
      ),
    );
  }

  Widget _vuePatientCharge(
    BuildContext context,
    WidgetRef ref,
    String initiales,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.check_circle, color: Colors.green, size: 96),
        const SizedBox(height: 24),
        Text(
          Textes.confirmationPatientPret(initiales),
          style: Theme.of(context).textTheme.headlineSmall,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 48),
        SizedBox(
          width: _largeurBoutonTactile,
          height: _hauteurBoutonTactile,
          child: ElevatedButton(
            onPressed: () => context.go('/configuration-partie'),
            child: const Text(
              Textes.boutonCommencerJeu,
              style: TextStyle(fontSize: 22),
            ),
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: _largeurBoutonTactile,
          height: _hauteurBoutonTactile,
          child: OutlinedButton(
            onPressed: () {
              ref.read(sessionEnCoursProvider.notifier).reinitialiser();
              context.go('/');
            },
            child: const Text(
              Textes.boutonAnnuler,
              style: TextStyle(fontSize: 22),
            ),
          ),
        ),
      ],
    );
  }

  Widget _vueAucunPatient(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          Textes.messageAucunPatientCharge,
          style: Theme.of(context).textTheme.titleLarge,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 48),
        SizedBox(
          width: _largeurBoutonTactile,
          height: _hauteurBoutonTactile,
          child: ElevatedButton(
            onPressed: () => context.go('/'),
            child: const Text(
              Textes.boutonRetourAccueil,
              style: TextStyle(fontSize: 22),
            ),
          ),
        ),
      ],
    );
  }
}
