import 'package:flutter_test/flutter_test.dart';

import 'package:tablette_flutter/features/jeu_emotions/data.dart';
import 'package:tablette_flutter/features/jeu_emotions/domain.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('chargerPlanche', () {
    test('charge planche_1 reelle via rootBundle', () async {
      final planche = await chargerPlanche(1);
      expect(planche.cheminAsset, 'assets/planches/planche_1.jpg');
      expect(planche.largeur, 1536);
      expect(planche.hauteur, 912);
      expect(planche.personnages, hasLength(53));
      for (final perso in planche.personnages) {
        expect(emotionsValides, contains(perso.emotion));
      }
    });

    test('comptages par emotion sur planche_1', () async {
      final planche = await chargerPlanche(1);
      expect(planche.nombreCiblesPourEmotion(emotionJoie), 14);
      expect(planche.nombreCiblesPourEmotion(emotionColere), 7);
      expect(planche.nombreCiblesPourEmotion(emotionTristesse), 15);
      expect(planche.nombreCiblesPourEmotion(emotionPeur), 17);
    });

    test('charge les 4 planches sans erreur', () async {
      for (var i = 1; i <= 4; i++) {
        final planche = await chargerPlanche(i);
        expect(planche.personnages, isNotEmpty);
        for (final emotion in emotionsValides) {
          expect(
            planche.nombreCiblesPourEmotion(emotion),
            greaterThan(0),
            reason: 'planche $i devrait avoir au moins 1 cible $emotion',
          );
        }
      }
    });
  });
}
