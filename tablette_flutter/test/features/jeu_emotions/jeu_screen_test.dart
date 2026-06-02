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

const _plancheFictive = Planche(
  cheminAsset: 'assets/planches/planche_1.jpg',
  largeur: 1000,
  hauteur: 1000,
  personnages: <PersonnageAnnotation>[
    PersonnageAnnotation(x: 100, y: 100, rayon: 30, emotion: 'joie'),
    PersonnageAnnotation(x: 200, y: 100, rayon: 30, emotion: 'joie'),
    PersonnageAnnotation(x: 100, y: 200, rayon: 30, emotion: 'colere'),
  ],
);

MoteurPlanche _moteurFictif() => MoteurPlanche(
      planche: _plancheFictive,
      numeroPlanche: 1,
      horlogeMs: () => 0,
    );

Future<ProviderContainer> _monterAvecPlanche(
  WidgetTester tester, {
  bool demo = false,
}) async {
  tester.view.physicalSize = const Size(1280, 800);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  final container = ProviderContainer();
  addTearDown(container.dispose);
  if (demo) {
    container.read(sessionEnCoursProvider.notifier).chargerDemo();
  } else {
    container.read(sessionEnCoursProvider.notifier).charger(_patient);
  }
  container
      .read(controleurPlancheProvider.notifier)
      .chargerMoteur(_moteurFictif());

  final routeur = creerRouteurApplication();
  routeur.go('/jeu');

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(routerConfig: routeur),
    ),
  );
  await tester.pump();
  return container;
}

void _simulerTap(WidgetTester tester, int x, int y) {
  final gestureDetector = tester.widget<GestureDetector>(
    find.byKey(const Key('jeu-canvas')),
  );
  gestureDetector.onTapDown!(
    TapDownDetails(localPosition: Offset(x.toDouble(), y.toDouble())),
  );
}

Future<void> _selectionnerEmotion(WidgetTester tester, String emotion) async {
  await tester.tap(find.byKey(Key('emotion-tile-$emotion')));
  await tester.pump();
}

void main() {
  testWidgets(
    'la barre laterale liste les quatre emotions avec leur compteur',
    (WidgetTester tester) async {
      await _monterAvecPlanche(tester);

      for (final emotion in emotionsOrdonnees) {
        expect(find.byKey(Key('emotion-tile-$emotion')), findsOneWidget);
      }
      expect(find.text(Textes.consigneSelectionnerEmotion), findsOneWidget);
      expect(find.text('0/2'), findsOneWidget);
      expect(find.text('0/1'), findsOneWidget);
    },
  );

  testWidgets(
    'selectionner une emotion met a jour la consigne courante',
    (WidgetTester tester) async {
      await _monterAvecPlanche(tester);

      await _selectionnerEmotion(tester, emotionJoie);

      expect(
        find.text(Textes.consigneTrouverEmotion(Textes.emotionJoieLibelle)),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'tap sur une cible de l\'emotion courante : marqueur vert et compteur a jour',
    (WidgetTester tester) async {
      final container = await _monterAvecPlanche(tester);
      await _selectionnerEmotion(tester, emotionJoie);

      _simulerTap(tester, 100, 100);
      await tester.pump();

      final etat = container.read(controleurPlancheProvider) as PlancheEnCours;
      expect(etat.moteur.nbCiblesTrouvees(emotionJoie), 1);
      expect(find.byIcon(Icons.check), findsOneWidget);
      expect(find.text('1/2'), findsOneWidget);
    },
  );

  testWidgets(
    'tap sur une mauvaise emotion : marqueur rouge PERSISTANT',
    (WidgetTester tester) async {
      final container = await _monterAvecPlanche(tester);
      await _selectionnerEmotion(tester, emotionJoie);

      _simulerTap(tester, 100, 200);
      await tester.pump();

      expect(find.byIcon(Icons.close), findsOneWidget);
      final etat = container.read(controleurPlancheProvider) as PlancheEnCours;
      expect(etat.moteur.nbFauxPositifs(emotionJoie), 1);

      await tester.pump(const Duration(milliseconds: 1500));
      expect(find.byIcon(Icons.close), findsOneWidget);
    },
  );

  testWidgets(
    'tap dans le vide : aucun marqueur ni penalite',
    (WidgetTester tester) async {
      final container = await _monterAvecPlanche(tester);
      await _selectionnerEmotion(tester, emotionJoie);

      _simulerTap(tester, 500, 500);
      await tester.pump();

      final etat = container.read(controleurPlancheProvider) as PlancheEnCours;
      expect(etat.moteur.nbCiblesTrouvees(emotionJoie), 0);
      expect(etat.moteur.nbFauxPositifs(emotionJoie), 0);
      expect(find.byIcon(Icons.check), findsNothing);
      expect(find.byIcon(Icons.close), findsNothing);
    },
  );

  testWidgets(
    'J\'ai fini sur planche incomplete affiche le tableau de selection',
    (WidgetTester tester) async {
      await _monterAvecPlanche(tester);
      await _selectionnerEmotion(tester, emotionJoie);
      _simulerTap(tester, 100, 100);
      await tester.pump();

      await tester.tap(find.text(Textes.boutonJaiFini));
      await tester.pump();

      expect(find.text(Textes.titreSelectionEmotions), findsOneWidget);
      expect(find.byKey(const Key('check-joie')), findsOneWidget);
    },
  );

  testWidgets(
    'le tableau de selection valide termine la planche et route vers le resultat',
    (WidgetTester tester) async {
      final container = await _monterAvecPlanche(tester);
      await _selectionnerEmotion(tester, emotionJoie);
      _simulerTap(tester, 100, 100);
      await tester.pump();

      await tester.tap(find.text(Textes.boutonJaiFini));
      await tester.pump();
      await tester.tap(find.text(Textes.boutonValiderSelection));
      await tester.pump();
      await tester.pump();

      expect(container.read(planchesSeanceProvider), hasLength(1));
      expect(find.text(Textes.titreResultatPlanche), findsOneWidget);
    },
  );

  testWidgets(
    'planche complete : J\'ai fini route directement au resultat sans tableau',
    (WidgetTester tester) async {
      final container = await _monterAvecPlanche(tester);
      await _selectionnerEmotion(tester, emotionJoie);
      _simulerTap(tester, 100, 100);
      _simulerTap(tester, 200, 100);
      await tester.pump();
      await _selectionnerEmotion(tester, emotionColere);
      _simulerTap(tester, 100, 200);
      await tester.pump();

      await tester.tap(find.text(Textes.boutonJaiFini));
      await tester.pump();
      await tester.pump();

      expect(find.text(Textes.titreSelectionEmotions), findsNothing);
      expect(container.read(planchesSeanceProvider), hasLength(1));
      expect(find.text(Textes.titreResultatPlanche), findsOneWidget);
    },
  );

  testWidgets(
    'Arreter demande confirmation puis abandonne sans enregistrer la planche',
    (WidgetTester tester) async {
      final container = await _monterAvecPlanche(tester);

      await tester.tap(find.text(Textes.boutonArreter));
      await tester.pump();
      expect(find.text(Textes.titreConfirmationArret), findsOneWidget);

      await tester.tap(find.text(Textes.boutonConfirmerArret));
      await tester.pump();
      await tester.pump();

      expect(container.read(planchesSeanceProvider), isEmpty);
      expect(container.read(controleurPlancheProvider), isA<AucunePlanche>());
      expect(find.text(Textes.titreRecapitulatifSeance), findsOneWidget);
    },
  );
}
