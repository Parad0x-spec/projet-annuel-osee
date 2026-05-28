# Sprint 3 - Taches 7 a 10 revisitees suite a l'ADR-08

## Objet

Ce document acte la revision des taches 7 a 10 du sprint 3 suite a la decision tracee dans l'ADR-08 de passer aux planches scenes pre-dessinees. Il reflete le modele definitif : quatre planches de niveau equivalent, quatre emotions (joie, colere, tristesse, peur), choix de la planche et de l'emotion par le praticien sur la tablette, accumulation de parties dans une seance et transfert groupe par un seul QR agrege en fin de seance.

Il succede aux specifications correspondantes du plan general docs/sprints/sprint_03.md, qui restent valides pour les autres taches du sprint mais sont ici remplacees pour les taches du jeu.

## Tache 7 - Production et annotation des planches : faite

La tache 7 initiale prevoyait une banque de visages individuels. Elle est remplacee par la production de quatre planches scenes et de leurs annotations, et elle est deja realisee.

Les quatre planches ont ete generees via ChatGPT et annotees manuellement avec l'outil HTML livre dans outils/annotateur_planche.html. Elles sont presentes dans tablette_flutter/assets/planches/ sous les noms planche_1.jpg a planche_4.jpg, chacune accompagnee de son fichier d'annotation planche_1.json a planche_4.json.

Les comptages observes confirment que chaque planche contient les quatre emotions en quantite suffisante pour qu'une consigne sur n'importe quelle emotion ait des cibles a trouver. La combinaison la plus maigre est la tristesse sur la planche 2 avec trois cibles, ce qui reste jouable.

Le pubspec.yaml de la tablette doit etre mis a jour pour declarer ces assets si ce n'est pas deja fait. Le commit correspondant ajoute les huit fichiers au depot.

## Tache 8 - Logique metier du jeu

La tache 8 initiale prevoyait la composition pseudo-aleatoire de planches. Elle devient le chargement et l'exploitation de planches pre-dessinees, avec gestion d'une partie et accumulation des parties dans une seance.

Code a livrer dans tablette_flutter/lib/features/jeu_emotions/.

Dans domain.dart, les types : Planche (chemin asset, largeur, hauteur, liste de PersonnageAnnotation), PersonnageAnnotation (x, y, rayon, emotion), une constante des emotions valides (joie, colere, tristesse, peur), une fonction estDansZone pour la detection de tap par distance euclidienne, un type Partie agregant le resultat d'une partie jouee (emotion cible, numero de planche, nombres de cibles totales, trouvees, ratees, faux positifs, temps total, mode de fin, score), l'adaptation du type Session pour contenir une liste de Partie, et un type Tap pour la collecte memoire non transmise.

Dans data.dart, une fonction de chargement de planche par numero qui lit l'image et parse le JSON via rootBundle, valide les emotions et la coherence des coordonnees, et leve une exception en cas de probleme. La fonction ignore le champ planche du JSON et localise l'image par le numero. L'adaptation de la construction du payload session pour serialiser la liste de Partie en JSON canonique, le reste de la chaine de signature et d'encodage etant deja en place.

Dans controller.dart, l'etat de partie en cours et l'etat de seance, les fonctions de demarrage de partie, de traitement d'un tap, de fin de partie avec calcul de score, et l'adaptation de la fonction d'export pour utiliser la liste reelle de parties. Le calcul de score suit la formule de la spec, borne entre zero et cent, avec gestion du cas ou il n'y a aucune cible.

Une variable de configuration centralisee pour le facteur de penalite des faux positifs et les seuils des etoiles, afin d'ajuster ces parametres sans toucher au code metier.

Tests unitaires sur le parsing, la detection de tap, le calcul de score, la fin de partie et la detection de fin automatique.

Commit propose : "tablette: implementer logique metier du jeu des emotions".

## Tache 9 - Application du niveau_demande : reduite

La tache 9 concernait l'application stricte du niveau_demande recu du PC. Dans le modele definitif, le choix se fait sur la tablette et le niveau_demande n'a plus d'effet sur le gameplay. Il est simplement conserve dans les donnees de seance comme intention du praticien.

Cette tache se reduit donc a s'assurer que le niveau_demande recu dans le message creation_patient est bien stocke et inclus dans la Session exportee, sans logique d'adaptation. C'est essentiellement deja couvert par les taches precedentes.

## Tache 10 - Interface graphique du jeu

La tache 10 initiale prevoyait une grille pseudo-aleatoire. Elle devient un canvas affichant une planche statique avec detection des taps, plus les ecrans de configuration, de transition et de recapitulatif.

Code a livrer dans tablette_flutter/lib/features/jeu_emotions/ui/.

L'ecran de configuration de partie, destine au praticien, permet de choisir une planche parmi les quatre et une emotion parmi les quatre, puis de lancer la partie.

L'ecran principal du jeu affiche la consigne en haut, la planche au centre dans un widget permettant le zoom et le scroll, et deux boutons en bas pour terminer ou arreter. La detection des taps convertit les coordonnees du referentiel widget vers le referentiel image en tenant compte du facteur d'echelle et du scroll. Selon le resultat, un feedback vert persistant ou rouge transitoire est superpose a la planche.

L'ecran de transition de fin de partie affiche le score en etoiles et un message d'encouragement, avec une option pour lancer une nouvelle partie et une option pour terminer la seance.

L'ecran recapitulatif de fin de seance liste les parties jouees et permet de generer le QR de session avec les donnees reelles, ou de quitter sans transferer.

Les retours sonores et haptiques sont ajoutes si les paquets sont disponibles, sinon notes comme amelioration.

Tests de widget sur les quatre ecrans.

Commit propose : "tablette: implementer interface graphique du jeu des emotions".

## Point technique sensible : conversion des coordonnees

Le point le plus delicat de la tache 10 est la conversion des coordonnees d'un tap depuis le referentiel de l'ecran vers le referentiel de l'image de la planche, en tenant compte du zoom et du defilement. Si un widget de type InteractiveViewer est utilise, sa matrice de transformation doit etre exploitee pour cette conversion. Une alternative est un defilement bidirectionnel avec calcul manuel de l'offset. Cette conversion doit etre soigneusement testee car une erreur decalerait toutes les zones cliquables.

## Ordre d'execution recommande

La tache 7 etant faite, l'ordre est : tache 8 (logique metier, testable sans UI), puis tache 10 (UI s'appuyant sur la logique), la tache 9 etant integree au passage. Enfin la tache 13 (test interactif sur materiel reel) valide l'ensemble.

## Criteres d'acceptation

Le jeu est valide quand le scenario suivant fonctionne sur la Lenovo Tab P12 reelle.

Apres scan d'un QR creation_patient et confirmation du patient charge, le praticien accede a l'ecran de configuration, choisit une planche et une emotion, et lance la partie. La planche s'affiche avec la consigne correspondante. Le patient tape sur des personnages : un tap correct fait apparaitre un point vert persistant, un tap sur une autre emotion un point rouge transitoire, un tap dans le vide ne fait rien. Quand toutes les cibles sont trouvees, ou apres le bouton de fin, l'ecran de transition affiche le score en etoiles. Le praticien peut lancer une nouvelle partie avec une autre planche et une autre emotion, ou terminer la seance. A la fin, l'ecran recapitulatif liste les parties et genere un QR de session unique contenant toutes les parties. Ce QR est scanne par le PC qui insere la seance en base avec ses parties agregees.

Tous les tests unitaires et de widget passent. Flutter analyze et flutter test sont verts. La cross-compile Windows reste valide.

## Risques specifiques

La production des planches etant faite, le risque principal est ecarte. Restent le risque de performance d'affichage d'une grande image scrollable sur la tablette, a verifier tot, et le risque de justesse de la conversion des coordonnees de tap, a tester soigneusement. L'equilibrage du scoring est gere par la variable de configuration centralisee, ajustable apres les premiers tests reels.
