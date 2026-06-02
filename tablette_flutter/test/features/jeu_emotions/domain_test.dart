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

  group('emotionsValides et emotionsOrdonnees', () {
    test('contiennent exactement les 4 emotions du concept definitif', () {
      expect(emotionsValides, <String>{'joie', 'colere', 'tristesse', 'peur'});
      expect(emotionsOrdonnees, <String>[
        'joie',
        'colere',
        'tristesse',
        'peur',
      ]);
    });
  });

  group('calculerScoreGlobal', () {
    test('moyenne arrondie des scores des emotions evaluees', () {
      const resultats = <ResultatEmotion>[
        ResultatEmotion(
          emotion: 'joie',
          nbCiblesTotal: 2,
          nbCiblesTrouvees: 2,
          nbFauxPositifs: 0,
          score: 100,
          evaluee: true,
        ),
        ResultatEmotion(
          emotion: 'colere',
          nbCiblesTotal: 2,
          nbCiblesTrouvees: 1,
          nbFauxPositifs: 0,
          score: 50,
          evaluee: true,
        ),
      ];
      expect(calculerScoreGlobal(resultats), 75);
    });

    test('liste vide donne 0 par convention', () {
      expect(calculerScoreGlobal(const <ResultatEmotion>[]), 0);
    });
  });

  group('ResultatEmotion.versJson', () {
    test('serialise tous les champs dans un ordre canonique', () {
      const resultat = ResultatEmotion(
        emotion: 'colere',
        nbCiblesTotal: 4,
        nbCiblesTrouvees: 3,
        nbFauxPositifs: 1,
        score: 70,
        evaluee: true,
      );
      final json = resultat.versJson();
      expect(json.keys.toList(), <String>[
        'emotion',
        'nb_cibles_total',
        'nb_cibles_trouvees',
        'nb_faux_positifs',
        'score',
        'evaluee',
      ]);
      expect(json['emotion'], 'colere');
      expect(json['nb_cibles_total'], 4);
      expect(json['nb_cibles_trouvees'], 3);
      expect(json['nb_faux_positifs'], 1);
      expect(json['score'], 70);
      expect(json['evaluee'], isTrue);
    });
  });

  group('PlancheJouee.versJson', () {
    test('serialise numero, score global et resultats par emotion', () {
      const planche = PlancheJouee(
        numeroPlanche: 2,
        scoreGlobal: 80,
        resultatsParEmotion: <ResultatEmotion>[
          ResultatEmotion(
            emotion: 'joie',
            nbCiblesTotal: 2,
            nbCiblesTrouvees: 2,
            nbFauxPositifs: 0,
            score: 100,
            evaluee: true,
          ),
        ],
      );
      final json = planche.versJson();
      expect(json.keys.toList(), <String>[
        'numero_planche',
        'score_global',
        'resultats_par_emotion',
      ]);
      expect(json['numero_planche'], 2);
      expect(json['score_global'], 80);
      final resultats = json['resultats_par_emotion'] as List<dynamic>;
      expect(resultats, hasLength(1));
      expect((resultats.first as Map<String, dynamic>)['emotion'], 'joie');
    });
  });
}
