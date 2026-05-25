import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/textes.dart';
import '../../shared_widgets/page_scanner_qr.dart';
import '../appairage/controller.dart';
import '../appairage/data.dart';
import '../appairage/domain.dart';
import 'data.dart';
import 'domain.dart';

sealed class EtatSession {
  const EtatSession();
}

class AucunPatientCharge extends EtatSession {
  const AucunPatientCharge();
}

class PatientCharge extends EtatSession {
  final SessionEnCours session;
  const PatientCharge(this.session);
}

class ControleurSession extends Notifier<EtatSession> {
  @override
  EtatSession build() => const AucunPatientCharge();

  void charger(PayloadCreationPatient patient) {
    state = PatientCharge(SessionEnCours(patient));
  }

  void reinitialiser() {
    state = const AucunPatientCharge();
  }
}

final sessionEnCoursProvider =
    NotifierProvider<ControleurSession, EtatSession>(ControleurSession.new);

typedef OuvrirScanner = Future<String?> Function(BuildContext context);

final scannerQrProvider = Provider<OuvrirScanner>((ref) {
  return (context) => Navigator.of(context).push<String>(
    MaterialPageRoute<String>(builder: (_) => const PageScannerQr()),
  );
});

sealed class ResultatRoutage {
  const ResultatRoutage();
}

class RoutageAppairage extends ResultatRoutage {
  const RoutageAppairage();
}

class RoutageConfirmationPatient extends ResultatRoutage {
  const RoutageConfirmationPatient();
}

class RoutageErreur extends ResultatRoutage {
  final String message;
  const RoutageErreur(this.message);
}

class ControleurReceptionQr extends Notifier<void> {
  @override
  void build() {}

  Future<ResultatRoutage> traiter(String chargeUtileBase64) async {
    final appairage = await ref.read(appairageActuelProvider.future);
    final resultat = await VerificateurEnveloppe.classifierEtVerifier(
      chargeUtileBase64,
      appairage,
    );

    switch (resultat) {
      case EnveloppeAppairagePc():
        await ref
            .read(controleurAppairageProvider.notifier)
            .traiterScan(chargeUtileBase64);
        return const RoutageAppairage();
      case EnveloppeNonAppairee():
        return const RoutageErreur(Textes.erreurTabletteNonAppairee);
      case EnveloppeSignatureInvalide():
        return const RoutageErreur(Textes.erreurPatientNonVerifie);
      case EnveloppeIllisible():
        return const RoutageErreur(Textes.erreurQrIllisible);
      case EnveloppeCreationPatientVerifiee(
        :final patientId,
        :final patientInitiales,
        :final niveauDemande,
      ):
        final patient = PayloadCreationPatient(
          patientId: patientId,
          patientInitiales: patientInitiales,
          niveauDemande: niveauDemande,
        );
        try {
          patient.valider();
        } on PayloadCreationPatientInvalideException {
          return const RoutageErreur(Textes.erreurDonneesPatientInvalides);
        }
        ref.read(sessionEnCoursProvider.notifier).charger(patient);
        return const RoutageConfirmationPatient();
    }
  }
}

final controleurReceptionQrProvider =
    NotifierProvider<ControleurReceptionQr, void>(ControleurReceptionQr.new);
