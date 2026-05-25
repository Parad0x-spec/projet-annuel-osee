import 'dart:convert';
import 'dart:io';

import 'package:tablette_flutter/core/crypto.dart';
import 'package:tablette_flutter/features/appairage/domain.dart';

String _compresserEtEncoder(String enveloppeJSON) {
  final octetsCompresses = ZLibCodec().encode(utf8.encode(enveloppeJSON));
  return base64.encode(octetsCompresses);
}

Future<String> fabriquerChargeUtileCreationPatient({
  required List<int> clePriveePc,
  required String patientId,
  required String patientInitiales,
  required int niveauDemande,
  String timestamp = '2026-05-25T10:00:00Z',
}) async {
  final payload = <String, dynamic>{
    'patient_id': patientId,
    'patient_initiales': patientInitiales,
    'niveau_demande': niveauDemande,
  };

  final messageSigne = utf8.encode(
    jsonEncode(<String, dynamic>{
      'type': typeCreationPatient,
      'version': versionProtocole,
      'timestamp': timestamp,
      'payload': payload,
    }),
  );
  final signature = await Crypto.signer(clePriveePc, messageSigne);

  final enveloppeJSON = jsonEncode(<String, dynamic>{
    'type': typeCreationPatient,
    'version': versionProtocole,
    'timestamp': timestamp,
    'payload': payload,
    'signature': base64.encode(signature),
  });
  return _compresserEtEncoder(enveloppeJSON);
}

String fabriquerChargeUtileAppairagePc({
  required String pairingId,
  required List<int> pcPub,
  String timestamp = '2026-05-25T10:00:00Z',
}) {
  final enveloppeJSON = jsonEncode(<String, dynamic>{
    'type': typeAppairagePc,
    'version': versionProtocole,
    'timestamp': timestamp,
    'payload': <String, dynamic>{
      'pairing_id': pairingId,
      'pc_pub': base64.encode(pcPub),
    },
    'signature': '',
  });
  return _compresserEtEncoder(enveloppeJSON);
}
