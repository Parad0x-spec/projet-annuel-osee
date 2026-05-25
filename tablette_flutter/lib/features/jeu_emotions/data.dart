import '../../core/qr_envelope.dart';
import '../appairage/domain.dart';
import 'domain.dart';

class SessionEnCours {
  final PayloadCreationPatient patient;

  const SessionEnCours(this.patient);
}

Map<String, dynamic> serialiserPayloadSession(Session session) {
  return <String, dynamic>{
    'patient_id': session.patientId,
    'patient_initiales': session.patientInitiales,
    'session_date': session.sessionDate.toUtc().toIso8601String(),
    'jeu_type': session.jeuType,
    'niveau': session.niveau,
    'manches': session.manches.map((manche) => manche.versJson()).toList(),
  };
}

Future<EnveloppeQr> construireQrSession({
  required Session session,
  required List<int> tabPriv,
  DateTime? horodatage,
}) {
  final timestamp = (horodatage ?? DateTime.now().toUtc()).toIso8601String();
  return ConstructeurEnveloppe.construireEtSigner(
    type: typeSession,
    version: versionProtocole,
    timestamp: timestamp,
    payload: serialiserPayloadSession(session),
    clePrivee: tabPriv,
  );
}
