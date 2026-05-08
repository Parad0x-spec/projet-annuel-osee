import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qr_flutter/qr_flutter.dart';

import 'package:tablette_flutter/core/textes.dart';
import 'package:tablette_flutter/features/appairage/controller.dart';
import 'package:tablette_flutter/features/appairage/domain.dart';
import 'package:tablette_flutter/features/appairage/ui/appairage_screen.dart';

class _ControleurAppairageReussiStub extends ControleurAppairage {
  @override
  EtatAppairage build() => const AppairageReussi(
    chargeUtileQRRetour: 'donnees-test-base64',
    pairingId: 'test-pairing-id',
  );
}

void main() {
  testWidgets(
    'AppairageScreen affiche la consigne et le bouton de scan en etat initial',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(child: MaterialApp(home: AppairageScreen())),
      );
      await tester.pump();

      expect(find.text(Textes.titreAppairage), findsOneWidget);
      expect(find.text(Textes.consigneAppairage), findsOneWidget);
      expect(find.text(Textes.boutonScannerQRPC), findsOneWidget);
    },
  );

  testWidgets(
    'AppairageScreen affiche le QR de retour, le message au praticien et le bouton de fin apres succes',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            controleurAppairageProvider.overrideWith(
              _ControleurAppairageReussiStub.new,
            ),
          ],
          child: const MaterialApp(home: AppairageScreen()),
        ),
      );
      await tester.pump();

      expect(find.text(Textes.consignePraticienScanner), findsOneWidget);
      expect(find.byType(QrImageView), findsOneWidget);
      expect(find.text(Textes.boutonAppairageTermine), findsOneWidget);
    },
  );
}
