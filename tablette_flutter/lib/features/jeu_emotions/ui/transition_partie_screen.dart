import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/textes.dart';
import '../controller.dart';
import '../domain.dart';

class TransitionPartieScreen extends ConsumerWidget {
  const TransitionPartieScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final parties = ref.watch(partiesSeanceProvider);
    return Scaffold(
      appBar: AppBar(title: const Text(Textes.titreTransitionPartie)),
      body: SafeArea(
        child: Center(
          child: parties.isEmpty
              ? _vueAucunePartie(context)
              : _vueResultat(context, parties.last),
        ),
      ),
    );
  }

  Widget _vueAucunePartie(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          Textes.messageAucunePartieJouee,
          style: Theme.of(context).textTheme.titleLarge,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        SizedBox(
          width: 360,
          height: 96,
          child: ElevatedButton(
            onPressed: () => context.go('/'),
            child: const Text(Textes.boutonRetourAccueil,
                style: TextStyle(fontSize: 22)),
          ),
        ),
      ],
    );
  }

  Widget _vueResultat(BuildContext context, Partie partie) {
    final etoiles = calculerEtoiles(partie.score);
    final message = _messageSelonEtoiles(etoiles);
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          _LigneEtoiles(nombre: etoiles),
          const SizedBox(height: 24),
          Text(
            message,
            style: Theme.of(context).textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 48),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
              SizedBox(
                width: 320,
                height: 96,
                child: OutlinedButton(
                  onPressed: () => context.go('/recapitulatif-seance'),
                  child: const Text(
                    Textes.boutonTerminerSeance,
                    style: TextStyle(fontSize: 22),
                  ),
                ),
              ),
              SizedBox(
                width: 320,
                height: 96,
                child: ElevatedButton(
                  onPressed: () => context.go('/configuration-partie'),
                  child: const Text(
                    Textes.boutonNouvellePartie,
                    style: TextStyle(fontSize: 22),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _messageSelonEtoiles(int etoiles) {
    switch (etoiles) {
      case 3:
        return Textes.messageEncouragementTroisEtoiles;
      case 2:
        return Textes.messageEncouragementDeuxEtoiles;
      default:
        return Textes.messageEncouragementUneEtoile;
    }
  }
}

class _LigneEtoiles extends StatelessWidget {
  final int nombre;
  const _LigneEtoiles({required this.nombre});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List<Widget>.generate(3, (i) {
        final remplie = i < nombre;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Icon(
            remplie ? Icons.star : Icons.star_border,
            color: Colors.amber,
            size: 96,
          ),
        );
      }),
    );
  }
}
