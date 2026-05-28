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
  routeur.go('/configuration-partie');

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
    'affiche les selecteurs planche et emotion et le bouton lancer',
    (WidgetTester tester) async {
      await _monter(tester);

      expect(find.text(Textes.consignePlanche), findsOneWidget);
      expect(find.text(Textes.consigneEmotion), findsOneWidget);
      for (var n = 1; n <= 4; n++) {
        expect(find.text(Textes.libellePlanche(n)), findsOneWidget);
      }
      expect(find.text(Textes.emotionJoieLibelle), findsOneWidget);
      expect(find.text(Textes.emotionColereLibelle), findsOneWidget);
      expect(find.text(Textes.emotionTristesseLibelle), findsOneWidget);
      expect(find.text(Textes.emotionPeurLibelle), findsOneWidget);
      expect(find.text(Textes.boutonLancerPartie), findsOneWidget);
    },
  );

  testWidgets(
    'bouton lancer desactive tant que planche et emotion ne sont pas choisies',
    (WidgetTester tester) async {
      await _monter(tester);

      final boutonLancerFinder = find.widgetWithText(
        ElevatedButton,
        Textes.boutonLancerPartie,
      );
      final bouton = tester.widget<ElevatedButton>(boutonLancerFinder);
      expect(bouton.onPressed, isNull);

      await tester.tap(find.text(Textes.libellePlanche(2)));
      await tester.pump();
      final bouton2 = tester.widget<ElevatedButton>(boutonLancerFinder);
      expect(bouton2.onPressed, isNull);

      await tester.tap(find.text(Textes.emotionJoieLibelle));
      await tester.pump();
      final bouton3 = tester.widget<ElevatedButton>(boutonLancerFinder);
      expect(bouton3.onPressed, isNotNull);
    },
  );

  testWidgets(
    'lancer la partie demarre le moteur et route vers le jeu',
    (WidgetTester tester) async {
      final container = await _monter(tester);

      await tester.tap(find.text(Textes.libellePlanche(1)));
      await tester.pump();
      await tester.tap(find.text(Textes.emotionJoieLibelle));
      await tester.pump();
      await tester.tap(find.text(Textes.boutonLancerPartie));
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      final etatPartie = container.read(controleurPartieProvider);
      expect(etatPartie, isA<PartieEnCours>());
      final moteur = (etatPartie as PartieEnCours).moteur;
      expect(moteur.numeroPlanche, 1);
      expect(moteur.emotionCible, emotionJoie);

      expect(find.text(Textes.titreJeu), findsOneWidget);
    },
  );

  testWidgets(
    'sans patient charge affiche le message dedie',
    (WidgetTester tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final routeur = creerRouteurApplication();
      routeur.go('/configuration-partie');

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(routerConfig: routeur),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(Textes.messageAucunPatientCharge), findsOneWidget);
    },
  );
}
