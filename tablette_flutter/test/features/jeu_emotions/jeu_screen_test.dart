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

MoteurPartie _moteurFictif() => MoteurPartie(
      planche: _plancheFictive,
      numeroPlanche: 1,
      emotionCible: emotionJoie,
      horlogeMs: () => 0,
    );

Future<ProviderContainer> _monterAvecPartie(WidgetTester tester) async {
  final container = ProviderContainer();
  addTearDown(container.dispose);
  container.read(sessionEnCoursProvider.notifier).charger(_patient);
  container
      .read(controleurPartieProvider.notifier)
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

void main() {
  testWidgets(
    'affiche la consigne avec l\'emotion cible et les deux boutons',
    (WidgetTester tester) async {
      await _monterAvecPartie(tester);

      expect(
        find.text(Textes.consigneTrouverEmotion(Textes.emotionJoieLibelle)),
        findsOneWidget,
      );
      expect(find.text(Textes.boutonJaiFini), findsOneWidget);
      expect(find.text(Textes.boutonArreter), findsOneWidget);
    },
  );

  testWidgets(
    'tap sur une cible affiche un feedback vert persistant',
    (WidgetTester tester) async {
      final container = await _monterAvecPartie(tester);

      _simulerTap(tester, 100, 100);
      await tester.pump();

      final etat = container.read(controleurPartieProvider) as PartieEnCours;
      expect(etat.moteur.nbCiblesTrouvees, 1);
      expect(find.byIcon(Icons.check), findsOneWidget);
    },
  );

  testWidgets(
    'tap sur mauvaise emotion affiche un feedback rouge qui disparait',
    (WidgetTester tester) async {
      final container = await _monterAvecPartie(tester);

      _simulerTap(tester, 100, 200);
      await tester.pump();

      expect(find.byIcon(Icons.close), findsOneWidget);
      final etat = container.read(controleurPartieProvider) as PartieEnCours;
      expect(etat.moteur.nbFauxPositifs, 1);

      await tester.pump(const Duration(milliseconds: 1100));
      expect(find.byIcon(Icons.close), findsNothing);
    },
  );

  testWidgets(
    'tap dans le vide ne genere ni feedback ni penalite',
    (WidgetTester tester) async {
      final container = await _monterAvecPartie(tester);

      _simulerTap(tester, 500, 500);
      await tester.pump();

      final etat = container.read(controleurPartieProvider) as PartieEnCours;
      expect(etat.moteur.nbCiblesTrouvees, 0);
      expect(etat.moteur.nbFauxPositifs, 0);
      expect(find.byIcon(Icons.check), findsNothing);
      expect(find.byIcon(Icons.close), findsNothing);
    },
  );

  testWidgets(
    'bouton J\'ai fini termine la partie et route vers la transition',
    (WidgetTester tester) async {
      final container = await _monterAvecPartie(tester);

      await tester.tap(find.text(Textes.boutonJaiFini));
      await tester.pump();
      await tester.pump();

      expect(container.read(partiesSeanceProvider), hasLength(1));
      expect(
        container.read(partiesSeanceProvider).first.modeFin,
        ModeFin.termineeBouton,
      );
      expect(find.text(Textes.titreTransitionPartie), findsOneWidget);
    },
  );

  testWidgets(
    'bouton Arreter demande confirmation puis abandonne la partie',
    (WidgetTester tester) async {
      final container = await _monterAvecPartie(tester);

      await tester.tap(find.text(Textes.boutonArreter));
      await tester.pump();
      await tester.pump();

      expect(find.text(Textes.titreConfirmationArret), findsOneWidget);

      await tester.tap(find.text(Textes.boutonConfirmerArret));
      await tester.pump();
      await tester.pump();

      expect(container.read(partiesSeanceProvider), hasLength(1));
      expect(
        container.read(partiesSeanceProvider).first.modeFin,
        ModeFin.abandonnee,
      );
      expect(find.text(Textes.titreTransitionPartie), findsOneWidget);
    },
  );

  testWidgets(
    'bouton Continuer dans la confirmation ne termine pas la partie',
    (WidgetTester tester) async {
      final container = await _monterAvecPartie(tester);

      await tester.tap(find.text(Textes.boutonArreter));
      await tester.pump();
      await tester.pump();
      await tester.tap(find.text(Textes.boutonAnnulerArret));
      await tester.pump();
      await tester.pump();

      expect(container.read(partiesSeanceProvider), isEmpty);
      expect(container.read(controleurPartieProvider), isA<PartieEnCours>());
    },
  );
}
