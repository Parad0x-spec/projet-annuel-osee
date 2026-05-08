import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import '../../core/crypto.dart';
import '../../core/stockage.dart';
import 'domain.dart';

class DepotAppairage {
  final Stockage _stockage;

  DepotAppairage(this._stockage);

  Future<Appairage?> lireActuel() async {
    final ligne = await _stockage.lireAppairageActuel();
    if (ligne == null) return null;
    return Appairage(
      pairingId: ligne['pairing_id'] as String,
      pcPub: List<int>.from(ligne['pc_pub'] as Uint8List),
      tabPriv: List<int>.from(ligne['tab_priv'] as Uint8List),
      tabPub: List<int>.from(ligne['tab_pub'] as Uint8List),
      dateAppairage: DateTime.parse(ligne['date_appairage'] as String),
    );
  }

  Future<void> enregistrer({
    required String pairingId,
    required List<int> pcPub,
    required List<int> tabPriv,
    required List<int> tabPub,
  }) async {
    await _stockage.insererAppairage(
      pairingId: pairingId,
      pcPub: pcPub,
      tabPriv: tabPriv,
      tabPub: tabPub,
      dateAppairage: DateTime.now().toUtc(),
    );
  }
}

class DecodeurEnveloppe {
  DecodeurEnveloppe._();

  static Enveloppe decoder(String chargeUtileBase64) {
    try {
      final compresse = base64.decode(chargeUtileBase64.trim());
      final octetsJson = ZLibCodec().decode(compresse);
      final texteJson = utf8.decode(octetsJson);
      final donnees = jsonDecode(texteJson);
      if (donnees is! Map<String, dynamic>) {
        throw const EnveloppeInvalideException('JSON racine non objet');
      }
      return Enveloppe.depuisJson(donnees);
    } on EnveloppeInvalideException {
      rethrow;
    } on FormatException catch (e) {
      throw EnveloppeInvalideException('format: ${e.message}');
    } catch (e) {
      throw EnveloppeInvalideException('decodage: $e');
    }
  }
}

class QRRetour {
  final String chargeUtileBase64;
  final String enveloppeJSON;

  const QRRetour({
    required this.chargeUtileBase64,
    required this.enveloppeJSON,
  });
}

class GenerateurQRRetour {
  GenerateurQRRetour._();

  static Future<QRRetour> generer({
    required String pairingId,
    required List<int> tabPriv,
    required List<int> tabPub,
    DateTime? horodatage,
  }) async {
    final timestamp = (horodatage ?? DateTime.now().toUtc()).toIso8601String();
    final payload = <String, dynamic>{
      'pairing_id': pairingId,
      'tab_pub': base64.encode(tabPub),
    };

    final donneesASigner = <String, dynamic>{
      'type': typeAppairageTablette,
      'version': versionProtocole,
      'timestamp': timestamp,
      'payload': payload,
    };
    final octetsASigner = utf8.encode(jsonEncode(donneesASigner));
    final signature = await Crypto.signer(tabPriv, octetsASigner);

    final enveloppe = <String, dynamic>{
      'type': typeAppairageTablette,
      'version': versionProtocole,
      'timestamp': timestamp,
      'payload': payload,
      'signature': base64.encode(signature),
    };
    final enveloppeJSON = jsonEncode(enveloppe);
    final octetsCompresses = ZLibCodec().encode(utf8.encode(enveloppeJSON));
    final chargeUtileBase64 = base64.encode(octetsCompresses);

    return QRRetour(
      chargeUtileBase64: chargeUtileBase64,
      enveloppeJSON: enveloppeJSON,
    );
  }

  static String serialiserPourSignature({
    required String type,
    required int version,
    required String timestamp,
    required Map<String, dynamic> payload,
  }) {
    return jsonEncode(<String, dynamic>{
      'type': type,
      'version': version,
      'timestamp': timestamp,
      'payload': payload,
    });
  }
}
