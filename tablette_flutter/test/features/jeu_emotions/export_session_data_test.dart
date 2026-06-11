import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:tablette_flutter/core/crypto.dart';
import 'package:tablette_flutter/core/qr_envelope.dart';
import 'package:tablette_flutter/features/appairage/domain.dart';
import 'package:tablette_flutter/features/jeu_emotions/data.dart';
import 'package:tablette_flutter/features/jeu_emotions/domain.dart';

Session _sessionTest() => Session(
  patientId: 'id-123',
  patientInitiales: 'MD',
  sessionDate: DateTime.utc(2026, 5, 25, 10, 0, 0),
  niveauDemande: 3,
  planchesJouees: const <PlancheJouee>[],
);

void main() {
  group('construireQrSession', () {
    test('produit une enveloppe session version 3 structurellement complete',
        () async {
      final paire = await Crypto.genererPaireDeCles();

      final enveloppeQr = await construireQrSession(
        session: _sessionTest(),
        tabPriv: paire.privee,
        horodatage: DateTime.utc(2026, 5, 25, 10, 0, 5),
      );

      final enveloppe =
          jsonDecode(enveloppeQr.enveloppeJSON) as Map<String, dynamic>;
      expect(enveloppe['type'], typeSession);
      expect(enveloppe['version'], versionProtocole);
      expect(enveloppe['timestamp'], '2026-05-25T10:00:05.000Z');

      final payload = enveloppe['payload'] as Map<String, dynamic>;
      expect(payload.keys.toList(), <String>[
        'patient_id',
        'patient_initiales',
        'session_date',
        'jeu_type',
        'niveau',
        'planches',
      ]);
      expect(payload['patient_id'], 'id-123');
      expect(payload['patient_initiales'], 'MD');
      expect(payload['session_date'], '2026-05-25T10:00:00.000Z');
      expect(payload['jeu_type'], 'emotions');
      expect(payload['niveau'], 3);
      expect(payload['planches'], isEmpty);
    });

    test('respecte l\'ordre canonique des cles dans le JSON serialise',
        () async {
      final paire = await Crypto.genererPaireDeCles();

      final enveloppeQr = await construireQrSession(
        session: _sessionTest(),
        tabPriv: paire.privee,
        horodatage: DateTime.utc(2026, 5, 25, 10, 0, 5),
      );

      const payloadAttendu =
          '"payload":{"patient_id":"id-123","patient_initiales":"MD",'
          '"session_date":"2026-05-25T10:00:00.000Z","jeu_type":"emotions",'
          '"niveau":3,"planches":[]}';
      expect(enveloppeQr.enveloppeJSON, contains(payloadAttendu));
    });

    test('produit une signature verifiable avec tab_pub', () async {
      final paire = await Crypto.genererPaireDeCles();

      final enveloppeQr = await construireQrSession(
        session: _sessionTest(),
        tabPriv: paire.privee,
      );

      final enveloppe =
          jsonDecode(enveloppeQr.enveloppeJSON) as Map<String, dynamic>;
      final octetsASigner = utf8.encode(
        ConstructeurEnveloppe.serialiserPourSignature(
          type: enveloppe['type'] as String,
          version: enveloppe['version'] as int,
          timestamp: enveloppe['timestamp'] as String,
          payload: enveloppe['payload'] as Map<String, dynamic>,
        ),
      );
      final signature = base64.decode(enveloppe['signature'] as String);

      expect(
        await Crypto.verifier(paire.publique, octetsASigner, signature),
        isTrue,
      );
    });

    test('signature invalide si verifiee avec une autre cle publique',
        () async {
      final paire = await Crypto.genererPaireDeCles();
      final autrePaire = await Crypto.genererPaireDeCles();

      final enveloppeQr = await construireQrSession(
        session: _sessionTest(),
        tabPriv: paire.privee,
      );

      final enveloppe =
          jsonDecode(enveloppeQr.enveloppeJSON) as Map<String, dynamic>;
      final octetsASigner = utf8.encode(
        ConstructeurEnveloppe.serialiserPourSignature(
          type: enveloppe['type'] as String,
          version: enveloppe['version'] as int,
          timestamp: enveloppe['timestamp'] as String,
          payload: enveloppe['payload'] as Map<String, dynamic>,
        ),
      );
      final signature = base64.decode(enveloppe['signature'] as String);

      expect(
        await Crypto.verifier(autrePaire.publique, octetsASigner, signature),
        isFalse,
      );
    });

    test('chaine de codage symetrique : base64 -> zlib -> JSON', () async {
      final paire = await Crypto.genererPaireDeCles();

      final enveloppeQr = await construireQrSession(
        session: _sessionTest(),
        tabPriv: paire.privee,
      );

      final compresse = base64.decode(enveloppeQr.chargeUtileBase64);
      final texteJson = utf8.decode(ZLibCodec().decode(compresse));
      expect(texteJson, enveloppeQr.enveloppeJSON);
    });
  });
}
