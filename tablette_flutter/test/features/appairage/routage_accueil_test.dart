import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tablette_flutter/app/router.dart';
import 'package:tablette_flutter/core/textes.dart';
import 'package:tablette_flutter/features/appairage/controller.dart';
import 'package:tablette_flutter/features/appairage/domain.dart';

void main() {
  testWidgets(
    'Nouveau patient route vers /appairage si aucun appairage en base',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appairageActuelProvider.overrideWith((ref) async => null),
          ],
          child: MaterialApp.router(routerConfig: creerRouteurApplication()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(Textes.titreAccueil), findsOneWidget);

      await tester.tap(find.text(Textes.boutonNouveauPatient));
      await tester.pumpAndSettle();

      expect(find.text(Textes.consigneAppairage), findsOneWidget);
      expect(find.text(Textes.boutonScannerQRPC), findsOneWidget);
    },
  );

  testWidgets(
    'Nouveau patient route vers /jeu si un appairage existe deja',
    (WidgetTester tester) async {
      final appairageEnregistre = Appairage(
        pairingId: 'paire-test',
        pcPub: List<int>.filled(32, 1),
        tabPriv: List<int>.filled(32, 2),
        tabPub: List<int>.filled(32, 3),
        dateAppairage: DateTime.utc(2026, 5, 8),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appairageActuelProvider.overrideWith(
              (ref) async => appairageEnregistre,
            ),
          ],
          child: MaterialApp.router(routerConfig: creerRouteurApplication()),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text(Textes.boutonNouveauPatient));
      await tester.pumpAndSettle();

      expect(find.text(Textes.messageJeuPlaceholder), findsOneWidget);
    },
  );
}
