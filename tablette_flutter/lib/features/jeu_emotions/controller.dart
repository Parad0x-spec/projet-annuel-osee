import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/qr_envelope.dart';
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
    ref.read(partiesSeanceProvider.notifier).vider();
    state = const AucunPatientCharge();
  }
}

final sessionEnCoursProvider =
    NotifierProvider<ControleurSession, EtatSession>(ControleurSession.new);

class ControleurPartiesSeance extends Notifier<List<Partie>> {
  @override
  List<Partie> build() => const <Partie>[];

  void ajouter(Partie partie) {
    state = <Partie>[...state, partie];
  }

  void vider() {
    state = const <Partie>[];
  }
}

final partiesSeanceProvider =
    NotifierProvider<ControleurPartiesSeance, List<Partie>>(
      ControleurPartiesSeance.new,
    );

class MoteurPartie {
  final Planche planche;
  final int numeroPlanche;
  final String emotionCible;
  final int Function() horlogeMs;

  final Set<int> _indicesTrouves = <int>{};
  final List<Tap> _taps = <Tap>[];
  int _nbFauxPositifs = 0;
  late final int _tempsDebutMs;
  late final int _nbCiblesTotal;

  MoteurPartie({
    required this.planche,
    required this.numeroPlanche,
    required this.emotionCible,
    required this.horlogeMs,
  }) {
    _tempsDebutMs = horlogeMs();
    _nbCiblesTotal = planche.nombreCiblesPourEmotion(emotionCible);
  }

  int get nbCiblesTotal => _nbCiblesTotal;
  int get nbCiblesTrouvees => _indicesTrouves.length;
  int get nbFauxPositifs => _nbFauxPositifs;
  Set<int> get indicesTrouves => Set.unmodifiable(_indicesTrouves);
  List<Tap> get taps => List.unmodifiable(_taps);
  bool get toutesCiblesTrouvees =>
      _nbCiblesTotal > 0 && _indicesTrouves.length == _nbCiblesTotal;

  ResultatTap taper(int tapX, int tapY) {
    final maintenant = horlogeMs();
    final tempsMs = maintenant - _tempsDebutMs;
    int? indexTouche;
    for (var i = 0; i < planche.personnages.length; i++) {
      if (estDansZone(tapX, tapY, planche.personnages[i])) {
        indexTouche = i;
        break;
      }
    }

    if (indexTouche == null) {
      _taps.add(
        Tap(
          timestampMs: tempsMs,
          x: tapX,
          y: tapY,
          emotionTouchee: null,
          correct: false,
        ),
      );
      return const ResultatTap.aucun();
    }

    final perso = planche.personnages[indexTouche];
    if (perso.emotion == emotionCible) {
      final dejaTrouvee = _indicesTrouves.contains(indexTouche);
      if (!dejaTrouvee) {
        _indicesTrouves.add(indexTouche);
      }
      _taps.add(
        Tap(
          timestampMs: tempsMs,
          x: tapX,
          y: tapY,
          emotionTouchee: perso.emotion,
          correct: true,
        ),
      );
      return ResultatTap.cible(indexPersonnage: indexTouche, dejaTrouvee: dejaTrouvee);
    } else {
      _nbFauxPositifs += 1;
      _taps.add(
        Tap(
          timestampMs: tempsMs,
          x: tapX,
          y: tapY,
          emotionTouchee: perso.emotion,
          correct: false,
        ),
      );
      return ResultatTap.fauxPositif(indexPersonnage: indexTouche);
    }
  }

  Partie terminer(ModeFin modeFin) {
    final tempsTotalMs = horlogeMs() - _tempsDebutMs;
    final nbTrouvees = _indicesTrouves.length;
    final nbRatees = _nbCiblesTotal - nbTrouvees;
    final score = calculerScore(
      T: nbTrouvees,
      R: nbRatees,
      F: _nbFauxPositifs,
    );
    return Partie(
      emotionCible: emotionCible,
      numeroPlanche: numeroPlanche,
      nbCiblesTotal: _nbCiblesTotal,
      nbCiblesTrouvees: nbTrouvees,
      nbFauxPositifs: _nbFauxPositifs,
      nbCiblesRatees: nbRatees,
      tempsTotalMs: tempsTotalMs,
      modeFin: modeFin,
      score: score,
    );
  }
}

sealed class ResultatTap {
  const ResultatTap();
  const factory ResultatTap.aucun() = ResultatAucun;
  const factory ResultatTap.cible({
    required int indexPersonnage,
    required bool dejaTrouvee,
  }) = ResultatCible;
  const factory ResultatTap.fauxPositif({required int indexPersonnage}) =
      ResultatFauxPositif;
}

class ResultatAucun extends ResultatTap {
  const ResultatAucun();
}

class ResultatCible extends ResultatTap {
  final int indexPersonnage;
  final bool dejaTrouvee;
  const ResultatCible({
    required this.indexPersonnage,
    required this.dejaTrouvee,
  });
}

class ResultatFauxPositif extends ResultatTap {
  final int indexPersonnage;
  const ResultatFauxPositif({required this.indexPersonnage});
}

sealed class EtatPartie {
  const EtatPartie();
}

class AucunePartie extends EtatPartie {
  const AucunePartie();
}

class PartieEnCours extends EtatPartie {
  final MoteurPartie moteur;
  const PartieEnCours(this.moteur);
}

class ControleurPartie extends Notifier<EtatPartie> {
  DateTime Function() horloge = DateTime.now;

  @override
  EtatPartie build() => const AucunePartie();

  Future<void> demarrerPartie({
    required int numeroPlanche,
    required String emotion,
  }) async {
    final planche = await chargerPlanche(numeroPlanche);
    state = PartieEnCours(
      MoteurPartie(
        planche: planche,
        numeroPlanche: numeroPlanche,
        emotionCible: emotion,
        horlogeMs: () => horloge().millisecondsSinceEpoch,
      ),
    );
  }

  ResultatTap taper(int tapX, int tapY) {
    final etatCourant = state;
    if (etatCourant is! PartieEnCours) {
      throw const PartieNonDemarreeException();
    }
    final resultat = etatCourant.moteur.taper(tapX, tapY);
    state = PartieEnCours(etatCourant.moteur);
    return resultat;
  }

  Partie terminer(ModeFin modeFin) {
    final etatCourant = state;
    if (etatCourant is! PartieEnCours) {
      throw const PartieNonDemarreeException();
    }
    final partie = etatCourant.moteur.terminer(modeFin);
    ref.read(partiesSeanceProvider.notifier).ajouter(partie);
    state = const AucunePartie();
    return partie;
  }
}

final controleurPartieProvider =
    NotifierProvider<ControleurPartie, EtatPartie>(ControleurPartie.new);

class PartieNonDemarreeException implements Exception {
  const PartieNonDemarreeException();
  @override
  String toString() => 'PartieNonDemarreeException';
}

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

class AucunPatientChargeException implements Exception {
  const AucunPatientChargeException();

  @override
  String toString() => 'AucunPatientChargeException';
}

class AppairageIntrouvableException implements Exception {
  const AppairageIntrouvableException();

  @override
  String toString() => 'AppairageIntrouvableException';
}

Future<EnveloppeQr> construireExportSession({
  required EtatSession etat,
  required List<Partie> parties,
  required Appairage? appairage,
  DateTime? horodatage,
}) {
  if (etat is! PatientCharge) {
    throw const AucunPatientChargeException();
  }
  if (appairage == null) {
    throw const AppairageIntrouvableException();
  }

  final patient = etat.session.patient;
  final maintenant = horodatage ?? DateTime.now().toUtc();
  final session = Session(
    patientId: patient.patientId,
    patientInitiales: patient.patientInitiales,
    sessionDate: maintenant,
    niveauDemande: patient.niveauDemande,
    parties: parties,
  );

  return construireQrSession(
    session: session,
    tabPriv: appairage.tabPriv,
    horodatage: maintenant,
  );
}

Future<EnveloppeQr> exporterSession(Ref ref, {DateTime? horodatage}) async {
  final appairage = await ref.read(appairageActuelProvider.future);
  final etat = ref.read(sessionEnCoursProvider);
  final parties = ref.read(partiesSeanceProvider);
  return construireExportSession(
    etat: etat,
    parties: parties,
    appairage: appairage,
    horodatage: horodatage,
  );
}

final exportSessionProvider = FutureProvider.autoDispose<EnveloppeQr>((ref) {
  return exporterSession(ref);
});
