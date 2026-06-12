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

Future<ProviderContainer> _monter(WidgetTester tester) async {
  final container = ProviderContainer();
  addTearDown(container.dispose);
  container.read(sessionEnCoursProvider.notifier).charger(_patient);

  final routeur = creerRouteurApplication();
  routeur.go('/choix-planche');

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
    'affiche le titre, la consigne et les quatre planches, sans choix d\'emotion',
    (WidgetTester tester) async {
      await _monter(tester);

      expect(find.text(Textes.titreChoixPlanche), findsOneWidget);
      expect(find.text(Textes.consignePlanche), findsOneWidget);
      for (var n = 1; n <= 4; n++) {
        expect(find.byKey(Key('planche-$n')), findsOneWidget);
      }
    },
  );

  testWidgets(
    'le bouton Lancer est desactive tant qu\'aucune planche n\'est choisie',
    (WidgetTester tester) async {
      await _monter(tester);

      final boutonAvant = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, Textes.boutonLancerPlanche),
      );
      expect(boutonAvant.onPressed, isNull);

      await tester.tap(find.byKey(const Key('planche-2')));
      await tester.pump();

      final boutonApres = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, Textes.boutonLancerPlanche),
      );
      expect(boutonApres.onPressed, isNotNull);
    },
  );

  testWidgets(
    'la fleche retour ramene a l\'accueil sans reinitialiser le patient',
    (WidgetTester tester) async {
      final container = await _monter(tester);

      await tester.tap(find.byTooltip(Textes.boutonRetourAccueil));
      await tester.pumpAndSettle();

      expect(find.text(Textes.titreAccueil), findsOneWidget);
      expect(container.read(sessionEnCoursProvider), isA<PatientCharge>());
    },
  );
}
