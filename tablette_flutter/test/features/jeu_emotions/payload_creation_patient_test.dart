import 'package:flutter_test/flutter_test.dart';

import 'package:tablette_flutter/features/jeu_emotions/domain.dart';

void main() {
  group('PayloadCreationPatient.valider', () {
    test('cas nominal ne leve aucune exception', () {
      const payload = PayloadCreationPatient(
        patientId: 'id-123',
        patientInitiales: 'MD',
        niveauDemande: 3,
      );
      expect(payload.valider, returnsNormally);
    });

    test('niveau inferieur a 1 leve PayloadCreationPatientInvalideException', () {
      const payload = PayloadCreationPatient(
        patientId: 'id-123',
        patientInitiales: 'MD',
        niveauDemande: 0,
      );
      expect(
        payload.valider,
        throwsA(isA<PayloadCreationPatientInvalideException>()),
      );
    });

    test('niveau superieur a 5 leve PayloadCreationPatientInvalideException', () {
      const payload = PayloadCreationPatient(
        patientId: 'id-123',
        patientInitiales: 'MD',
        niveauDemande: 6,
      );
      expect(
        payload.valider,
        throwsA(isA<PayloadCreationPatientInvalideException>()),
      );
    });

    test('niveaux limites 1 et 5 sont acceptes', () {
      const niveauMin = PayloadCreationPatient(
        patientId: 'id-123',
        patientInitiales: 'MD',
        niveauDemande: 1,
      );
      const niveauMax = PayloadCreationPatient(
        patientId: 'id-123',
        patientInitiales: 'MD',
        niveauDemande: 5,
      );
      expect(niveauMin.valider, returnsNormally);
      expect(niveauMax.valider, returnsNormally);
    });

    test('patientId vide leve PayloadCreationPatientInvalideException', () {
      const payload = PayloadCreationPatient(
        patientId: '',
        patientInitiales: 'MD',
        niveauDemande: 3,
      );
      expect(
        payload.valider,
        throwsA(isA<PayloadCreationPatientInvalideException>()),
      );
    });

    test('initiales vides leve PayloadCreationPatientInvalideException', () {
      const payload = PayloadCreationPatient(
        patientId: 'id-123',
        patientInitiales: '',
        niveauDemande: 3,
      );
      expect(
        payload.valider,
        throwsA(isA<PayloadCreationPatientInvalideException>()),
      );
    });
  });
}
