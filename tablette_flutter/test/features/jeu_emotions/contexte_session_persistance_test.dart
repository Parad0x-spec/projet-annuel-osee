import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:tablette_flutter/app/router.dart';
import 'package:tablette_flutter/core/stockage.dart';
import 'package:tablette_flutter/core/textes.dart';
import 'package:tablette_flutter/features/appairage/controller.dart';
import 'package:tablette_flutter/features/jeu_emotions/controller.dart';
import 'package:tablette_flutter/features/jeu_emotions/data.dart';
import 'package:tablette_flutter/features/jeu_emotions/domain.dart';

const _patient = PayloadCreationPatient(
  patientId: 'id-123',
  patientInitiales: 'MD',
  niveauDemande: 3,
);

Future<({ProviderContainer container, DepotContexteSession depot})>
    _conteneurAvecStockage() async {
  final stockage = await Stockage.ouvrirEnMemoire(databaseFactoryFfi);
  addTearDown(stockage.fermer);
  final container = ProviderContainer(
    overrides: [
      stockageProvider.overrideWith((ref) async => stockage),
    ],
  );
  addTearDown(container.dispose);
  final depot = await container.read(depotContexteSessionProvider.future);
  return (container: container, depot: depot);
}

void main() {
  setUpAll(() {
    sqfliteFfiInit();
  });

  test('charger persiste le contexte du vrai flux avec estDemo false',
      () async {
    final (:container, :depot) = await _conteneurAvecStockage();

    container.read(sessionEnCoursProvider.notifier).charger(_patient);
    await pumpEventQueue();

    final restaure = await depot.lire();
    expect(restaure, isNotNull);
    expect(restaure!.patient.patientId, 'id-123');
    expect(restaure.patient.patientInitiales, 'MD');
    expect(restaure.patient.niveauDemande, 3);
    expect(restaure.estDemo, isFalse);
  });

  test('chargerDemo persiste le contexte DEMO avec estDemo true', () async {
    final (:container, :depot) = await _conteneurAvecStockage();

    container.read(sessionEnCoursProvider.notifier).chargerDemo();
    await pumpEventQueue();

    final restaure = await depot.lire();
    expect(restaure, isNotNull);
    expect(restaure!.patient.patientInitiales, 'DEMO');
    expect(restaure.estDemo, isTrue);
  });

  test('reinitialiser efface le contexte persiste', () async {
    final (:container, :depot) = await _conteneurAvecStockage();

    container.read(sessionEnCoursProvider.notifier).charger(_patient);
    await pumpEventQueue();
    expect(await depot.lire(), isNotNull);

    container.read(sessionEnCoursProvider.notifier).reinitialiser();
    await pumpEventQueue();
    expect(await depot.lire(), isNull);
  });

  test('un contexte initial restaure seede la session en cours', () {
    final container = ProviderContainer(
      overrides: [
        contexteSessionInitialProvider
            .overrideWithValue(const SessionEnCours(_patient)),
      ],
    );
    addTearDown(container.dispose);

    final etat = container.read(sessionEnCoursProvider);
    expect(etat, isA<PatientCharge>());
    expect((etat as PatientCharge).session.patient.patientId, 'id-123');
  });

  testWidgets(
    'au demarrage avec session restauree, ouvre la configuration de partie',
    (WidgetTester tester) async {
      final container = ProviderContainer(
        overrides: [
          contexteSessionInitialProvider
              .overrideWithValue(const SessionEnCours(_patient)),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            routerConfig: creerRouteurApplication(
              initialLocation: '/choix-planche',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(Textes.titreChoixPlanche), findsOneWidget);
    },
  );
}
