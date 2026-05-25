import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../core/qr_envelope.dart';
import '../../../core/textes.dart';
import '../controller.dart';

class ExportSessionScreen extends ConsumerWidget {
  const ExportSessionScreen({super.key});

  static const double _tailleQR = 380;
  static const double _largeurBoutonTactile = 360;
  static const double _hauteurBoutonTactile = 96;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final etatQr = ref.watch(exportSessionProvider);

    return Scaffold(
      appBar: AppBar(title: const Text(Textes.titreExportSession)),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: etatQr.when(
              data: (qr) => _vueQr(context, ref, qr),
              loading: () => const CircularProgressIndicator(),
              error: (erreur, _) => _vueErreur(context, erreur),
            ),
          ),
        ),
      ),
    );
  }

  Widget _vueQr(BuildContext context, WidgetRef ref, EnveloppeQr qr) {
    final etatSession = ref.watch(sessionEnCoursProvider);
    final initiales = etatSession is PatientCharge
        ? etatSession.session.patient.patientInitiales
        : '';

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          Textes.consigneExportSession,
          style: Theme.of(context).textTheme.titleLarge,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: QrImageView(
            data: qr.chargeUtileBase64,
            version: QrVersions.auto,
            size: _tailleQR,
            errorCorrectionLevel: QrErrorCorrectLevel.M,
            backgroundColor: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          Textes.sessionPourInitiales(initiales),
          style: Theme.of(context).textTheme.titleMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        SizedBox(
          width: _largeurBoutonTactile,
          height: _hauteurBoutonTactile,
          child: ElevatedButton(
            onPressed: () {
              ref.read(sessionEnCoursProvider.notifier).reinitialiser();
              context.go('/');
            },
            child: const Text(
              Textes.boutonTermineRetourAccueil,
              style: TextStyle(fontSize: 22),
            ),
          ),
        ),
      ],
    );
  }

  Widget _vueErreur(BuildContext context, Object erreur) {
    final message = erreur is AucunPatientChargeException
        ? Textes.messageAucunPatientCharge
        : Textes.erreurExportSession;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.error, color: Colors.red, size: 96),
        const SizedBox(height: 24),
        Text(
          message,
          style: Theme.of(context).textTheme.headlineSmall,
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
