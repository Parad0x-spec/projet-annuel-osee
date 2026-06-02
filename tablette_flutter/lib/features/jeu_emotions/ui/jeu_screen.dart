import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/textes.dart';
import '../controller.dart';
import '../domain.dart';

class JeuScreen extends ConsumerWidget {
  const JeuScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final etat = ref.watch(controleurPlancheProvider);
    if (etat is! PlancheEnCours) {
      return Scaffold(
        appBar: AppBar(title: const Text(Textes.titreJeu)),
        body: SafeArea(
          child: Center(
            child: SizedBox(
              width: 360,
              height: 96,
              child: ElevatedButton(
                onPressed: () => context.go('/'),
                child: const Text(Textes.boutonRetourAccueil,
                    style: TextStyle(fontSize: 22)),
              ),
            ),
          ),
        ),
      );
    }

    final moteur = etat.moteur;
    final emotionCourante = moteur.emotionCible;

    return Scaffold(
      appBar: AppBar(title: const Text(Textes.titreJeu)),
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                emotionCourante == null
                    ? Textes.consigneSelectionnerEmotion
                    : Textes.consigneTrouverEmotion(
                        Textes.libelleEmotion(emotionCourante),
                      ),
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
            ),
            Wrap(
              spacing: 8,
              children: emotionsOrdonnees.map((emotion) {
                final selectionnee = emotion == emotionCourante;
                return ChoiceChip(
                  label: Text(
                    '${Textes.libelleEmotion(emotion)} '
                    '${moteur.nbCiblesTrouvees(emotion)}/'
                    '${moteur.nbCiblesTotal(emotion)}',
                  ),
                  selected: selectionnee,
                  onSelected: (_) => ref
                      .read(controleurPlancheProvider.notifier)
                      .changerEmotionCible(emotion),
                );
              }).toList(),
            ),
            Expanded(
              child: GestureDetector(
                key: const Key('jeu-canvas'),
                behavior: HitTestBehavior.opaque,
                onTapDown: (details) {
                  ref.read(controleurPlancheProvider.notifier).taper(
                        details.localPosition.dx.round(),
                        details.localPosition.dy.round(),
                      );
                },
                child: Center(
                  child: Image.asset(
                    moteur.planche.cheminAsset,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: <Widget>[
                  SizedBox(
                    width: 240,
                    height: 80,
                    child: OutlinedButton(
                      onPressed: () => context.go('/transition-partie'),
                      child: const Text(
                        Textes.boutonArreter,
                        style: TextStyle(fontSize: 22),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 240,
                    height: 80,
                    child: ElevatedButton(
                      onPressed: () {
                        ref
                            .read(controleurPlancheProvider.notifier)
                            .terminerPlanche(emotionsOrdonnees);
                        context.go('/transition-partie');
                      },
                      child: const Text(
                        Textes.boutonJaiFini,
                        style: TextStyle(fontSize: 22),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
