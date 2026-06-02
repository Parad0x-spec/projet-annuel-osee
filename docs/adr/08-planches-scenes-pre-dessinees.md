# ADR-08 - Planches scenes pre-dessinees pour le jeu des emotions

> Note : la section de cet ADR concernant le mode de jeu (une emotion par partie) est superseded par l'ADR-10 qui introduit la navigation libre entre emotions. Le reste de cet ADR, concernant les planches scenes pre-dessinees, leur production, leur annotation et leur format, demeure valide.

## Contexte

La specification initiale du jeu des emotions, redigee avant le sprint 3 et mise a jour apres le recalibrage de l'ADR-07, prevoyait une mecanique de composition de planche a la volee. Le principe etait de stocker une banque de visages individuels (huit variantes par emotion, format PNG transparent) et de composer dynamiquement chaque planche en tirant aleatoirement les visages selon le niveau de difficulte.

Au moment d'attaquer concretement la production des images, une recherche de format plus realiste a fait emerger un autre modele : la planche scene complete pre-dessinee dans le style "Ou est Charlie". Au lieu d'une grille de visages individuels composee a la volee, on dispose d'une image unique illustrant une scene sociale (un parc avec des enfants qui jouent, font la fete, se disputent), dans laquelle de nombreux personnages expriment chacun une emotion. Le patient doit trouver dans la scene les personnages correspondant a la consigne.

L'evaluation du modele a ete faite par la production de plusieurs planches sur ChatGPT (Image-1), avec un prompt detaille decrivant une scene de parc dense. Le resultat est superieur a l'approche grille sur les plans clinique, technique et legal, ce qui motive le changement de cap.

## Decision

Le modele de planches scenes pre-dessinees est retenu pour la premiere version du jeu, celle qui sera presentee a la soutenance et rendue le 15 juin.

Quatre planches sont produites pour cette premiere version. Contrairement a une premiere intention de faire une planche par niveau de difficulte croissante, les quatre planches sont de niveau equivalent. Elles representent toutes les quatre memes emotions et presentent une densite et une complexite comparables. La raison de ce choix est la variete : disposer de quatre scenes differentes de meme niveau permet au praticien de faire tourner les supports pour un meme patient, afin d'eviter que le patient ne memorise l'emplacement des personnages d'une seance a l'autre, et d'eviter la lassitude de toujours jouer sur la meme scene.

Les quatre emotions retenues, presentes sur chacune des quatre planches, sont la joie, la colere, la tristesse et la peur. Ce sont quatre des six emotions universelles identifiees par Paul Ekman. La surprise et le degout, evoquees dans des versions anterieures de la specification, ne sont pas retenues pour cette premiere version. Une evolution future pourra les ajouter.

Chaque planche est produite via le service de generation d'images de ChatGPT a partir d'un prompt detaille en francais, specifiant le contexte (un parc), le nombre approximatif de personnages, la liste des emotions, l'instruction d'expressions faciales tres lisibles et exagerees, et l'absence de bulles BD ou de smileys flottants pour conserver le realisme.

Chaque planche est annotee manuellement par le developpeur du projet. L'annotation consiste a marquer pour chaque personnage ses coordonnees x et y dans l'image, le rayon de sa zone cliquable, et l'emotion qu'il exprime. Cette annotation est stockee dans un fichier JSON associe a la planche. Un outil HTML d'annotation est livre dans outils/annotateur_planche.html pour faciliter ce travail.

Les planches sont au format JPG (et non PNG comme envisage initialement), ce qui reduit le poids des fichiers a environ 800 kilo-octets chacun, adapte a l'embarquement dans l'APK.

## Modele d'usage du jeu

Le choix de la planche et de l'emotion a chercher est fait par le praticien directement sur la tablette, avant de lancer une partie. C'est l'option de configuration cote tablette plutot que cote PC. Ce choix se justifie par le scenario d'usage : le praticien enchaine plusieurs parties au cours d'une seance en changeant de planche et d'emotion, et il serait trop lourd de regenerer un QR depuis le PC a chaque changement. La configuration sur la tablette rend ces changements immediats.

Une partie correspond donc a une planche et une emotion donnees. Le patient cherche tous les personnages de cette emotion sur cette planche. Quand la partie se termine, le praticien peut en relancer une autre avec une planche et une emotion differentes.

Plusieurs parties s'accumulent sur la tablette au cours d'une seance. A la fin de la seance, un seul QR de session est genere, contenant les donnees de toutes les parties jouees. Ce QR unique est scanne par le PC, qui rapatrie l'ensemble des donnees pour mettre a jour le suivi du patient. C'est le principe d'un transfert groupe plutot qu'un QR par partie.

Le niveau_demande transmis dans le QR creation_patient depuis le PC est conserve pour compatibilite et enregistre dans les donnees de seance comme intention du praticien, mais il n'a pas d'effet sur le deroulement du jeu dans cette premiere version, puisque le choix reel se fait sur la tablette.

## Transfert des donnees et granularite

Le transfert des donnees de seance vers le PC utilise le canal QR deja implemente aux taches 11 et 12 du sprint 3. Aucune communication reseau n'est utilisee, conformement a l'ADR-06 sur la souverainete des donnees.

La granularite des donnees transmises est agregee pour cette premiere version. Pour chaque partie, on transmet les statistiques : emotion cible, planche utilisee, nombre de cibles trouvees, nombre de cibles ratees, nombre de faux positifs, temps total de la partie, maniere dont la partie s'est terminee (terminee par le bouton, terminee automatiquement quand toutes les cibles sont trouvees, ou abandonnee), et le score calcule.

Le detail tap par tap (horodatage et coordonnees de chaque clic) est collecte en memoire pendant le jeu mais n'est pas transmis dans le QR. Cette decision est motivee par la capacite limitee d'un QR code : transmettre tous les taps de plusieurs parties depasserait la capacite scannable d'un seul QR. Les agregats suffisent pour l'objectif de suivi de progression longitudinale (tableau et diagramme d'evolution sur plusieurs seances).

Une evolution future pourra rendre l'export adaptatif, c'est-a-dire tenter d'envoyer le detail fin et basculer automatiquement vers l'agrege si la taille depasse la capacite du QR. Cette evolution est documentee comme piste mais hors perimetre de la premiere version, et sera calibree sur des mesures reelles une fois le jeu fonctionnel.

## Justification du changement

Sur le plan clinique, une planche scene reproduit un contexte social riche ou plusieurs enfants interagissent, ce qui est plus proche de la vie reelle et plus transferable qu'une grille de visages hors contexte. Le patient scanne la scene comme il scannerait une cour de recreation.

Sur le plan de la production, une planche scene unique resout par construction le probleme de coherence stylistique entre visages, puisque tous les personnages sont dans la meme image avec le meme style et le meme eclairage. Le travail passe de quarante-huit visages individuels a quatre planches plus leur annotation.

Sur le plan de la propriete intellectuelle et de l'ethique, les personnages sont des illustrations cartoon clairement non realistes, ce qui evite tout risque de droit a l'image ou de confusion avec une personne reelle.

Sur le plan technique, le modele simplifie l'implementation : charger une planche, charger son annotation, afficher l'image, detecter les clics aux coordonnees annotees, comparer l'emotion. Pas de composition aleatoire ni de calcul de densite.

## Consequences

La specification du jeu docs/specs/jeu_emotions.md est refondue en consequence.

La structure des assets devient tablette_flutter/assets/planches/ contenant planche_1.jpg a planche_4.jpg et leurs annotations planche_1.json a planche_4.json.

La logique metier du jeu charge une planche selon le choix du praticien, lit son annotation, et orchestre la partie. L'interface affiche la planche dans un canvas scrollable avec zones cliquables invisibles.

Un ecran de configuration praticien est ajoute sur la tablette pour choisir la planche et l'emotion avant de lancer une partie.

La mise en ligne du code source sur un depot public (GitHub ou equivalent) pour l'evaluation est compatible avec l'ADR-06 : le code source n'est pas une donnee patient. Le depot ne contient que le code, la documentation, les planches (qui sont des assets) et eventuellement des donnees de test factices. Aucune vraie donnee patient n'est versionnee. La base SQLite reelle reste dans le repertoire utilisateur, hors du depot.

Cette decision reste conforme aux ADR precedents. Elle n'introduit aucune nouvelle bibliotheque et ne modifie pas le canal de communication QR existant.
