import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tablette_flutter/app/router.dart';
import 'package:tablette_flutter/core/textes.dart';
import 'package:tablette_flutter/features/jeu_emotions/controller.dart';
import 'package:tablette_flutter/features/jeu_emotions/domain.dart';

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
    'le bouton Mode demo est present sur l\'accueil',
    (WidgetTester tester) async {
      await _monterAccueil(tester);
      expect(find.text(Textes.boutonModeDemo), findsOneWidget);
    },
  );

  testWidgets(
    'un clic sur Mode demo charge le patient DEMO et va a la configuration',
    (WidgetTester tester) async {
      final container = await _monterAccueil(tester);

      await tester.tap(find.text(Textes.boutonModeDemo));
      await tester.pumpAndSettle();

      final etat = container.read(sessionEnCoursProvider);
      expect(etat, isA<PatientCharge>());
      final session = (etat as PatientCharge).session;
      expect(session.estDemo, isTrue);
      expect(session.patient.patientInitiales, 'DEMO');

      expect(find.text(Textes.titreChoixPlanche), findsOneWidget);
    },
  );

  testWidgets(
    'un patient charge via le vrai flux n\'est pas en mode demo',
    (WidgetTester tester) async {
      final container = await _monterAccueil(tester);

      container.read(sessionEnCoursProvider.notifier).charger(
            const PayloadCreationPatient(
              patientId: 'id-123',
              patientInitiales: 'MD',
              niveauDemande: 3,
            ),
          );

      final etat = container.read(sessionEnCoursProvider) as PatientCharge;
      expect(etat.session.estDemo, isFalse);
    },
  );
}
