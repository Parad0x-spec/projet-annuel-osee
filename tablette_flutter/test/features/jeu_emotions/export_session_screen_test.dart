import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qr_flutter/qr_flutter.dart';

import 'package:tablette_flutter/app/router.dart';
import 'package:tablette_flutter/core/qr_envelope.dart';
import 'package:tablette_flutter/core/textes.dart';
import 'package:tablette_flutter/features/jeu_emotions/controller.dart';
import 'package:tablette_flutter/features/jeu_emotions/domain.dart';

const _patient = PayloadCreationPatient(
  patientId: 'id-123',
  patientInitiales: 'MD',
  niveauDemande: 3,
);

const _enveloppeFactice = EnveloppeQr(
  chargeUtileBase64: 'donnees-session-test',
  enveloppeJSON: '{}',
);

Future<ProviderContainer> _monterExport(WidgetTester tester) async {
  final container = ProviderContainer(
    overrides: [
      exportSessionProvider.overrideWith((ref) async => _enveloppeFactice),
    ],
  );
  addTearDown(container.dispose);
  container.read(sessionEnCoursProvider.notifier).charger(_patient);

  final routeur = creerRouteurApplication();
  routeur.go('/export-session');

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
  testWidgets('affiche le QR, la consigne et les initiales du patient',
      (WidgetTester tester) async {
    await _monterExport(tester);

    expect(find.byType(QrImageView), findsOneWidget);
    expect(find.text(Textes.consigneExportSession), findsOneWidget);
    expect(find.text(Textes.sessionPourInitiales('MD')), findsOneWidget);
    expect(find.text(Textes.boutonTermineRetourAccueil), findsOneWidget);
  });

  testWidgets('le bouton de fin efface la session et revient a l\'accueil',
      (WidgetTester tester) async {
    final container = await _monterExport(tester);

    await tester.ensureVisible(find.text(Textes.boutonTermineRetourAccueil));
    await tester.pumpAndSettle();
    await tester.tap(find.text(Textes.boutonTermineRetourAccueil));
    await tester.pumpAndSettle();

    expect(find.text(Textes.titreAccueil), findsOneWidget);
    expect(container.read(sessionEnCoursProvider), isA<AucunPatientCharge>());
  });
}
