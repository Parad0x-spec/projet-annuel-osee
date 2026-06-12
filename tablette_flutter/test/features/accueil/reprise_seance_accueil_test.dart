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

Future<ProviderContainer> _monterAccueil(WidgetTester tester) async {
  final container = ProviderContainer();
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(routerConfig: creerRouteurApplication()),
    ),
  );
  await tester.pumpAndSettle();
  return container;
}

void main() {
  testWidgets(
    'sans patient charge, l\'accueil ne propose pas de reprendre',
    (WidgetTester tester) async {
      await _monterAccueil(tester);
      expect(find.text(Textes.boutonReprendreSeance), findsNothing);
    },
  );

  testWidgets(
    'avec un patient charge, l\'accueil affiche le patient en cours et permet de reprendre',
    (WidgetTester tester) async {
      final container = await _monterAccueil(tester);

      container.read(sessionEnCoursProvider.notifier).charger(_patient);
      await tester.pumpAndSettle();

      expect(find.text(Textes.patientEnCours('MD')), findsOneWidget);
      expect(find.text(Textes.boutonReprendreSeance), findsOneWidget);

      await tester.tap(find.text(Textes.boutonReprendreSeance));
      await tester.pumpAndSettle();

      expect(find.text(Textes.titreChoixPlanche), findsOneWidget);
      expect(container.read(sessionEnCoursProvider), isA<PatientCharge>());
    },
  );
}
