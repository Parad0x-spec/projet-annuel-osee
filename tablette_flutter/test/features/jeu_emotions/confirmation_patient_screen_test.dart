import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tablette_flutter/app/router.dart';
import 'package:tablette_flutter/core/textes.dart';
import 'package:tablette_flutter/features/jeu_emotions/controller.dart';
import 'package:tablette_flutter/features/jeu_emotions/domain.dart';

const _patient = PayloadCreationPatient(
  patientId: 'id-123',
  patientInitiales: 'MD',
  niveauDemande: 3,
);

Future<ProviderContainer> _monterConfirmation(WidgetTester tester) async {
  final container = ProviderContainer();
  addTearDown(container.dispose);
  container.read(sessionEnCoursProvider.notifier).charger(_patient);

  final routeur = creerRouteurApplication();
  routeur.go('/confirmation-patient');

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(routerConfig: routeur),
    ),
  );
  await tester.pumpAndSettle();
  return container;
}

void main() {
  testWidgets(
    'affiche les initiales chargees et les deux boutons',
    (WidgetTester tester) async {
      await _monterConfirmation(tester);

      expect(
        find.text(Textes.confirmationPatientPret('MD')),
        findsOneWidget,
      );
      expect(find.text(Textes.boutonCommencerJeu), findsOneWidget);
      expect(find.text(Textes.boutonAnnuler), findsOneWidget);
    },
  );

  testWidgets(
    'Commencer le jeu route vers la configuration de partie',
    (WidgetTester tester) async {
      await _monterConfirmation(tester);

      await tester.tap(find.text(Textes.boutonCommencerJeu));
      await tester.pumpAndSettle();

      expect(find.text(Textes.titreConfigurationPartie), findsOneWidget);
      expect(find.text(Textes.consignePlanche), findsOneWidget);
      expect(find.text(Textes.consigneEmotion), findsOneWidget);
    },
  );

  testWidgets(
    'Annuler revient a l\'accueil et reinitialise la session',
    (WidgetTester tester) async {
      final container = await _monterConfirmation(tester);

      await tester.tap(find.text(Textes.boutonAnnuler));
      await tester.pumpAndSettle();

      expect(find.text(Textes.titreAccueil), findsOneWidget);
      expect(container.read(sessionEnCoursProvider), isA<AucunPatientCharge>());
    },
  );
}
