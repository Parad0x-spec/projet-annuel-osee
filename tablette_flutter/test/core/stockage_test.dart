import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:tablette_flutter/core/stockage.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
  });

  group('Stockage SQLite', () {
    late Stockage stockage;

    setUp(() async {
      stockage = await Stockage.ouvrirEnMemoire(databaseFactoryFfi);
    });

    tearDown(() async {
      await stockage.fermer();
    });

    test('base initialisee est vide', () async {
      expect(await stockage.compterAppairages(), 0);
      expect(await stockage.lireAppairageActuel(), isNull);
    });

    test('insertion puis lecture retourne les memes valeurs', () async {
      final pcPub = List<int>.generate(32, (i) => i);
      final tabPriv = List<int>.generate(32, (i) => i + 100);
      final tabPub = List<int>.generate(32, (i) => i + 200);
      final date = DateTime.utc(2026, 5, 8, 9, 0, 0);

      await stockage.insererAppairage(
        pairingId: 'paire-001',
        pcPub: pcPub,
        tabPriv: tabPriv,
        tabPub: tabPub,
        dateAppairage: date,
      );

      final ligne = await stockage.lireAppairageActuel();
      expect(ligne, isNotNull);
      expect(ligne!['pairing_id'], 'paire-001');
      expect(ligne['pc_pub'], equals(Uint8List.fromList(pcPub)));
      expect(ligne['tab_priv'], equals(Uint8List.fromList(tabPriv)));
      expect(ligne['tab_pub'], equals(Uint8List.fromList(tabPub)));
      expect(ligne['date_appairage'], '2026-05-08T09:00:00.000Z');
    });

    test('lireAppairageActuel retourne le plus recent', () async {
      await stockage.insererAppairage(
        pairingId: 'ancien',
        pcPub: List<int>.filled(32, 1),
        tabPriv: List<int>.filled(32, 2),
        tabPub: List<int>.filled(32, 3),
        dateAppairage: DateTime.utc(2026, 1, 1),
      );
      await stockage.insererAppairage(
        pairingId: 'recent',
        pcPub: List<int>.filled(32, 4),
        tabPriv: List<int>.filled(32, 5),
        tabPub: List<int>.filled(32, 6),
        dateAppairage: DateTime.utc(2026, 5, 1),
      );

      final ligne = await stockage.lireAppairageActuel();
      expect(ligne!['pairing_id'], 'recent');
      expect(await stockage.compterAppairages(), 2);
    });
  });
}
