import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/textes.dart';
import '../controller.dart';
import '../data.dart';

class ChoixPlancheScreen extends ConsumerStatefulWidget {
  const ChoixPlancheScreen({super.key});

  @override
  ConsumerState<ChoixPlancheScreen> createState() => _ChoixPlancheScreenState();
}

class _ChoixPlancheScreenState extends ConsumerState<ChoixPlancheScreen> {
  int? _planche;
  bool _lancementEnCours = false;

  static const List<int> _numerosPlanches = <int>[1, 2, 3, 4];

  Future<void> _lancer() async {
    final planche = _planche;
    if (planche == null) return;
    setState(() => _lancementEnCours = true);
    try {
      await ref
          .read(controleurPlancheProvider.notifier)
          .demarrerPlanche(planche);
      if (!mounted) return;
      context.go('/jeu');
    } on PlancheInvalideException {
      if (!mounted) return;
      setState(() => _lancementEnCours = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(Textes.erreurChargementPlanche)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final etatSession = ref.watch(sessionEnCoursProvider);
    if (etatSession is! PatientCharge) {
      return Scaffold(
        appBar: AppBar(title: const Text(Textes.titreChoixPlanche)),
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

    final pretALancer = _planche != null && !_lancementEnCours;

    return Scaffold(
      appBar: AppBar(title: const Text(Textes.titreChoixPlanche)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(
                Textes.consignePlanche,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: _numerosPlanches.map((n) {
                  final selectionne = _planche == n;
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: SizedBox(
                        height: 96,
                        child: ElevatedButton(
                          key: Key('planche-$n'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: selectionne
                                ? Colors.blue
                                : Colors.grey.shade200,
                            foregroundColor:
                                selectionne ? Colors.white : Colors.black,
                          ),
                          onPressed: () => setState(() => _planche = n),
                          child: Text(
                            Textes.libellePlanche(n),
                            style: const TextStyle(fontSize: 22),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const Spacer(),
              Center(
                child: SizedBox(
                  width: 360,
                  height: 96,
                  child: ElevatedButton(
                    onPressed: pretALancer ? _lancer : null,
                    child: _lancementEnCours
                        ? const CircularProgressIndicator()
                        : const Text(
                            Textes.boutonLancerPlanche,
                            style: TextStyle(fontSize: 22),
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
