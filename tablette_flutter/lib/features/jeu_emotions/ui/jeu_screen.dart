import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/textes.dart';
import '../controller.dart';
import '../domain.dart';

class JeuScreen extends ConsumerStatefulWidget {
  const JeuScreen({super.key});

  @override
  ConsumerState<JeuScreen> createState() => _JeuScreenState();
}

class _JeuScreenState extends ConsumerState<JeuScreen> {
  final TransformationController _transformController =
      TransformationController();
  final List<_FeedbackRouge> _feedbacksRouges = <_FeedbackRouge>[];
  Planche? _plancheAjustee;

  static const Duration _dureeFeedbackRouge = Duration(seconds: 1);

  void _ajusterAuViewport(Planche planche, Size viewport) {
    if (_plancheAjustee == planche) return;
    if (viewport.width <= 0 || viewport.height <= 0) return;
    final echelleFit = _echelleFit(planche, viewport);
    final largeurAffichee = planche.largeur * echelleFit;
    final hauteurAffichee = planche.hauteur * echelleFit;
    final translationX = (viewport.width - largeurAffichee) / 2;
    final translationY = (viewport.height - hauteurAffichee) / 2;
    _transformController.value = Matrix4(
      echelleFit, 0, 0, 0,
      0, echelleFit, 0, 0,
      0, 0, 1, 0,
      translationX, translationY, 0, 1,
    );
    _plancheAjustee = planche;
  }

  double _echelleFit(Planche planche, Size viewport) {
    final echelleLargeur = viewport.width / planche.largeur;
    final echelleHauteur = viewport.height / planche.hauteur;
    return echelleLargeur < echelleHauteur ? echelleLargeur : echelleHauteur;
  }

  @override
  void dispose() {
    _transformController.dispose();
    super.dispose();
  }

  void _terminerEnMode(ModeFin mode) {
    ref.read(controleurPartieProvider.notifier).terminer(mode);
    if (!mounted) return;
    context.go('/transition-partie');
  }

  Future<void> _confirmerArret() async {
    final confirme = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(Textes.titreConfirmationArret),
        content: const Text(Textes.messageConfirmationArret),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text(Textes.boutonAnnulerArret),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text(Textes.boutonConfirmerArret),
          ),
        ],
      ),
    );
    if (confirme == true && mounted) {
      _terminerEnMode(ModeFin.abandonnee);
    }
  }

  void _onTapDown(TapDownDetails details, MoteurPartie moteur) {
    final x = details.localPosition.dx.round();
    final y = details.localPosition.dy.round();
    final resultat = ref.read(controleurPartieProvider.notifier).taper(x, y);
    switch (resultat) {
      case ResultatAucun():
        break;
      case ResultatCible():
        break;
      case ResultatFauxPositif(:final indexPersonnage):
        final perso = moteur.planche.personnages[indexPersonnage];
        final feedback = _FeedbackRouge(perso: perso);
        setState(() => _feedbacksRouges.add(feedback));
        Timer(_dureeFeedbackRouge, () {
          if (!mounted) return;
          setState(() => _feedbacksRouges.remove(feedback));
        });
    }
    if (moteur.toutesCiblesTrouvees) {
      _terminerEnMode(ModeFin.termineeAuto);
    }
  }

  @override
  Widget build(BuildContext context) {
    final etat = ref.watch(controleurPartieProvider);
    if (etat is! PartieEnCours) {
      return Scaffold(
        appBar: AppBar(title: const Text(Textes.titreJeu)),
        body: SafeArea(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  Textes.messageAucunPatientCharge,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 24),
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
            ),
          ),
        ),
      );
    }

    final moteur = etat.moteur;
    final planche = moteur.planche;

    return Scaffold(
      appBar: AppBar(title: const Text(Textes.titreJeu)),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                Textes.consigneTrouverEmotion(
                  Textes.libelleEmotion(moteur.emotionCible),
                ),
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
            ),
            Expanded(
              child: ClipRect(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final viewport = constraints.biggest;
                    final echelleFit = _echelleFit(planche, viewport);
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (!mounted) return;
                      _ajusterAuViewport(planche, viewport);
                    });
                    return InteractiveViewer(
                      transformationController: _transformController,
                      constrained: false,
                      minScale: echelleFit * 0.8,
                      maxScale: 4.0,
                      boundaryMargin: const EdgeInsets.all(double.infinity),
                      child: SizedBox(
                        width: planche.largeur.toDouble(),
                        height: planche.hauteur.toDouble(),
                        child: GestureDetector(
                          key: const Key('jeu-canvas'),
                          behavior: HitTestBehavior.opaque,
                          onTapDown: (d) => _onTapDown(d, moteur),
                          child: Stack(
                            children: <Widget>[
                              Positioned.fill(
                                child: Image.asset(
                                  planche.cheminAsset,
                                  fit: BoxFit.contain,
                                ),
                              ),
                              ..._feedbacksVerts(moteur),
                              ..._feedbacksRougesWidgets(),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
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
                      onPressed: _confirmerArret,
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
                      onPressed: () => _terminerEnMode(ModeFin.termineeBouton),
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

  Iterable<Widget> _feedbacksVerts(MoteurPartie moteur) {
    return moteur.indicesTrouves.map((index) {
      final perso = moteur.planche.personnages[index];
      return _MarqueurFeedback(
        x: perso.x,
        y: perso.y,
        rayon: perso.rayon,
        couleur: Colors.green,
        icone: Icons.check,
        key: ValueKey<String>('feedback-vert-$index'),
      );
    });
  }

  Iterable<Widget> _feedbacksRougesWidgets() {
    return _feedbacksRouges.map((f) => _MarqueurFeedback(
          x: f.perso.x,
          y: f.perso.y,
          rayon: f.perso.rayon,
          couleur: Colors.red,
          icone: Icons.close,
          key: ValueKey<int>(f.id),
        ));
  }
}

class _FeedbackRouge {
  static int _seq = 0;
  final int id;
  final PersonnageAnnotation perso;
  _FeedbackRouge({required this.perso}) : id = ++_seq;
}

class _MarqueurFeedback extends StatelessWidget {
  final int x;
  final int y;
  final int rayon;
  final Color couleur;
  final IconData icone;

  const _MarqueurFeedback({
    required this.x,
    required this.y,
    required this.rayon,
    required this.couleur,
    required this.icone,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final taille = rayon * 2.0;
    return Positioned(
      left: (x - rayon).toDouble(),
      top: (y - rayon).toDouble(),
      width: taille,
      height: taille,
      child: IgnorePointer(
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: couleur.withValues(alpha: 0.35),
            border: Border.all(color: couleur, width: 3),
          ),
          child: Icon(icone, color: Colors.white, size: rayon.toDouble()),
        ),
      ),
    );
  }
}
