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
  final Set<int> _indicesRouges = <int>{};
  Planche? _plancheAjustee;

  @override
  void dispose() {
    _transformController.dispose();
    super.dispose();
  }

  double _echelleFit(Planche planche, Size viewport) {
    final echelleLargeur = viewport.width / planche.largeur;
    final echelleHauteur = viewport.height / planche.hauteur;
    return echelleLargeur < echelleHauteur ? echelleLargeur : echelleHauteur;
  }

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

  void _onTapDown(TapDownDetails details) {
    final x = details.localPosition.dx.round();
    final y = details.localPosition.dy.round();
    final resultat = ref.read(controleurPlancheProvider.notifier).taper(x, y);
    if (resultat is ResultatFauxPositif) {
      setState(() => _indicesRouges.add(resultat.indexPersonnage));
    }
  }

  Future<void> _terminerPlanche(MoteurPlanche moteur) async {
    final List<String>? retenues;
    if (moteur.toutesEmotionsCompletes()) {
      retenues = emotionsOrdonnees;
    } else {
      retenues = await _choisirEmotionsAEvaluer(moteur);
    }
    if (retenues == null || !mounted) return;
    ref.read(controleurPlancheProvider.notifier).terminerPlanche(retenues);
    if (!mounted) return;
    context.go('/resultat-planche');
  }

  Future<List<String>?> _choisirEmotionsAEvaluer(MoteurPlanche moteur) {
    final selection = <String, bool>{
      for (final emotion in emotionsOrdonnees)
        emotion: moteur.nbCiblesTrouvees(emotion) > 0,
    };
    return showDialog<List<String>>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setStateDialog) => AlertDialog(
          title: const Text(Textes.titreSelectionEmotions),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Text(Textes.consigneSelectionEmotions),
              const SizedBox(height: 8),
              ...emotionsOrdonnees.map(
                (emotion) => CheckboxListTile(
                  key: Key('check-$emotion'),
                  value: selection[emotion],
                  title: Text(
                    '${Textes.libelleEmotion(emotion)}  '
                    '${Textes.compteurEmotion(moteur.nbCiblesTrouvees(emotion), moteur.nbCiblesTotal(emotion))}',
                  ),
                  onChanged: (valeur) =>
                      setStateDialog(() => selection[emotion] = valeur ?? false),
                ),
              ),
            ],
          ),
          actions: <Widget>[
            ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(
                emotionsOrdonnees
                    .where((emotion) => selection[emotion] == true)
                    .toList(),
              ),
              child: const Text(Textes.boutonValiderSelection),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmerArret(bool estDemo) async {
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
    if (confirme != true || !mounted) return;
    ref.read(controleurPlancheProvider.notifier).abandonnerPlanche();
    if (!mounted) return;
    if (estDemo) {
      ref.read(sessionEnCoursProvider.notifier).reinitialiser();
      context.go('/');
    } else {
      context.go('/recapitulatif-seance');
    }
  }

  @override
  Widget build(BuildContext context) {
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
    final etatSession = ref.watch(sessionEnCoursProvider);
    final estDemo =
        etatSession is PatientCharge && etatSession.session.estDemo;

    return Scaffold(
      appBar: AppBar(title: const Text(Textes.titreJeu)),
      body: SafeArea(
        child: Row(
          children: <Widget>[
            Expanded(child: _zonePlanche(moteur)),
            SizedBox(
              width: 220,
              child: _barreLaterale(moteur, estDemo),
            ),
          ],
        ),
      ),
    );
  }

  Widget _zonePlanche(MoteurPlanche moteur) {
    final planche = moteur.planche;
    return ClipRect(
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
                onTapDown: _onTapDown,
                child: Stack(
                  children: <Widget>[
                    Positioned.fill(
                      child: Image.asset(
                        planche.cheminAsset,
                        fit: BoxFit.contain,
                      ),
                    ),
                    ..._marqueursVerts(moteur),
                    ..._marqueursRouges(moteur),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _barreLaterale(MoteurPlanche moteur, bool estDemo) {
    final emotionCourante = moteur.emotionCible;
    final reste = moteur.resteDesCibles();
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            emotionCourante == null
                ? Textes.consigneSelectionnerEmotion
                : Textes.consigneTrouverEmotion(
                    Textes.libelleEmotion(emotionCourante),
                  ),
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView(
              children: emotionsOrdonnees
                  .map((emotion) => _tuileEmotion(moteur, emotion))
                  .toList(),
            ),
          ),
          const SizedBox(height: 8),
          if (reste)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  const Icon(Icons.warning_amber,
                      color: Colors.orange, size: 18),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      Textes.messageResteDesCibles,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          SizedBox(
            height: 64,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: reste ? Colors.orange : Colors.green,
                foregroundColor: Colors.white,
              ),
              onPressed: () => _terminerPlanche(moteur),
              child: const Text(Textes.boutonJaiFini,
                  style: TextStyle(fontSize: 20)),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 56,
            child: OutlinedButton(
              onPressed: () => _confirmerArret(estDemo),
              child: const Text(Textes.boutonArreter,
                  style: TextStyle(fontSize: 18)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tuileEmotion(MoteurPlanche moteur, String emotion) {
    final total = moteur.nbCiblesTotal(emotion);
    final trouvees = moteur.nbCiblesTrouvees(emotion);
    final complete = total > 0 && trouvees == total;
    final selectionnee = moteur.emotionCible == emotion;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Material(
        color: selectionnee ? Colors.blue.shade100 : Colors.grey.shade100,
        shape: RoundedRectangleBorder(
          side: BorderSide(
            color: selectionnee ? Colors.blue : Colors.transparent,
            width: 3,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: InkWell(
          key: Key('emotion-tile-$emotion'),
          borderRadius: BorderRadius.circular(12),
          onTap: () => ref
              .read(controleurPlancheProvider.notifier)
              .changerEmotionCible(emotion),
          child: Container(
            constraints: const BoxConstraints(minHeight: 80),
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Text(
                  Textes.libelleEmotion(emotion),
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Row(
                  children: <Widget>[
                    Text(
                      Textes.compteurEmotion(trouvees, total),
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: complete ? Colors.green : Colors.black87,
                      ),
                    ),
                    if (complete)
                      const Padding(
                        padding: EdgeInsets.only(left: 6),
                        child: Icon(Icons.check_circle, color: Colors.green),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Iterable<Widget> _marqueursVerts(MoteurPlanche moteur) {
    final widgets = <Widget>[];
    for (final emotion in emotionsOrdonnees) {
      for (final index in moteur.indicesTrouves(emotion)) {
        final perso = moteur.planche.personnages[index];
        widgets.add(_MarqueurFeedback(
          x: perso.x,
          y: perso.y,
          rayon: perso.rayon,
          couleur: Colors.green,
          icone: Icons.check,
          key: ValueKey<String>('feedback-vert-$index'),
        ));
      }
    }
    return widgets;
  }

  Iterable<Widget> _marqueursRouges(MoteurPlanche moteur) {
    final indicesVerts = <int>{
      for (final emotion in emotionsOrdonnees) ...moteur.indicesTrouves(emotion),
    };
    return _indicesRouges
        .where((index) => !indicesVerts.contains(index))
        .map((index) {
      final perso = moteur.planche.personnages[index];
      return _MarqueurFeedback(
        x: perso.x,
        y: perso.y,
        rayon: perso.rayon,
        couleur: Colors.red,
        icone: Icons.close,
        key: ValueKey<String>('feedback-rouge-$index'),
      );
    });
  }
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
