import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tablette_flutter/core/crypto.dart';
import 'package:tablette_flutter/features/appairage/data.dart';
import 'package:tablette_flutter/features/appairage/domain.dart';

void main() {
  group('GenerateurQRRetour', () {
    test('produit une enveloppe avec le bon type, version et pairing_id',
        () async {
      final paire = await Crypto.genererPaireDeCles();
      final pairingIdAttendu = '64369080-a18c-4b6f-b52d-29420fe87cb4';

      final qrRetour = await GenerateurQRRetour.generer(
        pairingId: pairingIdAttendu,
        tabPriv: paire.privee,
        tabPub: paire.publique,
        horodatage: DateTime.utc(2026, 5, 8, 9, 0, 0),
      );

      final enveloppe = jsonDecode(qrRetour.enveloppeJSON) as Map<String, dynamic>;
      expect(enveloppe['type'], typeAppairageTablette);
      expect(enveloppe['version'], versionProtocole);
      expect(enveloppe['timestamp'], '2026-05-08T09:00:00.000Z');

      final payload = enveloppe['payload'] as Map<String, dynamic>;
      expect(payload['pairing_id'], pairingIdAttendu);

      final tabPubDecode = base64.decode(payload['tab_pub'] as String);
      expect(tabPubDecode, equals(paire.publique));
    });

    test('produit une signature non vide et verifiable avec tab_pub', () async {
      final paire = await Crypto.genererPaireDeCles();

      final qrRetour = await GenerateurQRRetour.generer(
        pairingId: 'paire-001',
        tabPriv: paire.privee,
        tabPub: paire.publique,
      );

      final enveloppe = jsonDecode(qrRetour.enveloppeJSON) as Map<String, dynamic>;
      final signatureBase64 = enveloppe['signature'] as String;
      expect(signatureBase64, isNotEmpty);

      final octetsASigner = utf8.encode(GenerateurQRRetour.serialiserPourSignature(
        type: enveloppe['type'] as String,
        version: enveloppe['version'] as int,
        timestamp: enveloppe['timestamp'] as String,
        payload: enveloppe['payload'] as Map<String, dynamic>,
      ));
      final signature = base64.decode(signatureBase64);
      final estValide = await Crypto.verifier(
        paire.publique,
        octetsASigner,
        signature,
      );
      expect(estValide, isTrue);
    });

    test(
        'la signature est invalide si verifiee avec une autre cle publique',
        () async {
      final paire = await Crypto.genererPaireDeCles();
      final autrePaire = await Crypto.genererPaireDeCles();

      final qrRetour = await GenerateurQRRetour.generer(
        pairingId: 'paire-002',
        tabPriv: paire.privee,
        tabPub: paire.publique,
      );

      final enveloppe = jsonDecode(qrRetour.enveloppeJSON) as Map<String, dynamic>;
      final signature = base64.decode(enveloppe['signature'] as String);
      final octetsASigner = utf8.encode(GenerateurQRRetour.serialiserPourSignature(
        type: enveloppe['type'] as String,
        version: enveloppe['version'] as int,
        timestamp: enveloppe['timestamp'] as String,
        payload: enveloppe['payload'] as Map<String, dynamic>,
      ));
      final estValide = await Crypto.verifier(
        autrePaire.publique,
        octetsASigner,
        signature,
      );
      expect(estValide, isFalse);
    });

    test(
        'chaine de codage symetrique : base64 -> zlib -> JSON donne la meme enveloppe',
        () async {
      final paire = await Crypto.genererPaireDeCles();

      final qrRetour = await GenerateurQRRetour.generer(
        pairingId: 'paire-003',
        tabPriv: paire.privee,
        tabPub: paire.publique,
      );

      final compresse = base64.decode(qrRetour.chargeUtileBase64);
      final octetsJson = ZLibCodec().decode(compresse);
      final texteJson = utf8.decode(octetsJson);
      expect(texteJson, qrRetour.enveloppeJSON);

      final enveloppeReconstituee =
          jsonDecode(texteJson) as Map<String, dynamic>;
      expect(enveloppeReconstituee['type'], typeAppairageTablette);
      expect(enveloppeReconstituee['payload'], isA<Map<String, dynamic>>());
    });
  });
}
