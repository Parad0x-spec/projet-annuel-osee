import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:tablette_flutter/core/crypto.dart';

void main() {
  group('Crypto ed25519', () {
    test('genererPaireDeCles produit des cles aux bonnes tailles', () async {
      final paire = await Crypto.genererPaireDeCles();
      expect(paire.privee.length, 32);
      expect(paire.publique.length, 32);
    });

    test('signer puis verifier reussit sur un message', () async {
      final paire = await Crypto.genererPaireDeCles();
      final message = utf8.encode('message de test');
      final signature = await Crypto.signer(paire.privee, message);
      expect(signature.length, 64);
      expect(
        await Crypto.verifier(paire.publique, message, signature),
        isTrue,
      );
    });

    test('verifier rejette une signature corrompue', () async {
      final paire = await Crypto.genererPaireDeCles();
      final message = utf8.encode('message de test');
      final signature = await Crypto.signer(paire.privee, message);
      signature[0] ^= 0xFF;
      expect(
        await Crypto.verifier(paire.publique, message, signature),
        isFalse,
      );
    });

    test('verifier rejette avec une mauvaise cle publique', () async {
      final paire = await Crypto.genererPaireDeCles();
      final autrePaire = await Crypto.genererPaireDeCles();
      final message = utf8.encode('message de test');
      final signature = await Crypto.signer(paire.privee, message);
      expect(
        await Crypto.verifier(autrePaire.publique, message, signature),
        isFalse,
      );
    });

    test('verifier rejette un message different', () async {
      final paire = await Crypto.genererPaireDeCles();
      final messageOriginal = utf8.encode('message original');
      final messageDifferent = utf8.encode('message different');
      final signature = await Crypto.signer(paire.privee, messageOriginal);
      expect(
        await Crypto.verifier(paire.publique, messageDifferent, signature),
        isFalse,
      );
    });

    test('signer rejette une cle privee malformee', () async {
      expect(
        () => Crypto.signer(List<int>.filled(16, 0), utf8.encode('test')),
        throwsArgumentError,
      );
    });

    test('verifier rejette une cle publique malformee', () async {
      final paire = await Crypto.genererPaireDeCles();
      final signature = await Crypto.signer(paire.privee, utf8.encode('test'));
      expect(
        await Crypto.verifier(
          List<int>.filled(16, 0),
          utf8.encode('test'),
          signature,
        ),
        isFalse,
      );
    });
  });
}
