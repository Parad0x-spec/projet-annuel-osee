const String typeAppairagePc = 'appairage_pc';
const String typeAppairageTablette = 'appairage_tablette';
const String typeSession = 'session';
const int versionProtocole = 1;

sealed class EtatAppairage {
  const EtatAppairage();
}

class AppairageInitial extends EtatAppairage {
  const AppairageInitial();
}

class AppairageEnCours extends EtatAppairage {
  const AppairageEnCours();
}

class AppairageReussi extends EtatAppairage {
  final String chargeUtileQRRetour;
  final String pairingId;

  const AppairageReussi({
    required this.chargeUtileQRRetour,
    required this.pairingId,
  });
}

class AppairageEchec extends EtatAppairage {
  const AppairageEchec();
}

class Appairage {
  final String pairingId;
  final List<int> pcPub;
  final List<int> tabPriv;
  final List<int> tabPub;
  final DateTime dateAppairage;

  const Appairage({
    required this.pairingId,
    required this.pcPub,
    required this.tabPriv,
    required this.tabPub,
    required this.dateAppairage,
  });
}

class Enveloppe {
  final String type;
  final int version;
  final String timestamp;
  final Map<String, dynamic> payload;
  final String signature;

  const Enveloppe({
    required this.type,
    required this.version,
    required this.timestamp,
    required this.payload,
    required this.signature,
  });

  factory Enveloppe.depuisJson(Map<String, dynamic> donnees) {
    return Enveloppe(
      type: donnees['type'] as String,
      version: donnees['version'] as int,
      timestamp: donnees['timestamp'] as String,
      payload: Map<String, dynamic>.from(donnees['payload'] as Map),
      signature: donnees['signature'] as String,
    );
  }
}

class EnveloppeInvalideException implements Exception {
  final String message;
  const EnveloppeInvalideException(this.message);

  @override
  String toString() => 'EnveloppeInvalideException: $message';
}
