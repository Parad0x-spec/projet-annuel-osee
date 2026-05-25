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

const String jeuTypeEmotions = 'emotions';

class Session {
  final String patientId;
  final String patientInitiales;
  final DateTime sessionDate;
  final String jeuType;
  final int niveau;
  final List<Manche> manches;

  const Session({
    required this.patientId,
    required this.patientInitiales,
    required this.sessionDate,
    required this.jeuType,
    required this.niveau,
    required this.manches,
  });
}

class Manche {
  final String emotionCible;
  final int nombreVisagesPlanche;
  final int nombreCiblesPresentes;
  final int nombreCiblesTrouvees;
  final int nombreFauxPositifs;
  final int nombreCiblesRatees;
  final int tempsTotalMs;
  final bool abandonnee;
  final List<Tap> taps;

  const Manche({
    required this.emotionCible,
    required this.nombreVisagesPlanche,
    required this.nombreCiblesPresentes,
    required this.nombreCiblesTrouvees,
    required this.nombreFauxPositifs,
    required this.nombreCiblesRatees,
    required this.tempsTotalMs,
    required this.abandonnee,
    required this.taps,
  });

  Map<String, dynamic> versJson() => <String, dynamic>{
    'emotion_cible': emotionCible,
    'nombre_visages_planche': nombreVisagesPlanche,
    'nombre_cibles_presentes': nombreCiblesPresentes,
    'nombre_cibles_trouvees': nombreCiblesTrouvees,
    'nombre_faux_positifs': nombreFauxPositifs,
    'nombre_cibles_ratees': nombreCiblesRatees,
    'temps_total_ms': tempsTotalMs,
    'abandonnee': abandonnee,
    'taps': taps.map((tap) => tap.versJson()).toList(),
  };
}

class Tap {
  final int tempsMs;
  final double x;
  final double y;
  final String resultat;

  const Tap({
    required this.tempsMs,
    required this.x,
    required this.y,
    required this.resultat,
  });

  Map<String, dynamic> versJson() => <String, dynamic>{
    'temps_ms': tempsMs,
    'x': x,
    'y': y,
    'resultat': resultat,
  };
}
