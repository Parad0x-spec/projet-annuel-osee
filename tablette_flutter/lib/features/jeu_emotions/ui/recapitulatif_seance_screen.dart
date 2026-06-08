import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/textes.dart';
import '../controller.dart';
import '../domain.dart';

class RecapitulatifSeanceScreen extends ConsumerWidget {
  const RecapitulatifSeanceScreen({super.key});

  void _retourAccueil(BuildContext context, WidgetRef ref) {
    ref.read(sessionEnCoursProvider.notifier).reinitialiser();
    context.go('/');
  }

  String _detailEmotions(PlancheJouee planche) => planche.resultatsParEmotion
      .map((resultat) => Textes.fragmentEmotionRecap(
            emotionLibelle: Textes.libelleEmotion(resultat.emotion),
            trouvees: resultat.nbCiblesTrouvees,
            total: resultat.nbCiblesTotal,
            evaluee: resultat.evaluee,
          ))
      .join(', ');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final planches = ref.watch(planchesSeanceProvider);
    final etatSession = ref.watch(sessionEnCoursProvider);
    final estDemo = etatSession is PatientCharge && etatSession.session.estDemo;

    return Scaffold(
      appBar: AppBar(title: const Text(Textes.titreRecapitulatifSeance)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Expanded(
                child: planches.isEmpty
                    ? Center(
                        child: Text(
                          Textes.messageAucunePartieJouee,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      )
                    : ListView.builder(
                        itemCount: planches.length,
                        itemBuilder: (ctx, i) {
                          final p = planches[i];
                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 6),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 16,
                                horizontal: 20,
                              ),
                              child: Text(
                                Textes.plancheResumeDetaille(
                                  numero: i + 1,
                                  detailEmotions: _detailEmotions(p),
                                  scoreGlobal: p.scoreGlobal,
                                ),
                                style:
                                    Theme.of(context).textTheme.titleMedium,
                              ),
                            ),
                          );
                        },
                      ),
              ),
              const SizedBox(height: 16),
              estDemo
                  ? Center(
                      child: SizedBox(
                        width: 320,
                        height: 96,
                        child: ElevatedButton(
                          onPressed: () => _retourAccueil(context, ref),
                          child: const Text(
                            Textes.boutonRetourAccueil,
                            style: TextStyle(fontSize: 22),
                          ),
                        ),
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: <Widget>[
                        SizedBox(
                          width: 320,
                          height: 96,
                          child: OutlinedButton(
                            onPressed: () => _retourAccueil(context, ref),
                            child: const Text(
                              Textes.boutonQuitterSansTransferer,
                              style: TextStyle(fontSize: 22),
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 320,
                          height: 96,
                          child: ElevatedButton(
                            onPressed: planches.isEmpty
                                ? null
                                : () => context.go('/export-session'),
                            child: const Text(
                              Textes.boutonGenererQrSession,
                              style: TextStyle(fontSize: 22),
                            ),
                          ),
                        ),
                      ],
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
