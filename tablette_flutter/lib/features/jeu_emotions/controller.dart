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

final contexteSessionInitialProvider = Provider<SessionEnCours?>((ref) => null);

final depotContexteSessionProvider =
    FutureProvider<DepotContexteSession>((ref) async {
  final stockage = await ref.watch(stockageProvider.future);
  return DepotContexteSession(stockage);
});

class ControleurSession extends Notifier<EtatSession> {
  @override
  EtatSession build() {
    final contexteInitial = ref.watch(contexteSessionInitialProvider);
    if (contexteInitial == null) {
      return const AucunPatientCharge();
    }
    return PatientCharge(contexteInitial);
  }

  void charger(PayloadCreationPatient patient) {
    state = PatientCharge(SessionEnCours(patient));
    _persisterContexte(patient, estDemo: false);
  }

  void chargerDemo() {
    state = PatientCharge(SessionEnCours(patientDemo, estDemo: true));
    _persisterContexte(patientDemo, estDemo: true);
  }

  void reinitialiser() {
    ref.read(planchesSeanceProvider.notifier).vider();
    state = const AucunPatientCharge();
    _effacerContexte();
  }

  Future<void> _persisterContexte(
    PayloadCreationPatient patient, {
    required bool estDemo,
  }) async {
    try {
      final depot = await ref.read(depotContexteSessionProvider.future);
      await depot.enregistrer(patient: patient, estDemo: estDemo);
    } catch (_) {}
  }

  Future<void> _effacerContexte() async {
    try {
      final depot = await ref.read(depotContexteSessionProvider.future);
      await depot.effacer();
    } catch (_) {}
  }
}

final sessionEnCoursProvider =
    NotifierProvider<ControleurSession, EtatSession>(ControleurSession.new);

class ControleurPlanchesSeance extends Notifier<List<PlancheJouee>> {
  @override
  List<PlancheJouee> build() => const <PlancheJouee>[];

  void ajouter(PlancheJouee planche) {
    state = <PlancheJouee>[...state, planche];
  }

  void vider() {
    state = const <PlancheJouee>[];
  }
}

final planchesSeanceProvider =
    NotifierProvider<ControleurPlanchesSeance, List<PlancheJouee>>(
      ControleurPlanchesSeance.new,
    );

class MoteurPlanche {
  final Planche planche;
  final int numeroPlanche;
  final int Function() horlogeMs;

  final Map<String, Set<int>> _trouvesParEmotion = <String, Set<int>>{};
  final Map<String, int> _fauxPositifsParEmotion = <String, int>{};
  final Map<String, Set<int>> _indicesFauxPositifsParEmotion =
      <String, Set<int>>{};
  final List<Tap> _taps = <Tap>[];
  late final int _tempsDebutMs;
  String? _emotionCible;

  MoteurPlanche({
    required this.planche,
    required this.numeroPlanche,
    required this.horlogeMs,
  }) {
    _tempsDebutMs = horlogeMs();
    for (final emotion in emotionsOrdonnees) {
      _trouvesParEmotion[emotion] = <int>{};
      _fauxPositifsParEmotion[emotion] = 0;
      _indicesFauxPositifsParEmotion[emotion] = <int>{};
    }
  }

  String? get emotionCible => _emotionCible;
  List<Tap> get taps => List.unmodifiable(_taps);

  int nbCiblesTotal(String emotion) =>
      planche.nombreCiblesPourEmotion(emotion);
  int nbCiblesTrouvees(String emotion) =>
      _trouvesParEmotion[emotion]?.length ?? 0;
  int nbFauxPositifs(String emotion) => _fauxPositifsParEmotion[emotion] ?? 0;
  Set<int> indicesTrouves(String emotion) =>
      Set.unmodifiable(_trouvesParEmotion[emotion] ?? const <int>{});
  Set<int> indicesFauxPositifs(String emotion) =>
      Set.unmodifiable(_indicesFauxPositifsParEmotion[emotion] ?? const <int>{});

  void changerEmotionCible(String emotion) {
    _emotionCible = emotion;
  }

  bool resteDesCibles() {
    for (final emotion in emotionsOrdonnees) {
      if (nbCiblesTrouvees(emotion) < nbCiblesTotal(emotion)) {
        return true;
      }
    }
    return false;
  }

  bool toutesEmotionsCompletes() => !resteDesCibles();

  ResultatTap taper(int tapX, int tapY) {
    final emotionCourante = _emotionCible;
    if (emotionCourante == null) {
      return const ResultatTap.aucun();
    }

    final tempsMs = horlogeMs() - _tempsDebutMs;
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
    if (perso.emotion == emotionCourante) {
      final trouves = _trouvesParEmotion[emotionCourante]!;
      final dejaTrouvee = trouves.contains(indexTouche);
      if (!dejaTrouvee) {
        trouves.add(indexTouche);
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
      return ResultatTap.cible(
        indexPersonnage: indexTouche,
        dejaTrouvee: dejaTrouvee,
      );
    } else {
      _fauxPositifsParEmotion[emotionCourante] =
          (_fauxPositifsParEmotion[emotionCourante] ?? 0) + 1;
      _indicesFauxPositifsParEmotion[emotionCourante]!.add(indexTouche);
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

  ResultatEmotion resultatPourEmotion(
    String emotion, {
    required bool evaluee,
  }) {
    final total = nbCiblesTotal(emotion);
    final trouvees = nbCiblesTrouvees(emotion);
    final fauxPositifs = nbFauxPositifs(emotion);
    final score = calculerScore(
      T: trouvees,
      R: total - trouvees,
      F: fauxPositifs,
    );
    return ResultatEmotion(
      emotion: emotion,
      nbCiblesTotal: total,
      nbCiblesTrouvees: trouvees,
      nbFauxPositifs: fauxPositifs,
      score: score,
      evaluee: evaluee,
    );
  }

  PlancheJouee terminerPlanche(List<String> emotionsRetenues) {
    final retenues = emotionsRetenues.toSet();
    final resultats = emotionsOrdonnees
        .map((emotion) =>
            resultatPourEmotion(emotion, evaluee: retenues.contains(emotion)))
        .toList();
    final evalues = resultats.where((resultat) => resultat.evaluee).toList();
    return PlancheJouee(
      numeroPlanche: numeroPlanche,
      resultatsParEmotion: resultats,
      scoreGlobal: calculerScoreGlobal(evalues),
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

sealed class EtatPlanche {
  const EtatPlanche();
}

class AucunePlanche extends EtatPlanche {
  const AucunePlanche();
}

class PlancheEnCours extends EtatPlanche {
  final MoteurPlanche moteur;
  const PlancheEnCours(this.moteur);
}

class ControleurPlanche extends Notifier<EtatPlanche> {
  DateTime Function() horloge = DateTime.now;

  @override
  EtatPlanche build() => const AucunePlanche();

  Future<void> demarrerPlanche(int numeroPlanche) async {
    final planche = await chargerPlanche(numeroPlanche);
    chargerMoteur(
      MoteurPlanche(
        planche: planche,
        numeroPlanche: numeroPlanche,
        horlogeMs: () => horloge().millisecondsSinceEpoch,
      ),
    );
  }

  void chargerMoteur(MoteurPlanche moteur) {
    state = PlancheEnCours(moteur);
  }

  void changerEmotionCible(String emotion) {
    final etatCourant = state;
    if (etatCourant is! PlancheEnCours) {
      throw const PlancheNonDemarreeException();
    }
    etatCourant.moteur.changerEmotionCible(emotion);
    state = PlancheEnCours(etatCourant.moteur);
  }

  ResultatTap taper(int tapX, int tapY) {
    final etatCourant = state;
    if (etatCourant is! PlancheEnCours) {
      throw const PlancheNonDemarreeException();
    }
    final resultat = etatCourant.moteur.taper(tapX, tapY);
    state = PlancheEnCours(etatCourant.moteur);
    return resultat;
  }

  PlancheJouee terminerPlanche(List<String> emotionsRetenues) {
    final etatCourant = state;
    if (etatCourant is! PlancheEnCours) {
      throw const PlancheNonDemarreeException();
    }
    final plancheJouee =
        etatCourant.moteur.terminerPlanche(emotionsRetenues);
    ref.read(planchesSeanceProvider.notifier).ajouter(plancheJouee);
    state = const AucunePlanche();
    return plancheJouee;
  }

  void abandonnerPlanche() {
    state = const AucunePlanche();
  }
}

final controleurPlancheProvider =
    NotifierProvider<ControleurPlanche, EtatPlanche>(ControleurPlanche.new);

class PlancheNonDemarreeException implements Exception {
  const PlancheNonDemarreeException();
  @override
  String toString() => 'PlancheNonDemarreeException';
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
  required List<PlancheJouee> planches,
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
    planchesJouees: planches,
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
  final planches = ref.read(planchesSeanceProvider);
  return construireExportSession(
    etat: etat,
    planches: planches,
    appairage: appairage,
    horodatage: horodatage,
  );
}

final exportSessionProvider = FutureProvider.autoDispose<EnveloppeQr>((ref) {
  return exporterSession(ref);
});
