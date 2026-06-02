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

PlancheJouee _planche({int scoreGlobal = 80}) => PlancheJouee(
      numeroPlanche: 1,
      scoreGlobal: scoreGlobal,
      resultatsParEmotion: const <ResultatEmotion>[
        ResultatEmotion(
          emotion: 'joie',
          nbCiblesTotal: 2,
          nbCiblesTrouvees: 2,
          nbFauxPositifs: 0,
          score: 100,
          evaluee: true,
        ),
        ResultatEmotion(
          emotion: 'colere',
          nbCiblesTotal: 2,
          nbCiblesTrouvees: 1,
          nbFauxPositifs: 0,
          score: 50,
          evaluee: true,
        ),
        ResultatEmotion(
          emotion: 'tristesse',
          nbCiblesTotal: 1,
          nbCiblesTrouvees: 0,
          nbFauxPositifs: 0,
          score: 0,
          evaluee: false,
        ),
        ResultatEmotion(
          emotion: 'peur',
          nbCiblesTotal: 0,
          nbCiblesTrouvees: 0,
          nbFauxPositifs: 0,
          score: 0,
          evaluee: false,
        ),
      ],
    );

Future<ProviderContainer> _monter(
  WidgetTester tester, {
  bool demo = false,
}) async {
  final container = ProviderContainer();
  addTearDown(container.dispose);
  if (demo) {
    container.read(sessionEnCoursProvider.notifier).chargerDemo();
  } else {
    container.read(sessionEnCoursProvider.notifier).charger(_patient);
  }
  container.read(planchesSeanceProvider.notifier).ajouter(_planche());

  final routeur = creerRouteurApplication();
  routeur.go('/resultat-planche');

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
    'affiche les etoiles et le detail par emotion, evaluee ou non',
    (WidgetTester tester) async {
      await _monter(tester);

      expect(find.byIcon(Icons.star), findsNWidgets(3));
      expect(
        find.text(Textes.detailEmotionResultat(
          emotionLibelle: Textes.emotionJoieLibelle,
          trouvees: 2,
          total: 2,
          score: 100,
          evaluee: true,
        )),
        findsOneWidget,
      );
      expect(
        find.text(Textes.detailEmotionResultat(
          emotionLibelle: Textes.emotionTristesseLibelle,
          trouvees: 0,
          total: 1,
          score: 0,
          evaluee: false,
        )),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'Nouvelle planche route vers le choix de planche',
    (WidgetTester tester) async {
      await _monter(tester);

      await tester.tap(find.text(Textes.boutonNouvellePlanche));
      await tester.pumpAndSettle();

      expect(find.text(Textes.titreChoixPlanche), findsOneWidget);
    },
  );

  testWidgets(
    'Terminer la seance route vers le recapitulatif en session reelle',
    (WidgetTester tester) async {
      await _monter(tester);

      await tester.tap(find.text(Textes.boutonTerminerSeance));
      await tester.pumpAndSettle();

      expect(find.text(Textes.titreRecapitulatifSeance), findsOneWidget);
    },
  );

  testWidgets(
    'en mode demo le bouton de fin propose le retour a l\'accueil',
    (WidgetTester tester) async {
      await _monter(tester, demo: true);

      expect(find.text(Textes.boutonRetourAccueil), findsOneWidget);
      expect(find.text(Textes.boutonTerminerSeance), findsNothing);
    },
  );
}
