import 'package:flutter_test/flutter_test.dart';

import 'package:tablette_flutter/features/jeu_emotions/domain.dart';

void main() {
  group('estDansZone', () {
    const perso = PersonnageAnnotation(
      x: 100,
      y: 200,
      rayon: 30,
      emotion: 'joie',
    );

    test('tap au centre exact -> dans la zone', () {
      expect(estDansZone(100, 200, perso), isTrue);
    });

    test('tap sur le bord exact (distance = rayon) -> dans la zone', () {
      expect(estDansZone(130, 200, perso), isTrue);
      expect(estDansZone(100, 230, perso), isTrue);
    });

    test('tap juste au-dela du rayon -> hors zone', () {
      expect(estDansZone(131, 200, perso), isFalse);
      expect(estDansZone(100, 231, perso), isFalse);
    });

    test('tap loin -> hors zone', () {
      expect(estDansZone(500, 500, perso), isFalse);
    });
  });

  group('calculerScore', () {
    test('cas nominal : T=10, R=0, F=0 -> 100', () {
      expect(calculerScore(T: 10, R: 0, F: 0), 100);
    });

    test('cas avec faux positifs : T=10, R=0, F=2 -> 90', () {
      expect(calculerScore(T: 10, R: 0, F: 2), 90);
    });

    test('cas avec cibles ratees : T=5, R=5, F=0 -> 50', () {
      expect(calculerScore(T: 5, R: 5, F: 0), 50);
    });

    test('borne basse : score negatif ramene a 0', () {
      expect(calculerScore(T: 1, R: 0, F: 100), 0);
    });

    test('T+R = 0 -> 0 par convention', () {
      expect(calculerScore(T: 0, R: 0, F: 0), 0);
      expect(calculerScore(T: 0, R: 0, F: 5), 0);
    });

    test('arrondi a l\'entier le plus proche : T=1, R=2, F=0 -> 33', () {
      expect(calculerScore(T: 1, R: 2, F: 0), 33);
    });

    test('arrondi a l\'entier le plus proche : T=2, R=1, F=0 -> 67', () {
      expect(calculerScore(T: 2, R: 1, F: 0), 67);
    });
  });

  group('calculerEtoiles', () {
    test('score 0 -> 1 etoile', () {
      expect(calculerEtoiles(0), 1);
    });

    test('score 40 -> 1 etoile (borne sup une etoile)', () {
      expect(calculerEtoiles(40), 1);
    });

    test('score 41 -> 2 etoiles (entree dans deux etoiles)', () {
      expect(calculerEtoiles(41), 2);
    });

    test('score 75 -> 2 etoiles (borne sup deux etoiles)', () {
      expect(calculerEtoiles(75), 2);
    });

    test('score 76 -> 3 etoiles (entree dans trois etoiles)', () {
      expect(calculerEtoiles(76), 3);
    });

    test('score 100 -> 3 etoiles', () {
      expect(calculerEtoiles(100), 3);
    });
  });

  group('modeFinVersString', () {
    test('mappe les trois modes vers les chaines attendues', () {
      expect(modeFinVersString(ModeFin.termineeBouton), 'bouton');
      expect(modeFinVersString(ModeFin.termineeAuto), 'auto');
      expect(modeFinVersString(ModeFin.abandonnee), 'abandon');
    });
  });

  group('emotionsValides', () {
    test('contient exactement les 4 emotions du concept definitif', () {
      expect(emotionsValides, <String>{'joie', 'colere', 'tristesse', 'peur'});
    });
  });

  group('Partie.versJson', () {
    test('serialise tous les champs dans un ordre canonique', () {
      const partie = Partie(
        emotionCible: 'colere',
        numeroPlanche: 2,
        nbCiblesTotal: 4,
        nbCiblesTrouvees: 3,
        nbFauxPositifs: 1,
        nbCiblesRatees: 1,
        tempsTotalMs: 45000,
        modeFin: ModeFin.termineeBouton,
        score: 70,
      );
      final json = partie.versJson();
      expect(json.keys.toList(), <String>[
        'emotion_cible',
        'numero_planche',
        'nb_cibles_total',
        'nb_cibles_trouvees',
        'nb_faux_positifs',
        'nb_cibles_ratees',
        'temps_total_ms',
        'mode_fin',
        'score',
      ]);
      expect(json['emotion_cible'], 'colere');
      expect(json['numero_planche'], 2);
      expect(json['nb_cibles_total'], 4);
      expect(json['nb_cibles_trouvees'], 3);
      expect(json['nb_faux_positifs'], 1);
      expect(json['nb_cibles_ratees'], 1);
      expect(json['temps_total_ms'], 45000);
      expect(json['mode_fin'], 'bouton');
      expect(json['score'], 70);
    });
  });
}
