import 'dart:convert';

import 'package:flutter/services.dart';

import '../../core/qr_envelope.dart';
import '../../core/stockage.dart';
import '../appairage/domain.dart';
import 'domain.dart';

class SessionEnCours {
  final PayloadCreationPatient patient;
  final bool estDemo;

  const SessionEnCours(this.patient, {this.estDemo = false});
}

class DepotContexteSession {
  final Stockage _stockage;

  DepotContexteSession(this._stockage);

  Future<void> enregistrer({
    required PayloadCreationPatient patient,
    required bool estDemo,
  }) {
    return _stockage.enregistrerContexteSession(
      patientId: patient.patientId,
      patientInitiales: patient.patientInitiales,
      niveauDemande: patient.niveauDemande,
      estDemo: estDemo,
    );
  }

  Future<SessionEnCours?> lire() async {
    final ligne = await _stockage.lireContexteSession();
    if (ligne == null) return null;
    return SessionEnCours(
      PayloadCreationPatient(
        patientId: ligne['patient_id'] as String,
        patientInitiales: ligne['patient_initiales'] as String,
        niveauDemande: ligne['niveau_demande'] as int,
      ),
      estDemo: (ligne['est_demo'] as int) == 1,
    );
  }

  Future<void> effacer() => _stockage.effacerContexteSession();
}

Map<String, dynamic> serialiserPayloadSession(Session session) {
  return <String, dynamic>{
    'patient_id': session.patientId,
    'patient_initiales': session.patientInitiales,
    'session_date': session.sessionDate.toUtc().toIso8601String(),
    'jeu_type': jeuTypeEmotions,
    'niveau': session.niveauDemande,
    'parties': session.parties.map((partie) => partie.versJson()).toList(),
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

class PlancheInvalideException implements Exception {
  final String message;
  const PlancheInvalideException(this.message);

  @override
  String toString() => 'PlancheInvalideException: $message';
}

String cheminAssetPlanche(int numeroPlanche) =>
    'assets/planches/planche_$numeroPlanche.jpg';

String _cheminJsonPlanche(int numeroPlanche) =>
    'assets/planches/planche_$numeroPlanche.json';

Planche parserPlanche({
  required int numeroPlanche,
  required String contenuJson,
}) {
  final Object? brut;
  try {
    brut = jsonDecode(contenuJson);
  } on FormatException catch (e) {
    throw PlancheInvalideException('json illisible: ${e.message}');
  }
  if (brut is! Map<String, dynamic>) {
    throw const PlancheInvalideException('racine du JSON non-objet');
  }
  final largeur = brut['largeur'];
  final hauteur = brut['hauteur'];
  final personnagesBruts = brut['personnages'];
  if (largeur is! int || largeur <= 0) {
    throw const PlancheInvalideException('largeur absente ou invalide');
  }
  if (hauteur is! int || hauteur <= 0) {
    throw const PlancheInvalideException('hauteur absente ou invalide');
  }
  if (personnagesBruts is! List) {
    throw const PlancheInvalideException('personnages absent ou non-liste');
  }

  final personnages = <PersonnageAnnotation>[];
  for (var index = 0; index < personnagesBruts.length; index++) {
    final p = personnagesBruts[index];
    if (p is! Map<String, dynamic>) {
      throw PlancheInvalideException('personnage $index non-objet');
    }
    final x = p['x'];
    final y = p['y'];
    final rayon = p['rayon'];
    final emotion = p['emotion'];
    if (x is! int || y is! int || rayon is! int || emotion is! String) {
      throw PlancheInvalideException(
        'personnage $index : champs manquants ou de mauvais type',
      );
    }
    if (!emotionsValides.contains(emotion)) {
      throw PlancheInvalideException(
        'personnage $index : emotion invalide "$emotion"',
      );
    }
    if (rayon <= 0) {
      throw PlancheInvalideException(
        'personnage $index : rayon non strictement positif',
      );
    }
    if (x < 0 || x >= largeur || y < 0 || y >= hauteur) {
      throw PlancheInvalideException(
        'personnage $index : coordonnees ($x,$y) hors planche ${largeur}x$hauteur',
      );
    }
    personnages.add(
      PersonnageAnnotation(x: x, y: y, rayon: rayon, emotion: emotion),
    );
  }

  return Planche(
    cheminAsset: cheminAssetPlanche(numeroPlanche),
    largeur: largeur,
    hauteur: hauteur,
    personnages: personnages,
  );
}

Future<Planche> chargerPlanche(int numeroPlanche) async {
  final contenuJson = await rootBundle.loadString(
    _cheminJsonPlanche(numeroPlanche),
  );
  return parserPlanche(
    numeroPlanche: numeroPlanche,
    contenuJson: contenuJson,
  );
}

