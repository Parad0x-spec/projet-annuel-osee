import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tablette_flutter/core/crypto.dart';
import 'package:tablette_flutter/core/qr_envelope.dart';
import 'package:tablette_flutter/features/appairage/controller.dart';
import 'package:tablette_flutter/features/appairage/domain.dart';
import 'package:tablette_flutter/features/jeu_emotions/controller.dart';
import 'package:tablette_flutter/features/jeu_emotions/data.dart';
import 'package:tablette_flutter/features/jeu_emotions/domain.dart';

const _patient = PayloadCreationPatient(
  patientId: 'id-123',
  patientInitiales: 'MD',
  niveauDemande: 4,
);

EtatSession _etatCharge() => const PatientCharge(SessionEnCours(_patient));

Future<Appairage> _appairageTest() async {
  final paire = await Crypto.genererPaireDeCles();
  return Appairage(
    pairingId: 'paire-test',
    pcPub: List<int>.filled(32, 9),
    tabPriv: paire.privee,
    tabPub: paire.publique,
    dateAppairage: DateTime.utc(2026, 5, 8),
  );
}

void main() {
  group('construireExportSession', () {
    test('produit un QR signe pour le patient charge', () async {
      final appairage = await _appairageTest();

      final enveloppeQr = await construireExportSession(
        etat: _etatCharge(),
        planches: const <PlancheJouee>[],
        appairage: appairage,
      );

      final enveloppe =
          jsonDecode(enveloppeQr.enveloppeJSON) as Map<String, dynamic>;
      final payload = enveloppe['payload'] as Map<String, dynamic>;
      expect(payload['patient_id'], 'id-123');
      expect(payload['patient_initiales'], 'MD');
      expect(payload['niveau'], 4);
      expect(payload['jeu_type'], 'emotions');
      expect(payload['planches'], isEmpty);

      final octetsASigner = utf8.encode(
        ConstructeurEnveloppe.serialiserPourSignature(
          type: enveloppe['type'] as String,
          version: enveloppe['version'] as int,
          timestamp: enveloppe['timestamp'] as String,
          payload: payload,
        ),
      );
      final signature = base64.decode(enveloppe['signature'] as String);
      expect(
        await Crypto.verifier(appairage.tabPub, octetsASigner, signature),
        isTrue,
      );
    });

    test('leve AucunPatientChargeException si aucun patient charge', () {
      expect(
        () => construireExportSession(
          etat: const AucunPatientCharge(),
          planches: const <PlancheJouee>[],
          appairage: null,
        ),
        throwsA(isA<AucunPatientChargeException>()),
      );
    });

    test('leve AppairageIntrouvableException si la tablette n\'est pas appairee',
        () {
      expect(
        () => construireExportSession(
          etat: _etatCharge(),
          planches: const <PlancheJouee>[],
          appairage: null,
        ),
        throwsA(isA<AppairageIntrouvableException>()),
      );
    });

    test('inclut les planches jouees structurees par emotion dans le payload',
        () async {
      final appairage = await _appairageTest();
      const planche = PlancheJouee(
        numeroPlanche: 2,
        scoreGlobal: 70,
        resultatsParEmotion: <ResultatEmotion>[
          ResultatEmotion(
            emotion: 'joie',
            nbCiblesTotal: 4,
            nbCiblesTrouvees: 3,
            nbFauxPositifs: 1,
            score: 70,
            evaluee: true,
          ),
        ],
      );

      final enveloppeQr = await construireExportSession(
        etat: _etatCharge(),
        planches: const <PlancheJouee>[planche],
        appairage: appairage,
      );

      final enveloppe =
          jsonDecode(enveloppeQr.enveloppeJSON) as Map<String, dynamic>;
      final payload = enveloppe['payload'] as Map<String, dynamic>;
      final planches = payload['planches'] as List<dynamic>;
      expect(planches, hasLength(1));
      final p0 = planches[0] as Map<String, dynamic>;
      expect(p0['numero_planche'], 2);
      expect(p0['score_global'], 70);
      final resultats = p0['resultats_par_emotion'] as List<dynamic>;
      final r0 = resultats.first as Map<String, dynamic>;
      expect(r0['emotion'], 'joie');
      expect(r0['score'], 70);
      expect(r0['evaluee'], isTrue);
    });
  });

  test('exporterSession lit les providers et signe avec la cle d\'appairage',
      () async {
    final appairage = await _appairageTest();
    final container = ProviderContainer(
      overrides: [
        appairageActuelProvider.overrideWith((ref) async => appairage),
      ],
    );
    addTearDown(container.dispose);
    container.read(sessionEnCoursProvider.notifier).charger(_patient);

    final sub = container.listen(exportSessionProvider.future, (_, _) {});
    addTearDown(sub.close);

    final enveloppeQr = await sub.read();
    final enveloppe =
        jsonDecode(enveloppeQr.enveloppeJSON) as Map<String, dynamic>;
    expect(enveloppe['type'], typeSession);
    expect(
      (enveloppe['payload'] as Map<String, dynamic>)['patient_id'],
      'id-123',
    );
  });
}
