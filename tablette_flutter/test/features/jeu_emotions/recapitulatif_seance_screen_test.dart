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

Partie _partie({
  required int numeroPlanche,
  required String emotion,
  required int score,
}) =>
    Partie(
      emotionCible: emotion,
      numeroPlanche: numeroPlanche,
      nbCiblesTotal: 4,
      nbCiblesTrouvees: 3,
      nbFauxPositifs: 0,
      nbCiblesRatees: 1,
      tempsTotalMs: 30000,
      modeFin: ModeFin.termineeBouton,
      score: score,
    );

Future<ProviderContainer> _monter(
  WidgetTester tester,
  List<Partie> parties, {
  bool avecPatient = true,
}) async {
  final container = ProviderContainer();
  addTearDown(container.dispose);
  if (avecPatient) {
    container.read(sessionEnCoursProvider.notifier).charger(_patient);
  }
  for (final p in parties) {
    container.read(partiesSeanceProvider.notifier).ajouter(p);
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
  testWidgets('liste chaque partie avec son resume', (WidgetTester tester) async {
    await _monter(tester, <Partie>[
      _partie(numeroPlanche: 1, emotion: emotionJoie, score: 80),
      _partie(numeroPlanche: 3, emotion: emotionColere, score: 55),
    ]);

    expect(
      find.text(
        Textes.partieResume(
          numero: 1,
          numeroPlanche: 1,
          emotionLibelle: Textes.emotionJoieLibelle,
          score: 80,
        ),
      ),
      findsOneWidget,
    );
    expect(
      find.text(
        Textes.partieResume(
          numero: 2,
          numeroPlanche: 3,
          emotionLibelle: Textes.emotionColereLibelle,
          score: 55,
        ),
      ),
      findsOneWidget,
    );
  });

  testWidgets(
    'bouton Generer le QR de seance route vers /export-session',
    (WidgetTester tester) async {
      await _monter(tester, <Partie>[
        _partie(numeroPlanche: 1, emotion: emotionJoie, score: 80),
      ]);

      await tester.tap(find.text(Textes.boutonGenererQrSession));
      await tester.pump();
      await tester.pump();

      expect(find.text(Textes.titreExportSession), findsOneWidget);
    },
  );

  testWidgets(
    'bouton Generer desactive si aucune partie',
    (WidgetTester tester) async {
      await _monter(tester, const <Partie>[]);

      final bouton = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, Textes.boutonGenererQrSession),
      );
      expect(bouton.onPressed, isNull);
      expect(find.text(Textes.messageAucunePartieJouee), findsOneWidget);
    },
  );

  testWidgets(
    'bouton Quitter sans transferer reinitialise la session et revient a l\'accueil',
    (WidgetTester tester) async {
      final container = await _monter(tester, <Partie>[
        _partie(numeroPlanche: 1, emotion: emotionJoie, score: 80),
      ]);

      await tester.tap(find.text(Textes.boutonQuitterSansTransferer));
      await tester.pumpAndSettle();

      expect(find.text(Textes.titreAccueil), findsOneWidget);
      expect(
        container.read(sessionEnCoursProvider),
        isA<AucunPatientCharge>(),
      );
      expect(container.read(partiesSeanceProvider), isEmpty);
    },
  );
}
