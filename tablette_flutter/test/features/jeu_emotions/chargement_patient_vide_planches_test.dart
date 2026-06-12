import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tablette_flutter/features/jeu_emotions/controller.dart';
import 'package:tablette_flutter/features/jeu_emotions/domain.dart';

PlancheJouee _plancheFactice() => const PlancheJouee(
      numeroPlanche: 1,
      resultatsParEmotion: <ResultatEmotion>[],
      scoreGlobal: 50,
    );

void main() {
  test('charger un nouveau patient vide les planches de la seance precedente',
      () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    container.read(planchesSeanceProvider.notifier).ajouter(_plancheFactice());
    expect(container.read(planchesSeanceProvider), isNotEmpty);

    container.read(sessionEnCoursProvider.notifier).charger(
          const PayloadCreationPatient(
            patientId: 'autre-patient',
            patientInitiales: 'AB',
            niveauDemande: 2,
          ),
        );

    expect(container.read(planchesSeanceProvider), isEmpty,
        reason: 'un nouveau patient doit demarrer une seance propre');
  });

  test('chargerDemo vide aussi les planches en cours', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    container.read(planchesSeanceProvider.notifier).ajouter(_plancheFactice());
    expect(container.read(planchesSeanceProvider), isNotEmpty);

    container.read(sessionEnCoursProvider.notifier).chargerDemo();

    expect(container.read(planchesSeanceProvider), isEmpty);
  });
}
