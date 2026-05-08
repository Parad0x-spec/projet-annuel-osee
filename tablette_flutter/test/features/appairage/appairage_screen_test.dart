import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tablette_flutter/core/textes.dart';
import 'package:tablette_flutter/features/appairage/ui/appairage_screen.dart';

void main() {
  testWidgets(
    'AppairageScreen affiche la consigne et le bouton de scan en etat initial',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(home: AppairageScreen()),
        ),
      );
      await tester.pump();

      expect(find.text(Textes.titreAppairage), findsOneWidget);
      expect(find.text(Textes.consigneAppairage), findsOneWidget);
      expect(find.text(Textes.boutonScannerQRPC), findsOneWidget);
    },
  );
}
