import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tablette_flutter/app/router.dart';
import 'package:tablette_flutter/core/crypto.dart';
import 'package:tablette_flutter/core/textes.dart';
import 'package:tablette_flutter/features/appairage/controller.dart';
import 'package:tablette_flutter/features/appairage/domain.dart';
import 'package:tablette_flutter/features/jeu_emotions/controller.dart';

import '../../support/fabrique_enveloppe.dart';

class _ControleurAppairageStub extends ControleurAppairage {
  static String? dernierScan;

  @override
  EtatAppairage build() => const AppairageInitial();

  @override
  Future<void> traiterScan(String chargeUtileBase64) async {
    dernierScan = chargeUtileBase64;
  }
}

Future<void> _monterAccueil(
  WidgetTester tester, {
  required List<Override> overrides,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: overrides,
      child: MaterialApp.router(routerConfig: creerRouteurApplication()),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'un QR creation_patient verifie route vers ConfirmationPatientScreen',
    (WidgetTester tester) async {
      final paire = await Crypto.genererPaireDeCles();
      final chargeUtile = await fabriquerChargeUtileCreationPatient(
        clePriveePc: paire.privee,
        patientId: 'id-123',
        patientInitiales: 'MD',
        niveauDemande: 3,
      );
      final appairage = Appairage(
        pairingId: 'paire-test',
        pcPub: paire.publique,
        tabPriv: List<int>.filled(32, 2),
        tabPub: List<int>.filled(32, 3),
        dateAppairage: DateTime.utc(2026, 5, 8),
      );

      await _monterAccueil(
        tester,
        overrides: [
          appairageActuelProvider.overrideWith((ref) async => appairage),
          scannerQrProvider.overrideWithValue(
            (context) async => chargeUtile,
          ),
        ],
      );

      await tester.tap(find.text(Textes.boutonNouveauPatient));
      await tester.pumpAndSettle();

      expect(find.text(Textes.titreConfirmationPatient), findsOneWidget);
      expect(
        find.text(Textes.confirmationPatientPret('MD')),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'un QR appairage_pc route vers la mecanique d\'appairage existante',
    (WidgetTester tester) async {
      _ControleurAppairageStub.dernierScan = null;
      final chargeUtile = fabriquerChargeUtileAppairagePc(
        pairingId: 'paire-test',
        pcPub: List<int>.filled(32, 7),
      );

      await _monterAccueil(
        tester,
        overrides: [
          appairageActuelProvider.overrideWith((ref) async => null),
          controleurAppairageProvider.overrideWith(
            _ControleurAppairageStub.new,
          ),
          scannerQrProvider.overrideWithValue(
            (context) async => chargeUtile,
          ),
        ],
      );

      await tester.tap(find.text(Textes.boutonNouveauPatient));
      await tester.pumpAndSettle();

      expect(_ControleurAppairageStub.dernierScan, chargeUtile);
      expect(find.text(Textes.consigneAppairage), findsOneWidget);
    },
  );

  testWidgets(
    'un QR creation_patient sans appairage affiche le message d\'erreur',
    (WidgetTester tester) async {
      final paire = await Crypto.genererPaireDeCles();
      final chargeUtile = await fabriquerChargeUtileCreationPatient(
        clePriveePc: paire.privee,
        patientId: 'id-123',
        patientInitiales: 'MD',
        niveauDemande: 3,
      );

      await _monterAccueil(
        tester,
        overrides: [
          appairageActuelProvider.overrideWith((ref) async => null),
          scannerQrProvider.overrideWithValue(
            (context) async => chargeUtile,
          ),
        ],
      );

      await tester.tap(find.text(Textes.boutonNouveauPatient));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 750));

      expect(find.text(Textes.erreurTabletteNonAppairee), findsOneWidget);
      expect(find.text(Textes.titreAccueil), findsOneWidget);
    },
  );
}
