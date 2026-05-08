import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tablette_flutter/app/accueil_screen.dart';
import 'package:tablette_flutter/core/textes.dart';
import 'package:tablette_flutter/features/appairage/controller.dart';

void main() {
  testWidgets(
    'AccueilScreen affiche le titre et les trois boutons',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appairageActuelProvider.overrideWith((ref) async => null),
          ],
          child: const MaterialApp(home: AccueilScreen()),
        ),
      );
      await tester.pump();

      expect(find.text(Textes.titreAccueil), findsOneWidget);
      expect(find.text(Textes.boutonNouveauPatient), findsOneWidget);
      expect(find.text(Textes.boutonPatientExistant), findsOneWidget);
      expect(find.text(Textes.boutonParametres), findsOneWidget);
    },
  );
}
