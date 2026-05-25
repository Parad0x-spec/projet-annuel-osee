# Sprint 3 - Tâches 7 a 10 revisitees suite a l'ADR-08

## Objet

Ce document acte la revision des taches 7 a 10 du sprint 3 suite a la decision tracee dans l'ADR-08 de passer aux planches scenes pre-dessinees. Il succede aux specifications correspondantes du plan general docs/sprints/sprint_03.md, qui restent valides pour les autres taches du sprint mais sont ici remplacees pour les taches du jeu.

## Tache 7 revisitee - Production et annotation des trois planches

La tache 7 initiale prevoyait la constitution d'une banque de visages individuels Open Peeps. Elle est remplacee par la production des trois planches scenes complete et de leurs annotations.

Cette tache est realisee par le developpeur hors session de Claude Code, en deux phases.

Phase un, production des planches. Generer les trois planches via ChatGPT en utilisant le prompt initial pour le niveau 1 et des variantes ajustees pour les niveaux 2 et 3. Chaque planche est revue pour s'assurer que les expressions des personnages sont lisibles et que la repartition des emotions est equilibree. Une planche refusee ou de qualite insuffisante est regenerée avec des ajustements de prompt. Les trois planches sont sauvegardees au format PNG dans un dossier de travail.

Phase deux, annotation des planches. Utiliser l'outil annotateur_planche.html livre dans outils/ pour ouvrir chaque planche et marquer les personnages. Pour chaque visage, cliquer dessus, choisir l'emotion dans le menu, ajuster eventuellement le rayon de la zone cliquable. Une fois toutes les annotations posees, exporter le JSON. Repeter pour les trois planches.

Les six fichiers resultant (trois images PNG et trois fichiers JSON) sont copies dans tablette_flutter/assets/planches/ avec les noms planche_1.png et planche_1.json pour le niveau 1, planche_2.png et planche_2.json pour le niveau 2, planche_3.png et planche_3.json pour le niveau 3.

Le pubspec.yaml de la tablette est mis a jour pour declarer ces assets.

Cette tache ne fait pas l'objet d'un commit unique, elle se materialise par un commit "tablette: ajouter banque de planches du jeu des emotions" qui ajoute les six fichiers au repo.

## Tache 8 revisitee - Logique metier du jeu

La tache 8 initiale prevoyait la composition pseudo-aleatoire de planches a la volee. Elle devient le chargement et l'exploitation de planches pre-dessinees.

Code a livrer dans tablette_flutter/lib/features/jeu_emotions/ :

Dans domain.dart, etendre les types deja en place avec un type Planche qui contient le chemin de l'image asset, la largeur et hauteur en pixels, et une liste de PersonnageAnnotation (chaque PersonnageAnnotation contient x, y, rayon, emotion). Ajouter une fonction utilitaire estDansZone(tapX, tapY, personnage) qui retourne vrai si les coordonnees du tap tombent dans le cercle defini par les coordonnees et le rayon du personnage.

Dans data.dart, ajouter une fonction chargerPlanchePourNiveau(niveau) qui retourne un Future<Planche> en lisant l'image asset correspondante et en parsant le JSON d'annotation associe. La fonction valide que toutes les emotions du JSON sont des emotions reconnues par le jeu, et que les coordonnees sont coherentes avec la taille de l'image.

Dans controller.dart, ajouter les providers Riverpod necessaires : un PlancheCouranteProvider qui charge la planche selon le niveau courant, un ManchesCouranteProvider qui gere l'etat de la manche en cours (consigne actuelle, cibles trouvees, faux positifs, temps de debut), et une fonction taper(tapX, tapY) qui prend les coordonnees d'un tap, identifie si un personnage est touche, et met a jour l'etat selon l'emotion.

Implementer la fonction de calcul de score selon la formule de la spec : score = (T / (T + R)) * 100 - F * 5, borne entre zero et cent.

Tests unitaires obligatoires sur le parsing du JSON, la detection de tap, le calcul de score, et la logique de fin de manche.

Commit propose : "tablette: implementer logique metier du jeu des emotions".

## Tache 9 reconfirmee - Application stricte du niveau_demande

La tache 9 telle que revisee suite a l'option (c) sur l'adaptation reste valide. Pas de changement de specification suite a l'ADR-08, car cette tache concerne la lecture du niveau_demande dans le payload creation_patient et son application au demarrage du jeu, ce qui est independant du modele de planche.

A noter cependant que la fonction chargerPlanchePourNiveau livree a la tache 8 utilise le niveau_demande pour choisir parmi planche_1, planche_2 ou planche_3.

## Tache 10 revisitee - Interface graphique du jeu

La tache 10 initiale prevoyait une grille pseudo-aleatoire de cellules contenant des visages. Elle devient un canvas scrollable affichant une planche statique avec detection des taps.

Code a livrer dans tablette_flutter/lib/features/jeu_emotions/ui/ :

L'ecran principal JeuEmotionsScreen affiche en haut la consigne et la progression (manche x sur y), au centre la planche dans un widget InteractiveViewer ou GestureDetector imbrique selon le besoin de scroll, et en bas les deux boutons "J'ai fini" et "Arreter la session".

La planche est affichee dans un widget Stack qui superpose l'image et les indicateurs de feedback. Au moment d'un tap, l'application calcule les coordonnees du tap dans le referentiel de l'image (en tenant compte du facteur d'echelle d'affichage et du scroll eventuel), appelle la fonction taper du controller, et selon le retour ajoute soit un PositionedFeedback vert persistant soit un PositionedFeedback rouge transitoire au-dessus de la planche.

L'ecran de transition entre manches affiche le score en etoiles et le message d'encouragement, avec un timer de trois secondes ou un bouton "Suivant".

L'ecran recapitulatif de fin de session reprend l'export deja en place a la tache 11 mais avec maintenant des donnees reelles de session a la place du payload minimaliste.

Les retours sonores et haptiques sont implementes avec les paquets audioplayers et vibration deja en place ou a ajouter (a verifier dans le pubspec actuel).

Tests de widget sur l'affichage de la planche, la reaction aux taps avec coordonnees simulees, l'enchainement des manches.

Commit propose : "tablette: implementer interface graphique du jeu des emotions".

## Ordre d'execution recommande

L'ordre recommande pour les taches 7 a 10 est le suivant.

D'abord la tache 7 (production des planches), puisque sans planches on ne peut pas tester les taches 8 et 10. La production peut etre faite en parallele d'autres taches non bloquantes si necessaire.

Ensuite la tache 8 (logique metier sans UI), qui peut etre developpee et testee avec une planche fictive si la tache 7 traine.

Ensuite la tache 10 (UI), qui s'appuie sur la tache 8.

Ensuite la tache 9 (application du niveau), qui peut etre integree en parallele de la tache 10.

Enfin la tache 13 (test interactif) qui s'appuie sur tout ce qui precede.

## Critères d'acceptation revisités

Le jeu est valide quand le scenario suivant fonctionne sur la Lenovo Tab P12 reelle.

Apres scan d'un QR creation_patient avec niveau 1, l'ecran de jeu affiche la planche 1, la consigne "Trouve les enfants joyeux" et la barre de progression "Manche 1 sur 5". Le patient peut taper sur des personnages joyeux et voir des points verts persistants apparaitre. Un tap sur un personnage triste fait apparaitre un point rouge qui s'efface en une seconde. Quand tous les personnages joyeux sont trouves, ou apres clic sur "J'ai fini", l'ecran de transition affiche le score en etoiles. La manche suivante demarre avec une autre consigne. Apres cinq manches, l'ecran recapitulatif s'affiche avec le score global et permet de generer le QR de session. Ce QR est scanne par le PC qui insere une session reelle dans sa base, avec des manches non vides cette fois.

Le meme scenario fonctionne aux niveaux 2 et 3 avec leurs planches respectives, et les emotions correspondantes sont presentes dans les consignes.

Tous les tests unitaires et de widget passent. Flutter analyze et flutter test sont verts. La cross-compile Windows reste valide.

## Risques specifiques a ces taches

Le risque principal est la production des planches 2 et 3, qui n'ont pas encore ete generees. Si ChatGPT a du mal a produire une planche niveau 3 avec six emotions distinctes dans une scene dense, on peut soit reduire le nombre d'emotions pour ce niveau, soit composer la planche en plusieurs etapes de generation, soit accepter un niveau 3 a cinq emotions seulement.

Le second risque est l'effort d'annotation. Trois planches de quarante a soixante personnages chacune, cela fait entre cent vingt et cent quatre-vingts annotations a poser manuellement. L'outil HTML est concu pour rendre ce travail le plus rapide possible mais cela reste un investissement de trente a quarante-cinq minutes. Il faut bloquer ce temps de production dans le planning.

Le troisieme risque est l'interaction tactile sur des zones petites au niveau 3. Si la planche est dense et les personnages petits, les zones cliquables peuvent se chevaucher. Dans ce cas l'outil d'annotation permet de reduire le rayon pour eviter les recouvrements, et le test interactif validera l'ergonomie reelle.
