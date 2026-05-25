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

class Session {
  const Session();
}
