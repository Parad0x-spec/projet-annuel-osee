import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tablette_flutter/app/router.dart';
import 'package:tablette_flutter/core/textes.dart';
import 'package:tablette_flutter/features/jeu_emotions/controller.dart';
import 'package:tablette_flutter/features/jeu_emotions/domain.dart';

Partie _partieAvecScore(int score) => Partie(
      emotionCible: emotionJoie,
      numeroPlanche: 1,
      nbCiblesTotal: 4,
      nbCiblesTrouvees: 2,
      nbFauxPositifs: 0,
      nbCiblesRatees: 2,
      tempsTotalMs: 20000,
      modeFin: ModeFin.termineeBouton,
      score: score,
    );

Future<ProviderContainer> _monterAvecPartie(
  WidgetTester tester,
  Partie partie, {
  bool demo = false,
}) async {
  final container = ProviderContainer();
  addTearDown(container.dispose);
  if (demo) {
    container.read(sessionEnCoursProvider.notifier).chargerDemo();
  }
  container.read(partiesSeanceProvider.notifier).ajouter(partie);

  final routeur = creerRouteurApplication();
  routeur.go('/transition-partie');

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
  testWidgets('score 30 -> 1 etoile et message une-etoile',
      (WidgetTester tester) async {
    await _monterAvecPartie(tester, _partieAvecScore(30));

    expect(find.byIcon(Icons.star), findsOneWidget);
    expect(find.byIcon(Icons.star_border), findsNWidgets(2));
    expect(find.text(Textes.messageEncouragementUneEtoile), findsOneWidget);
  });

  testWidgets('score 60 -> 2 etoiles et message deux-etoiles',
      (WidgetTester tester) async {
    await _monterAvecPartie(tester, _partieAvecScore(60));

    expect(find.byIcon(Icons.star), findsNWidgets(2));
    expect(find.byIcon(Icons.star_border), findsOneWidget);
    expect(find.text(Textes.messageEncouragementDeuxEtoiles), findsOneWidget);
  });

  testWidgets('score 90 -> 3 etoiles et message trois-etoiles',
      (WidgetTester tester) async {
    await _monterAvecPartie(tester, _partieAvecScore(90));

    expect(find.byIcon(Icons.star), findsNWidgets(3));
    expect(find.byIcon(Icons.star_border), findsNothing);
    expect(find.text(Textes.messageEncouragementTroisEtoiles), findsOneWidget);
  });

  testWidgets('bouton Nouvelle partie route vers configuration-partie',
      (WidgetTester tester) async {
    await _monterAvecPartie(tester, _partieAvecScore(50));

    await tester.tap(find.text(Textes.boutonNouvellePartie));
    await tester.pumpAndSettle();

    expect(find.text(Textes.titreConfigurationPartie), findsOneWidget);
  });

  testWidgets('bouton Terminer la seance route vers le recapitulatif',
      (WidgetTester tester) async {
    await _monterAvecPartie(tester, _partieAvecScore(50));

    await tester.tap(find.text(Textes.boutonTerminerSeance));
    await tester.pumpAndSettle();

    expect(find.text(Textes.titreRecapitulatifSeance), findsOneWidget);
  });

  testWidgets(
      'en mode demo propose Retour accueil au lieu de Terminer la seance',
      (WidgetTester tester) async {
    final container =
        await _monterAvecPartie(tester, _partieAvecScore(50), demo: true);

    expect(find.text(Textes.boutonTerminerSeance), findsNothing);
    expect(find.text(Textes.boutonNouvellePartie), findsOneWidget);

    await tester.tap(find.text(Textes.boutonRetourAccueil));
    await tester.pumpAndSettle();

    expect(find.text(Textes.titreAccueil), findsOneWidget);
    expect(container.read(sessionEnCoursProvider), isA<AucunPatientCharge>());
    expect(container.read(partiesSeanceProvider), isEmpty);
  });

  testWidgets('sans partie affiche le message dedie',
      (WidgetTester tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final routeur = creerRouteurApplication();
    routeur.go('/transition-partie');

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(routerConfig: routeur),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(Textes.messageAucunePartieJouee), findsOneWidget);
  });
}
