class PayloadCreationPatient {
  final String patientId;
  final String patientInitiales;
  final int niveauDemande;

  const PayloadCreationPatient({
    required this.patientId,
    required this.patientInitiales,
    required this.niveauDemande,
  });

  void valider() {
    if (patientId.isEmpty) {
      throw const PayloadCreationPatientInvalideException('patient_id vide');
    }
    if (patientInitiales.isEmpty) {
      throw const PayloadCreationPatientInvalideException(
        'patient_initiales vides',
      );
    }
    if (niveauDemande < 1 || niveauDemande > 5) {
      throw PayloadCreationPatientInvalideException(
        'niveau_demande hors plage: $niveauDemande',
      );
    }
  }
}

class PayloadCreationPatientInvalideException implements Exception {
  final String message;
  const PayloadCreationPatientInvalideException(this.message);

  @override
  String toString() => 'PayloadCreationPatientInvalideException: $message';
}

const PayloadCreationPatient patientDemo = PayloadCreationPatient(
  patientId: '00000000-0000-4000-8000-000000000000',
  patientInitiales: 'DEMO',
  niveauDemande: 1,
);

const String jeuTypeEmotions = 'emotions';

const String emotionJoie = 'joie';
const String emotionColere = 'colere';
const String emotionTristesse = 'tristesse';
const String emotionPeur = 'peur';

const List<String> emotionsOrdonnees = <String>[
  emotionJoie,
  emotionColere,
  emotionTristesse,
  emotionPeur,
];

const Set<String> emotionsValides = <String>{
  emotionJoie,
  emotionColere,
  emotionTristesse,
  emotionPeur,
};

const int penaliteFauxPositif = 5;
const int seuilDeuxEtoiles = 41;
const int seuilTroisEtoiles = 76;

class PersonnageAnnotation {
  final int x;
  final int y;
  final int rayon;
  final String emotion;

  const PersonnageAnnotation({
    required this.x,
    required this.y,
    required this.rayon,
    required this.emotion,
  });
}

class Planche {
  final String cheminAsset;
  final int largeur;
  final int hauteur;
  final List<PersonnageAnnotation> personnages;

  const Planche({
    required this.cheminAsset,
    required this.largeur,
    required this.hauteur,
    required this.personnages,
  });

  int nombreCiblesPourEmotion(String emotion) {
    return personnages.where((p) => p.emotion == emotion).length;
  }
}

bool estDansZone(int tapX, int tapY, PersonnageAnnotation personnage) {
  final dx = tapX - personnage.x;
  final dy = tapY - personnage.y;
  return dx * dx + dy * dy <= personnage.rayon * personnage.rayon;
}

class Tap {
  final int timestampMs;
  final int x;
  final int y;
  final String? emotionTouchee;
  final bool correct;

  const Tap({
    required this.timestampMs,
    required this.x,
    required this.y,
    required this.emotionTouchee,
    required this.correct,
  });
}

class ResultatEmotion {
  final String emotion;
  final int nbCiblesTotal;
  final int nbCiblesTrouvees;
  final int nbFauxPositifs;
  final int score;
  final bool evaluee;

  const ResultatEmotion({
    required this.emotion,
    required this.nbCiblesTotal,
    required this.nbCiblesTrouvees,
    required this.nbFauxPositifs,
    required this.score,
    required this.evaluee,
  });

  Map<String, dynamic> versJson() => <String, dynamic>{
    'emotion': emotion,
    'nb_cibles_total': nbCiblesTotal,
    'nb_cibles_trouvees': nbCiblesTrouvees,
    'nb_faux_positifs': nbFauxPositifs,
    'score': score,
    'evaluee': evaluee,
  };
}

class PlancheJouee {
  final int numeroPlanche;
  final List<ResultatEmotion> resultatsParEmotion;
  final int scoreGlobal;

  const PlancheJouee({
    required this.numeroPlanche,
    required this.resultatsParEmotion,
    required this.scoreGlobal,
  });

  Map<String, dynamic> versJson() => <String, dynamic>{
    'numero_planche': numeroPlanche,
    'score_global': scoreGlobal,
    'resultats_par_emotion':
        resultatsParEmotion.map((resultat) => resultat.versJson()).toList(),
  };
}

class Session {
  final String patientId;
  final String patientInitiales;
  final DateTime sessionDate;
  final int niveauDemande;
  final List<PlancheJouee> planchesJouees;

  const Session({
    required this.patientId,
    required this.patientInitiales,
    required this.sessionDate,
    required this.niveauDemande,
    required this.planchesJouees,
  });
}

int calculerScoreGlobal(List<ResultatEmotion> resultatsEvalues) {
  if (resultatsEvalues.isEmpty) {
    return 0;
  }
  final somme = resultatsEvalues.fold<int>(
    0,
    (acc, resultat) => acc + resultat.score,
  );
  return (somme / resultatsEvalues.length).round();
}

int calculerScore({required int T, required int R, required int F}) {
  if (T + R == 0) {
    return 0;
  }
  final brut = (T / (T + R)) * 100.0 - F * penaliteFauxPositif;
  final borne = brut.clamp(0.0, 100.0);
  return borne.round();
}

int calculerEtoiles(int score) {
  if (score >= seuilTroisEtoiles) return 3;
  if (score >= seuilDeuxEtoiles) return 2;
  return 1;
}
