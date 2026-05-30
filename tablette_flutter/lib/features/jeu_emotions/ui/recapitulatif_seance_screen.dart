import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/textes.dart';
import '../controller.dart';

class RecapitulatifSeanceScreen extends ConsumerWidget {
  const RecapitulatifSeanceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final parties = ref.watch(partiesSeanceProvider);
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
                child: parties.isEmpty
                    ? Center(
                        child: Text(
                          Textes.messageAucunePartieJouee,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      )
                    : ListView.builder(
                        itemCount: parties.length,
                        itemBuilder: (ctx, i) {
                          final p = parties[i];
                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 6),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 16,
                                horizontal: 20,
                              ),
                              child: Text(
                                Textes.partieResume(
                                  numero: i + 1,
                                  numeroPlanche: p.numeroPlanche,
                                  emotionLibelle:
                                      Textes.libelleEmotion(p.emotionCible),
                                  score: p.score,
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: <Widget>[
                  SizedBox(
                    width: 320,
                    height: 96,
                    child: OutlinedButton(
                      onPressed: () {
                        ref
                            .read(sessionEnCoursProvider.notifier)
                            .reinitialiser();
                        context.go('/');
                      },
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
                      onPressed: (parties.isEmpty || estDemo)
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
