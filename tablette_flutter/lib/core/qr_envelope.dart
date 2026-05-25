import 'dart:convert';
import 'dart:io';

import 'crypto.dart';

class EnveloppeQr {
  final String chargeUtileBase64;
  final String enveloppeJSON;

  const EnveloppeQr({
    required this.chargeUtileBase64,
    required this.enveloppeJSON,
  });
}

class ConstructeurEnveloppe {
  ConstructeurEnveloppe._();

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

  static Future<EnveloppeQr> construireEtSigner({
    required String type,
    required int version,
    required String timestamp,
    required Map<String, dynamic> payload,
    required List<int> clePrivee,
  }) async {
    final octetsASigner = utf8.encode(
      serialiserPourSignature(
        type: type,
        version: version,
        timestamp: timestamp,
        payload: payload,
      ),
    );
    final signature = await Crypto.signer(clePrivee, octetsASigner);

    final enveloppe = <String, dynamic>{
      'type': type,
      'version': version,
      'timestamp': timestamp,
      'payload': payload,
      'signature': base64.encode(signature),
    };
    final enveloppeJSON = jsonEncode(enveloppe);
    final octetsCompresses = ZLibCodec().encode(utf8.encode(enveloppeJSON));

    return EnveloppeQr(
      chargeUtileBase64: base64.encode(octetsCompresses),
      enveloppeJSON: enveloppeJSON,
    );
  }
}
