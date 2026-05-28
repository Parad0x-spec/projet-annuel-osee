import 'package:flutter_test/flutter_test.dart';

import 'package:tablette_flutter/features/jeu_emotions/data.dart';

void main() {
  group('parserPlanche', () {
    test('parse correctement un JSON minimal valide', () {
      const json = '''
{
  "planche": "ancien_nom.jpg",
  "largeur": 1536,
  "hauteur": 912,
  "personnages": [
    {"x": 100, "y": 200, "rayon": 30, "emotion": "joie"},
    {"x": 500, "y": 400, "rayon": 25, "emotion": "colere"}
  ]
}
''';
      final planche = parserPlanche(numeroPlanche: 3, contenuJson: json);
      expect(planche.cheminAsset, 'assets/planches/planche_3.jpg');
      expect(planche.largeur, 1536);
      expect(planche.hauteur, 912);
      expect(planche.personnages, hasLength(2));
      expect(planche.personnages[0].emotion, 'joie');
      expect(planche.personnages[1].rayon, 25);
    });

    test('ignore le champ "planche" du JSON et utilise le numero pour l\'asset',
        () {
      const json = '''
{
  "planche": "n_importe_quoi.jpg",
  "largeur": 100,
  "hauteur": 100,
  "personnages": []
}
''';
      final planche = parserPlanche(numeroPlanche: 1, contenuJson: json);
      expect(planche.cheminAsset, 'assets/planches/planche_1.jpg');
    });

    test('rejette un JSON syntaxiquement invalide', () {
      expect(
        () => parserPlanche(numeroPlanche: 1, contenuJson: 'pas du json {'),
        throwsA(isA<PlancheInvalideException>()),
      );
    });

    test('rejette une emotion hors emotionsValides', () {
      const json = '''
{
  "largeur": 100,
  "hauteur": 100,
  "personnages": [
    {"x": 10, "y": 10, "rayon": 5, "emotion": "surprise"}
  ]
}
''';
      expect(
        () => parserPlanche(numeroPlanche: 1, contenuJson: json),
        throwsA(
          isA<PlancheInvalideException>().having(
            (e) => e.message,
            'message',
            contains('emotion invalide'),
          ),
        ),
      );
    });

    test('rejette des coordonnees hors planche', () {
      const json = '''
{
  "largeur": 100,
  "hauteur": 100,
  "personnages": [
    {"x": 150, "y": 50, "rayon": 5, "emotion": "joie"}
  ]
}
''';
      expect(
        () => parserPlanche(numeroPlanche: 1, contenuJson: json),
        throwsA(
          isA<PlancheInvalideException>().having(
            (e) => e.message,
            'message',
            contains('hors planche'),
          ),
        ),
      );
    });

    test('rejette une largeur absente ou non-int', () {
      const json = '''
{
  "largeur": "grosse",
  "hauteur": 100,
  "personnages": []
}
''';
      expect(
        () => parserPlanche(numeroPlanche: 1, contenuJson: json),
        throwsA(isA<PlancheInvalideException>()),
      );
    });

    test('rejette un rayon nul ou negatif', () {
      const json = '''
{
  "largeur": 100,
  "hauteur": 100,
  "personnages": [
    {"x": 10, "y": 10, "rayon": 0, "emotion": "joie"}
  ]
}
''';
      expect(
        () => parserPlanche(numeroPlanche: 1, contenuJson: json),
        throwsA(isA<PlancheInvalideException>()),
      );
    });

    test('rejette un personnage non-objet', () {
      const json = '''
{
  "largeur": 100,
  "hauteur": 100,
  "personnages": ["pas un objet"]
}
''';
      expect(
        () => parserPlanche(numeroPlanche: 1, contenuJson: json),
        throwsA(isA<PlancheInvalideException>()),
      );
    });
  });
}
