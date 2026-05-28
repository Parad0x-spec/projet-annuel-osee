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
  ],
);

class _HorlogeFactice {
  int _t = 0;
  int call() => _t;
  void avancerDe(int ms) {
    _t += ms;
  }
}

MoteurPartie _moteur({
  String emotion = 'joie',
  _HorlogeFactice? horloge,
}) {
  final h = horloge ?? _HorlogeFactice();
  return MoteurPartie(
    planche: _planche,
    numeroPlanche: 1,
    emotionCible: emotion,
    horlogeMs: h.call,
  );
}

void main() {
  group('MoteurPartie - initialisation', () {
    test('compte les cibles de l\'emotion sur la planche', () {
      final mJoie = _moteur(emotion: 'joie');
      final mColere = _moteur(emotion: 'colere');
      expect(mJoie.nbCiblesTotal, 2);
      expect(mColere.nbCiblesTotal, 1);
      expect(mJoie.nbCiblesTrouvees, 0);
      expect(mJoie.nbFauxPositifs, 0);
      expect(mJoie.toutesCiblesTrouvees, isFalse);
    });
  });

  group('MoteurPartie - taper', () {
    test('tap sur une cible : incremente trouvees, enregistre tap correct', () {
      final m = _moteur(emotion: 'joie');
      final r = m.taper(100, 100);
      expect(r, isA<ResultatCible>());
      expect((r as ResultatCible).dejaTrouvee, isFalse);
      expect(m.nbCiblesTrouvees, 1);
      expect(m.taps, hasLength(1));
      expect(m.taps[0].correct, isTrue);
      expect(m.taps[0].emotionTouchee, 'joie');
    });

    test('tap sur une mauvaise emotion : faux positif, tap incorrect', () {
      final m = _moteur(emotion: 'joie');
      final r = m.taper(100, 200);
      expect(r, isA<ResultatFauxPositif>());
      expect(m.nbFauxPositifs, 1);
      expect(m.nbCiblesTrouvees, 0);
      expect(m.taps[0].correct, isFalse);
      expect(m.taps[0].emotionTouchee, 'colere');
    });

    test('tap dans le vide : aucun, pas de penalite, tap sans emotion', () {
      final m = _moteur(emotion: 'joie');
      final r = m.taper(500, 500);
      expect(r, isA<ResultatAucun>());
      expect(m.nbFauxPositifs, 0);
      expect(m.nbCiblesTrouvees, 0);
      expect(m.taps[0].emotionTouchee, isNull);
      expect(m.taps[0].correct, isFalse);
    });

    test('re-tap sur une cible deja trouvee : pas de double comptage', () {
      final m = _moteur(emotion: 'joie');
      m.taper(100, 100);
      final r = m.taper(100, 100);
      expect(r, isA<ResultatCible>());
      expect((r as ResultatCible).dejaTrouvee, isTrue);
      expect(m.nbCiblesTrouvees, 1);
      expect(m.taps, hasLength(2));
    });

    test('horodatage des taps : relatif au debut, croissant', () {
      final h = _HorlogeFactice();
      final m = _moteur(emotion: 'joie', horloge: h);
      h.avancerDe(500);
      m.taper(100, 100);
      h.avancerDe(1500);
      m.taper(200, 100);
      expect(m.taps[0].timestampMs, 500);
      expect(m.taps[1].timestampMs, 2000);
    });
  });

  group('MoteurPartie - detection fin auto', () {
    test('toutesCiblesTrouvees vrai quand toutes les cibles sont trouvees', () {
      final m = _moteur(emotion: 'joie');
      expect(m.toutesCiblesTrouvees, isFalse);
      m.taper(100, 100);
      expect(m.toutesCiblesTrouvees, isFalse);
      m.taper(200, 100);
      expect(m.toutesCiblesTrouvees, isTrue);
    });
  });

  group('MoteurPartie - terminer', () {
    test('mode bouton : produit une Partie avec le bon modeFin et le score', () {
      final h = _HorlogeFactice();
      final m = _moteur(emotion: 'joie', horloge: h);
      m.taper(100, 100);
      h.avancerDe(10000);
      final partie = m.terminer(ModeFin.termineeBouton);
      expect(partie.modeFin, ModeFin.termineeBouton);
      expect(partie.numeroPlanche, 1);
      expect(partie.emotionCible, 'joie');
      expect(partie.nbCiblesTotal, 2);
      expect(partie.nbCiblesTrouvees, 1);
      expect(partie.nbCiblesRatees, 1);
      expect(partie.nbFauxPositifs, 0);
      expect(partie.tempsTotalMs, 10000);
      expect(partie.score, 50);
    });

    test('mode abandon : score reflete l\'etat au moment de l\'abandon', () {
      final m = _moteur(emotion: 'joie');
      final partie = m.terminer(ModeFin.abandonnee);
      expect(partie.modeFin, ModeFin.abandonnee);
      expect(partie.nbCiblesTrouvees, 0);
      expect(partie.nbCiblesRatees, 2);
      expect(partie.score, 0);
    });

    test('mode auto : score 100 quand tout est trouve sans faute', () {
      final m = _moteur(emotion: 'joie');
      m.taper(100, 100);
      m.taper(200, 100);
      final partie = m.terminer(ModeFin.termineeAuto);
      expect(partie.modeFin, ModeFin.termineeAuto);
      expect(partie.score, 100);
      expect(partie.nbCiblesRatees, 0);
    });

    test('faux positifs reduisent le score selon la penalite', () {
      final m = _moteur(emotion: 'joie');
      m.taper(100, 100);
      m.taper(200, 100);
      m.taper(100, 200);
      final partie = m.terminer(ModeFin.termineeBouton);
      expect(partie.nbFauxPositifs, 1);
      expect(partie.score, 95);
    });
  });
}
