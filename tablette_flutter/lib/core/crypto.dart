import 'package:cryptography/cryptography.dart';

class PaireDeCles {
  final List<int> privee;
  final List<int> publique;

  const PaireDeCles({required this.privee, required this.publique});
}

class Crypto {
  Crypto._();

  static final Ed25519 _algorithme = Ed25519();
  static const int _tailleClePrivee = 32;
  static const int _tailleClePublique = 32;
  static const int _tailleSignature = 64;

  static Future<PaireDeCles> genererPaireDeCles() async {
    final paire = await _algorithme.newKeyPair();
    final clePublique = await paire.extractPublicKey();
    final clePriveeBytes = await paire.extractPrivateKeyBytes();
    return PaireDeCles(privee: clePriveeBytes, publique: clePublique.bytes);
  }

  static Future<List<int>> signer(List<int> clePrivee, List<int> message) async {
    if (clePrivee.length != _tailleClePrivee) {
      throw ArgumentError('crypto: cle privee de taille invalide');
    }
    final paire = await _algorithme.newKeyPairFromSeed(clePrivee);
    final signature = await _algorithme.sign(message, keyPair: paire);
    return signature.bytes;
  }

  static Future<bool> verifier(
    List<int> clePublique,
    List<int> message,
    List<int> signature,
  ) async {
    if (clePublique.length != _tailleClePublique) {
      return false;
    }
    if (signature.length != _tailleSignature) {
      return false;
    }
    final pub = SimplePublicKey(clePublique, type: KeyPairType.ed25519);
    return _algorithme.verify(
      message,
      signature: Signature(signature, publicKey: pub),
    );
  }
}
