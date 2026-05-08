import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/crypto.dart';
import '../../core/stockage.dart';
import 'data.dart';
import 'domain.dart';

final stockageProvider = FutureProvider<Stockage>((ref) async {
  final stockage = await Stockage.ouvrir();
  ref.onDispose(() async {
    await stockage.fermer();
  });
  return stockage;
});

final depotAppairageProvider = FutureProvider<DepotAppairage>((ref) async {
  final stockage = await ref.watch(stockageProvider.future);
  return DepotAppairage(stockage);
});

final appairageActuelProvider = FutureProvider<Appairage?>((ref) async {
  final depot = await ref.watch(depotAppairageProvider.future);
  return depot.lireActuel();
});

class ControleurAppairage extends Notifier<EtatAppairage> {
  @override
  EtatAppairage build() => const AppairageInitial();

  Future<void> traiterScan(String chargeUtileBase64) async {
    state = const AppairageEnCours();
    try {
      final enveloppe = DecodeurEnveloppe.decoder(chargeUtileBase64);
      if (enveloppe.type != typeAppairagePc) {
        throw const EnveloppeInvalideException('type incorrect');
      }
      if (enveloppe.version != versionProtocole) {
        throw const EnveloppeInvalideException('version incompatible');
      }
      final pairingId = enveloppe.payload['pairing_id'] as String?;
      final pcPubBase64 = enveloppe.payload['pc_pub'] as String?;
      if (pairingId == null || pcPubBase64 == null) {
        throw const EnveloppeInvalideException('champs payload manquants');
      }
      final pcPub = base64.decode(pcPubBase64);
      final paireTablette = await Crypto.genererPaireDeCles();
      final depot = await ref.read(depotAppairageProvider.future);
      await depot.enregistrer(
        pairingId: pairingId,
        pcPub: pcPub,
        tabPriv: paireTablette.privee,
        tabPub: paireTablette.publique,
      );
      ref.invalidate(appairageActuelProvider);

      final qrRetour = await GenerateurQRRetour.generer(
        pairingId: pairingId,
        tabPriv: paireTablette.privee,
        tabPub: paireTablette.publique,
      );

      state = AppairageReussi(
        chargeUtileQRRetour: qrRetour.chargeUtileBase64,
        pairingId: pairingId,
      );
    } catch (_) {
      state = const AppairageEchec();
    }
  }

  void reinitialiser() {
    state = const AppairageInitial();
  }
}

final controleurAppairageProvider =
    NotifierProvider<ControleurAppairage, EtatAppairage>(
      ControleurAppairage.new,
    );
