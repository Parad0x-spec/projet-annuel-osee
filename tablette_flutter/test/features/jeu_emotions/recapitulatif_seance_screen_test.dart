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

PlancheJouee _planche({
  required int numeroPlanche,
  required int scoreGlobal,
}) =>
    PlancheJouee(
      numeroPlanche: numeroPlanche,
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
          nbCiblesTotal: 4,
          nbCiblesTrouvees: 3,
          nbFauxPositifs: 0,
          score: 75,
          evaluee: true,
        ),
        ResultatEmotion(
          emotion: 'tristesse',
          nbCiblesTotal: 2,
          nbCiblesTrouvees: 2,
          nbFauxPositifs: 0,
          score: 100,
          evaluee: true,
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
  WidgetTester tester,
  List<PlancheJouee> planches, {
  bool avecPatient = true,
  bool demo = false,
}) async {
  final container = ProviderContainer();
  addTearDown(container.dispose);
  if (demo) {
    container.read(sessionEnCoursProvider.notifier).chargerDemo();
  } else if (avecPatient) {
    container.read(sessionEnCoursProvider.notifier).charger(_patient);
  }
  for (final p in planches) {
    container.read(planchesSeanceProvider.notifier).ajouter(p);
  }

  final routeur = creerRouteurApplication();
  routeur.go('/recapitulatif-seance');

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
  testWidgets('liste chaque planche avec le detail par emotion et le score',
      (WidgetTester tester) async {
    await _monter(tester, <PlancheJouee>[
      _planche(numeroPlanche: 1, scoreGlobal: 80),
      _planche(numeroPlanche: 3, scoreGlobal: 55),
    ]);

    expect(
      find.text(
        'Planche 1 — Joie 2/2, Colère 3/4, Tristesse 2/2, '
        'Peur non évaluée — score global 80 / 100',
      ),
      findsOneWidget,
    );
    expect(
      find.text(
        'Planche 2 — Joie 2/2, Colère 3/4, Tristesse 2/2, '
        'Peur non évaluée — score global 55 / 100',
      ),
      findsOneWidget,
    );
  });

  testWidgets(
    'bouton Generer le QR de seance route vers /export-session',
    (WidgetTester tester) async {
      await _monter(tester, <PlancheJouee>[
        _planche(numeroPlanche: 1, scoreGlobal: 80),
      ]);

      await tester.tap(find.text(Textes.boutonGenererQrSession));
      await tester.pump();
      await tester.pump();

      expect(find.text(Textes.titreExportSession), findsOneWidget);
    },
  );

  testWidgets(
    'bouton Generer desactive si aucune planche',
    (WidgetTester tester) async {
      await _monter(tester, const <PlancheJouee>[]);

      final bouton = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, Textes.boutonGenererQrSession),
      );
      expect(bouton.onPressed, isNull);
      expect(find.text(Textes.messageAucunePartieJouee), findsOneWidget);
    },
  );

  testWidgets(
    'en mode demo pas de generation QR mais un bouton Retour accueil',
    (WidgetTester tester) async {
      final container = await _monter(
        tester,
        <PlancheJouee>[_planche(numeroPlanche: 1, scoreGlobal: 80)],
        demo: true,
      );

      final etat = container.read(sessionEnCoursProvider) as PatientCharge;
      expect(etat.session.estDemo, isTrue);

      expect(find.text(Textes.boutonGenererQrSession), findsNothing);
      expect(find.text(Textes.boutonRetourAccueil), findsOneWidget);

      await tester.tap(find.text(Textes.boutonRetourAccueil));
      await tester.pumpAndSettle();

      expect(find.text(Textes.titreAccueil), findsOneWidget);
      expect(container.read(sessionEnCoursProvider), isA<AucunPatientCharge>());
      expect(container.read(planchesSeanceProvider), isEmpty);
    },
  );

  testWidgets(
    'en session reelle avec planches le bouton Generer est actif',
    (WidgetTester tester) async {
      await _monter(
        tester,
        <PlancheJouee>[_planche(numeroPlanche: 1, scoreGlobal: 80)],
      );

      final bouton = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, Textes.boutonGenererQrSession),
      );
      expect(bouton.onPressed, isNotNull);
    },
  );

  testWidgets(
    'Quitter sans transferer reinitialise la session et revient a l\'accueil',
    (WidgetTester tester) async {
      final container = await _monter(tester, <PlancheJouee>[
        _planche(numeroPlanche: 1, scoreGlobal: 80),
      ]);

      await tester.tap(find.text(Textes.boutonQuitterSansTransferer));
      await tester.pumpAndSettle();

      expect(find.text(Textes.titreAccueil), findsOneWidget);
      expect(container.read(sessionEnCoursProvider), isA<AucunPatientCharge>());
      expect(container.read(planchesSeanceProvider), isEmpty);
    },
  );
}
