import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tablette_flutter/features/jeu_emotions/controller.dart';
import 'package:tablette_flutter/features/jeu_emotions/domain.dart';

const _planche = Planche(
  cheminAsset: 'assets/planches/planche_1.jpg',
  largeur: 1000,
  hauteur: 1000,
  personnages: <PersonnageAnnotation>[
    PersonnageAnnotation(x: 100, y: 100, rayon: 30, emotion: 'joie'),
    PersonnageAnnotation(x: 200, y: 100, rayon: 30, emotion: 'joie'),
    PersonnageAnnotation(x: 100, y: 200, rayon: 30, emotion: 'colere'),
    PersonnageAnnotation(x: 300, y: 300, rayon: 30, emotion: 'tristesse'),
  ],
);

class _HorlogeFactice {
  int _t = 0;
  int call() => _t;
  void avancerDe(int ms) {
    _t += ms;
  }
}

MoteurPlanche _moteur({_HorlogeFactice? horloge}) {
  final h = horloge ?? _HorlogeFactice();
  return MoteurPlanche(
    planche: _planche,
    numeroPlanche: 1,
    horlogeMs: h.call,
  );
}

void main() {
  group('MoteurPlanche - initialisation', () {
    test('compteurs a zero et total par emotion correct', () {
      final m = _moteur();
      expect(m.emotionCible, isNull);
      expect(m.nbCiblesTotal('joie'), 2);
      expect(m.nbCiblesTotal('colere'), 1);
      expect(m.nbCiblesTotal('tristesse'), 1);
      expect(m.nbCiblesTotal('peur'), 0);
      for (final emotion in emotionsOrdonnees) {
        expect(m.nbCiblesTrouvees(emotion), 0);
        expect(m.nbFauxPositifs(emotion), 0);
      }
    });
  });

  group('MoteurPlanche - taper sans emotion selectionnee', () {
    test('un tap est sans effet tant qu aucune emotion n est choisie', () {
      final m = _moteur();
      final r = m.taper(100, 100);
      expect(r, isA<ResultatAucun>());
      expect(m.nbCiblesTrouvees('joie'), 0);
      expect(m.taps, isEmpty);
    });
  });

  group('MoteurPlanche - changerEmotionCible', () {
    test('change l emotion courante et conserve les cibles deja trouvees', () {
      final m = _moteur();
      m.changerEmotionCible('joie');
      m.taper(100, 100);
      m.taper(200, 100);
      expect(m.nbCiblesTrouvees('joie'), 2);

      m.changerEmotionCible('colere');
      expect(m.emotionCible, 'colere');
      expect(m.nbCiblesTrouvees('joie'), 2);
      expect(m.nbCiblesTrouvees('colere'), 0);
    });
  });

  group('MoteurPlanche - taper', () {
    test('tap sur l emotion courante : cible trouvee, tap correct', () {
      final m = _moteur();
      m.changerEmotionCible('joie');
      final r = m.taper(100, 100);
      expect(r, isA<ResultatCible>());
      expect((r as ResultatCible).dejaTrouvee, isFalse);
      expect(m.nbCiblesTrouvees('joie'), 1);
      expect(m.taps.single.correct, isTrue);
      expect(m.taps.single.emotionTouchee, 'joie');
    });

    test(
        'tap sur une autre emotion : faux positif attribue a l emotion courante',
        () {
      final m = _moteur();
      m.changerEmotionCible('joie');
      final r = m.taper(100, 200);
      expect(r, isA<ResultatFauxPositif>());
      expect(m.nbFauxPositifs('joie'), 1);
      expect(m.nbFauxPositifs('colere'), 0);
      expect(m.nbCiblesTrouvees('colere'), 0);
      expect(m.taps.single.correct, isFalse);
      expect(m.taps.single.emotionTouchee, 'colere');
    });

    test('tap dans le vide : aucun effet, tap sans emotion', () {
      final m = _moteur();
      m.changerEmotionCible('joie');
      final r = m.taper(500, 500);
      expect(r, isA<ResultatAucun>());
      expect(m.nbFauxPositifs('joie'), 0);
      expect(m.nbCiblesTrouvees('joie'), 0);
      expect(m.taps.single.emotionTouchee, isNull);
      expect(m.taps.single.correct, isFalse);
    });

    test('re-tap sur une cible deja trouvee : pas de double comptage', () {
      final m = _moteur();
      m.changerEmotionCible('joie');
      m.taper(100, 100);
      final r = m.taper(100, 100);
      expect(r, isA<ResultatCible>());
      expect((r as ResultatCible).dejaTrouvee, isTrue);
      expect(m.nbCiblesTrouvees('joie'), 1);
      expect(m.taps, hasLength(2));
    });

    test('horodatage des taps relatif au debut et croissant', () {
      final h = _HorlogeFactice();
      final m = _moteur(horloge: h);
      m.changerEmotionCible('joie');
      h.avancerDe(500);
      m.taper(100, 100);
      h.avancerDe(1500);
      m.taper(200, 100);
      expect(m.taps[0].timestampMs, 500);
      expect(m.taps[1].timestampMs, 2000);
    });
  });

  group('MoteurPlanche - indicesFauxPositifs par emotion', () {
    test('aucun faux positif au depart pour toutes les emotions', () {
      final m = _moteur();
      for (final emotion in emotionsOrdonnees) {
        expect(m.indicesFauxPositifs(emotion), isEmpty);
      }
    });

    test(
        'scenario soutenance : rouge local a l emotion, vert global apres trouvaille',
        () {
      final m = _moteur();

      m.changerEmotionCible('joie');
      m.taper(100, 200);
      expect(m.indicesFauxPositifs('joie'), <int>{2});

      m.changerEmotionCible('tristesse');
      expect(m.indicesFauxPositifs('tristesse'), isEmpty);

      m.changerEmotionCible('joie');
      expect(m.indicesFauxPositifs('joie'), <int>{2});

      m.changerEmotionCible('colere');
      final r = m.taper(100, 200);
      expect(r, isA<ResultatCible>());
      expect(m.indicesTrouves('colere'), contains(2));
    });

    test(
        'le compteur de score compte chaque tap fautif mais une seule croix affichee',
        () {
      final m = _moteur();
      m.changerEmotionCible('joie');
      m.taper(100, 200);
      m.taper(100, 200);
      m.taper(100, 200);
      expect(m.nbFauxPositifs('joie'), 3);
      expect(m.indicesFauxPositifs('joie'), <int>{2});
    });

    test('un faux positif n affecte pas les autres emotions', () {
      final m = _moteur();
      m.changerEmotionCible('joie');
      m.taper(100, 200);
      expect(m.indicesFauxPositifs('joie'), <int>{2});
      expect(m.indicesFauxPositifs('colere'), isEmpty);
      expect(m.indicesFauxPositifs('tristesse'), isEmpty);
      expect(m.indicesFauxPositifs('peur'), isEmpty);
    });
  });

  group('MoteurPlanche - resteDesCibles et toutesEmotionsCompletes', () {
    test('vrai au depart car aucune cible trouvee', () {
      final m = _moteur();
      expect(m.resteDesCibles(), isTrue);
      expect(m.toutesEmotionsCompletes(), isFalse);
    });

    test('reste des cibles tant qu une emotion est incomplete', () {
      final m = _moteur();
      m.changerEmotionCible('joie');
      m.taper(100, 100);
      m.taper(200, 100);
      m.changerEmotionCible('colere');
      m.taper(100, 200);
      expect(m.resteDesCibles(), isTrue);
      expect(m.toutesEmotionsCompletes(), isFalse);
    });

    test('complet quand toutes les cibles de toutes les emotions sont trouvees',
        () {
      final m = _moteur();
      m.changerEmotionCible('joie');
      m.taper(100, 100);
      m.taper(200, 100);
      m.changerEmotionCible('colere');
      m.taper(100, 200);
      m.changerEmotionCible('tristesse');
      m.taper(300, 300);
      expect(m.resteDesCibles(), isFalse);
      expect(m.toutesEmotionsCompletes(), isTrue);
    });
  });

  group('MoteurPlanche - resultatPourEmotion', () {
    test('cas nominal sans faute : score 100', () {
      final m = _moteur();
      m.changerEmotionCible('joie');
      m.taper(100, 100);
      m.taper(200, 100);
      final r = m.resultatPourEmotion('joie', evaluee: true);
      expect(r.nbCiblesTotal, 2);
      expect(r.nbCiblesTrouvees, 2);
      expect(r.nbFauxPositifs, 0);
      expect(r.score, 100);
      expect(r.evaluee, isTrue);
    });

    test('faux positifs reduisent le score selon la penalite', () {
      final m = _moteur();
      m.changerEmotionCible('joie');
      m.taper(100, 100);
      m.taper(200, 100);
      m.taper(100, 200);
      final r = m.resultatPourEmotion('joie', evaluee: true);
      expect(r.nbFauxPositifs, 1);
      expect(r.score, 95);
    });

    test('emotion sans cible : T+R=0 donne score 0', () {
      final m = _moteur();
      final r = m.resultatPourEmotion('peur', evaluee: false);
      expect(r.nbCiblesTotal, 0);
      expect(r.score, 0);
      expect(r.evaluee, isFalse);
    });
  });

  group('MoteurPlanche - terminerPlanche', () {
    test('planche complete : toutes les emotions retenues, score global moyenne',
        () {
      final m = _moteur();
      m.changerEmotionCible('joie');
      m.taper(100, 100);
      m.taper(200, 100);
      m.changerEmotionCible('colere');
      m.taper(100, 200);
      m.changerEmotionCible('tristesse');
      m.taper(300, 300);

      final planche = m.terminerPlanche(emotionsOrdonnees);
      expect(planche.numeroPlanche, 1);
      expect(planche.resultatsParEmotion.map((r) => r.emotion).toList(),
          emotionsOrdonnees);
      expect(planche.resultatsParEmotion.every((r) => r.evaluee), isTrue);
      final scores = {
        for (final r in planche.resultatsParEmotion) r.emotion: r.score
      };
      expect(scores['joie'], 100);
      expect(scores['colere'], 100);
      expect(scores['tristesse'], 100);
      expect(scores['peur'], 0);
      expect(planche.scoreGlobal, 75);
    });

    test('planche incomplete : seules les emotions cochees comptent', () {
      final m = _moteur();
      m.changerEmotionCible('joie');
      m.taper(100, 100);
      m.taper(200, 100);
      m.changerEmotionCible('colere');
      m.taper(100, 200);

      final planche = m.terminerPlanche(<String>['joie', 'colere']);
      final parEmotion = {
        for (final r in planche.resultatsParEmotion) r.emotion: r
      };
      expect(parEmotion['joie']!.evaluee, isTrue);
      expect(parEmotion['colere']!.evaluee, isTrue);
      expect(parEmotion['tristesse']!.evaluee, isFalse);
      expect(parEmotion['peur']!.evaluee, isFalse);
      expect(planche.scoreGlobal, 100);
    });

    test('aucune emotion retenue : score global 0', () {
      final m = _moteur();
      final planche = m.terminerPlanche(const <String>[]);
      expect(planche.resultatsParEmotion.every((r) => !r.evaluee), isTrue);
      expect(planche.scoreGlobal, 0);
    });
  });

  group('ControleurPlanche - accumulation d une seance', () {
    test('terminerPlanche ajoute chaque planche jouee a la seance', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(controleurPlancheProvider.notifier);

      notifier.chargerMoteur(_moteur());
      notifier.changerEmotionCible('joie');
      notifier.taper(100, 100);
      notifier.terminerPlanche(emotionsOrdonnees);

      notifier.chargerMoteur(_moteur());
      notifier.changerEmotionCible('colere');
      notifier.taper(100, 200);
      notifier.terminerPlanche(emotionsOrdonnees);

      final planches = container.read(planchesSeanceProvider);
      expect(planches, hasLength(2));
      expect(container.read(controleurPlancheProvider), isA<AucunePlanche>());
    });

    test('changerEmotionCible sans planche demarree leve une exception', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      expect(
        () => container
            .read(controleurPlancheProvider.notifier)
            .changerEmotionCible('joie'),
        throwsA(isA<PlancheNonDemarreeException>()),
      );
    });
  });
}
