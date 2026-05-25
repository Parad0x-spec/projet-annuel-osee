import 'package:flutter_test/flutter_test.dart';

import 'package:tablette_flutter/core/crypto.dart';
import 'package:tablette_flutter/features/appairage/data.dart';
import 'package:tablette_flutter/features/appairage/domain.dart';

import '../../support/fabrique_enveloppe.dart';

Appairage _appairageAvec(List<int> pcPub) => Appairage(
  pairingId: 'paire-test',
  pcPub: pcPub,
  tabPriv: List<int>.filled(32, 2),
  tabPub: List<int>.filled(32, 3),
  dateAppairage: DateTime.utc(2026, 5, 8),
);

void main() {
  test('creation_patient signe correctement est verifie', () async {
    final paire = await Crypto.genererPaireDeCles();
    final chargeUtile = await fabriquerChargeUtileCreationPatient(
      clePriveePc: paire.privee,
      patientId: 'id-123',
      patientInitiales: 'MD',
      niveauDemande: 3,
    );

    final resultat = await VerificateurEnveloppe.classifierEtVerifier(
      chargeUtile,
      _appairageAvec(paire.publique),
    );

    expect(resultat, isA<EnveloppeCreationPatientVerifiee>());
    final verifiee = resultat as EnveloppeCreationPatientVerifiee;
    expect(verifiee.patientId, 'id-123');
    expect(verifiee.patientInitiales, 'MD');
    expect(verifiee.niveauDemande, 3);
  });

  test('creation_patient sans appairage retourne EnveloppeNonAppairee', () async {
    final paire = await Crypto.genererPaireDeCles();
    final chargeUtile = await fabriquerChargeUtileCreationPatient(
      clePriveePc: paire.privee,
      patientId: 'id-123',
      patientInitiales: 'MD',
      niveauDemande: 3,
    );

    final resultat = await VerificateurEnveloppe.classifierEtVerifier(
      chargeUtile,
      null,
    );

    expect(resultat, isA<EnveloppeNonAppairee>());
  });

  test('creation_patient signe par une autre cle est rejete', () async {
    final paireSignataire = await Crypto.genererPaireDeCles();
    final paireAppairee = await Crypto.genererPaireDeCles();
    final chargeUtile = await fabriquerChargeUtileCreationPatient(
      clePriveePc: paireSignataire.privee,
      patientId: 'id-123',
      patientInitiales: 'MD',
      niveauDemande: 3,
    );

    final resultat = await VerificateurEnveloppe.classifierEtVerifier(
      chargeUtile,
      _appairageAvec(paireAppairee.publique),
    );

    expect(resultat, isA<EnveloppeSignatureInvalide>());
  });

  test('appairage_pc retourne EnveloppeAppairagePc', () async {
    final chargeUtile = fabriquerChargeUtileAppairagePc(
      pairingId: 'paire-test',
      pcPub: List<int>.filled(32, 7),
    );

    final resultat = await VerificateurEnveloppe.classifierEtVerifier(
      chargeUtile,
      null,
    );

    expect(resultat, isA<EnveloppeAppairagePc>());
  });

  test('charge utile illisible retourne EnveloppeIllisible', () async {
    final resultat = await VerificateurEnveloppe.classifierEtVerifier(
      'pas-une-enveloppe-valide',
      null,
    );

    expect(resultat, isA<EnveloppeIllisible>());
  });
}
