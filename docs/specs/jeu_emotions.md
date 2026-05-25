# Specification du jeu des emotions

## Note de version

Cette specification supersede la version anterieure. Elle est entierement refondue suite a la decision actee par l'ADR-08 de passer d'un modele de grille composee a la volee a un modele de planches scenes pre-dessinees style "Ou est Charlie".

## Objet

Le jeu des emotions est le premier contenu cognitif du projet, integre dans l'application tablette. Il est destine a des patients suivis pour TDAH ou troubles du spectre autistique, encadres par un praticien qui pilote le dispositif depuis son PC.

Le format retenu est inspire des livres "Ou est Charlie" : le patient voit a l'ecran une planche dense illustrant une scene sociale (un parc, une fete, une recreation) dans laquelle de nombreux enfants sont representes avec chacun une emotion definie. La consigne lui demande de trouver et taper sur tous les enfants exprimant une emotion donnee.

Ce format combine deux objectifs cliniques. L'attention visuelle selective, qui consiste a parcourir un champ visuel charge et a isoler les elements pertinents, est une fonction frequemment alteree dans le TDAH. La reconnaissance des emotions sur des visages dans un contexte social riche est une competence souvent alteree dans le spectre autistique. En combinant les deux, le jeu travaille simultanement les deux dimensions dans un cadre proche de la vie reelle.

## Banque de planches

La banque de planches est composee de trois planches scenes complete pour la premiere version, correspondant aux trois niveaux de difficulte. Chaque planche est une illustration cartoon dense montrant une scene sociale avec de nombreux enfants exprimant des emotions varies.

Les trois planches sont produites par generation d'images via ChatGPT en utilisant le modele Image-1. Le prompt utilise pour la planche niveau 1 est conserve dans docs/specs/planches_prompts.md et peut etre reutilise pour produire de nouvelles planches dans une evolution post-soutenance.

Chaque planche est livree au format PNG, dimensions typiques 1536x1024 pixels, sans transparence, en couleurs vives. Les trois planches sont rangees dans tablette_flutter/assets/planches/ sous les noms planche_1.png, planche_2.png et planche_3.png.

Chaque planche est associee a un fichier d'annotation JSON portant le meme nom et l'extension .json. Ce fichier contient la liste des personnages presents dans la planche avec, pour chacun, ses coordonnees x et y dans l'image (en pixels depuis le coin haut gauche), le rayon de la zone cliquable autour du visage (en pixels, typiquement entre vingt et quarante selon la taille du personnage dans la planche), et l'emotion qu'il exprime.

Le format JSON de l'annotation est le suivant.

```json
{
  "planche": "planche_1.png",
  "largeur": 1536,
  "hauteur": 1024,
  "personnages": [
    {"x": 245, "y": 380, "rayon": 30, "emotion": "joie"},
    {"x": 412, "y": 156, "rayon": 28, "emotion": "tristesse"},
    {"x": 678, "y": 245, "rayon": 32, "emotion": "colere"}
  ]
}
```

L'annotation est realisee par le developpeur du projet a l'aide de l'outil HTML d'annotation livre dans outils/annotateur_planche.html. L'outil affiche la planche, permet de cliquer sur chaque visage pour ajouter une annotation, et exporte le JSON pret a etre integre dans les assets de l'application.

## Niveaux de difficulte

Le jeu propose trois niveaux de difficulte, du plus facile au plus difficile.

Le niveau 1 utilise la planche 1. Quatre emotions sont representees : joie, colere, tristesse, surprise. La planche est aeree, avec environ trente personnages au total, repartis dans une scene de parc lisible. Les expressions sont exagerees et facilement identifiables. C'est le niveau d'introduction, sans pression temporelle.

Le niveau 2 utilise la planche 2. Cinq emotions sont representees, avec l'ajout de la peur. La planche est plus dense, avec environ quarante personnages dans une scene de fete ou de recreation. Les expressions restent claires mais commencent a presenter quelques nuances. C'est le niveau intermediaire, sans pression temporelle.

Le niveau 3 utilise la planche 3. Six emotions sont representees, avec l'ajout du degout. La planche est tres dense, avec environ cinquante a soixante personnages dans une scene complexe. Quelques expressions sont volontairement plus subtiles, par exemple la distinction entre peur et surprise qui ont des expressions faciales proches. C'est le niveau le plus exigeant, sans pression temporelle pour la premiere version.

L'absence de pression temporelle dans toutes les versions de la premiere iteration est volontaire pour ne pas mettre les patients en situation de stress. Une evolution future pourra introduire un chronometre aux niveaux superieurs si l'usage le justifie.

Le niveau joue est choisi par le praticien dans le logiciel PC au moment de generer le QR creation_patient, et transmis a la tablette via le champ niveau_demande de ce QR. La tablette applique strictement ce niveau sans calcul d'adaptation.

## Mecanique generale du jeu

Une session de jeu se deroule en plusieurs manches sur la planche correspondant au niveau choisi. Chaque manche est independante.

Au debut d'une manche, la tablette affiche en haut de l'ecran la consigne du moment, par exemple "Trouve tous les enfants joyeux". En dessous, la planche complete est affichee dans un canvas qui peut etre scrolle horizontalement et verticalement si la planche depasse la taille de l'ecran tablette.

Le patient tape sur les zones qu'il pense correspondre a la consigne. A chaque tap, l'application verifie si les coordonnees du tap tombent dans la zone cliquable d'un personnage annote. Si oui, l'application compare l'emotion du personnage avec l'emotion consigne.

Si le tap correspond a un personnage cible (bonne emotion), un point vert avec une icone de validation apparait sur le visage et reste affiche jusqu'a la fin de la manche pour signaler que cette cible est trouvee. Le compteur de cibles trouvees est incremente.

Si le tap correspond a un personnage non cible (mauvaise emotion), un point rouge avec une icone de croix apparait sur le visage et reste affiche un temps court (environ une seconde) avant de s'effacer. Le compteur de faux positifs est incremente.

Si le tap ne tombe sur aucun personnage annote, rien ne se passe. C'est volontaire : on ne penalise pas un patient qui aurait clique entre deux personnages.

La manche se termine quand le patient a trouve tous les personnages cibles de la planche, ou quand le patient appuie sur le bouton "J'ai fini" affiche en bas de l'ecran. Le patient peut aussi appuyer sur "Abandonner la manche" qui termine la manche avec un drapeau d'abandon.

Quand la manche se termine, un ecran de transition affiche le score de la manche sous deux formes. Pour le patient, une note ludique en etoiles (de une a trois etoiles selon la performance) avec un message d'encouragement neutre. Pour les donnees envoyees au PC, un score precis sous forme de pourcentage et de details (nombre de cibles trouvees, ratees, faux positifs).

La session contient un nombre fixe de manches, typiquement cinq pour la premiere version. La consigne change a chaque manche : la premiere manche peut demander de trouver les enfants joyeux, la deuxieme les tristes, et ainsi de suite. L'ordre des consignes est tire aleatoirement parmi les emotions disponibles au niveau courant, sans repetition tant que toutes les emotions n'ont pas ete utilisees.

A la fin de la session (cinq manches jouees), un ecran recapitulatif affiche le score global, propose un bouton pour generer le QR de session a scanner par le PC, et un bouton pour quitter sans transferer.

## Calcul du score

Le score d'une manche est calcule comme suit. On note T le nombre de cibles trouvees, R le nombre de cibles ratees (les cibles qui n'ont pas ete cliquees a la fin de la manche), F le nombre de faux positifs (les clics sur des personnages d'une autre emotion).

Le score brut sur cent est calcule par la formule (T / (T + R)) * 100 - F * 5. Le facteur cinq par faux positif est arbitraire pour la premiere version et pourra etre ajuste apres les premiers tests utilisateurs. Le score est borne entre zero et cent.

L'affichage en etoiles cote patient suit la regle suivante. De zero a quarante : une etoile et un message du type "Continue, tu progresses". De quarante-et-un a soixante-quinze : deux etoiles et un message du type "Bien joue". Au-dessus de soixante-quinze : trois etoiles et un message du type "Excellent, tu maitrises". Aucun feedback negatif n'est donne, conformement au principe de bienveillance pose dans la note de cadrage.

Le score global de la session est la moyenne arithmetique des scores des manches.

## Metriques enregistrees et envoyees au PC

Le jeu enregistre des metriques detaillees pendant la session, stockees temporairement dans la base SQLite de la tablette puis transmises au PC via le QR session a la fin de la session.

Au niveau de la session globale on enregistre le patient_id et les patient_initiales recus du PC dans le message creation_patient, la date et l'heure de debut, le niveau joue, le nombre de manches jouees, l'heure de fin, et le score global.

Au niveau de chaque manche on enregistre l'emotion cible demandee, le numero de la planche utilisee, le nombre total de personnages de cette emotion presents dans la planche, le nombre de cibles trouvees, le nombre de faux positifs, le nombre de cibles ratees, le temps total de la manche en millisecondes, le booleen indiquant si la manche a ete abandonnee, et le score de la manche.

Au niveau de chaque tap on enregistre le timestamp relatif au debut de la manche, les coordonnees x et y du tap dans la planche, l'emotion du personnage tape (ou null si le tap n'est tombe sur aucun personnage), et un booleen indiquant si le tap etait correct (cible trouvee). Cette granularite permet au praticien de visualiser le parcours d'attention du patient.

## Ecrans et navigation

Le jeu s'integre dans l'application tablette existante. Il est accessible depuis la route /jeu qui est actuellement un placeholder.

Le parcours nominal d'une session est le suivant. Apres scan du QR creation_patient et confirmation "Patient MD charge", le patient (ou plutot le praticien qui pilote) clique sur "Commencer le jeu". L'application charge la planche correspondant au niveau et lance la premiere manche.

L'ecran principal du jeu affiche en haut une barre de progression (manche courante sur manches totales) et la consigne du moment ("Trouve les enfants joyeux"). Au centre se trouve le canvas affichant la planche, scrollable si necessaire. En bas se trouvent deux boutons : "J'ai fini" qui valide la manche en l'etat, et "Arreter la session" qui propose une confirmation avant d'abandonner toute la session.

Entre deux manches, un ecran de transition de quelques secondes affiche le score de la manche en etoiles, le message d'encouragement, et un bouton "Manche suivante" pour passer a la suite. Le bouton peut etre tape pour avancer plus vite.

A la fin de la session, l'ecran recapitulatif affiche le score global, le detail par manche, et deux boutons : "Generer le QR de session" qui ouvre l'ecran d'export QR deja implemente, et "Quitter sans transferer" qui retourne a l'accueil sans envoyer les donnees (mode degrade en cas de probleme).

## Considerations ergonomiques et accessibilite

Le jeu cible des enfants et adolescents. La taille minimale de la zone tactile autour d'un visage doit etre suffisante pour un tap precis. Le rayon de la zone cliquable de chaque personnage est defini dans le JSON d'annotation par le developpeur, typiquement entre vingt et quarante pixels selon la taille du personnage dans la planche. Les zones cliquables sont invisibles pour ne pas perturber le rendu de la scene.

Les retours visuels (point vert ou rouge) sont accompagnes de retours sonores discrets mais distincts (un son court joyeux pour la cible trouvee, un son neutre pour le faux positif, pas de son negatif aggressif). Des retours haptiques courts sont aussi declenches (vibration de cinquante millisecondes pour un tap correct, cent millisecondes pour un tap incorrect). Tous ces retours peuvent etre desactives dans les parametres si necessaire.

Les couleurs des points de feedback respectent un contraste suffisant pour les patients avec une perception alteree des couleurs : vert vif accompagne d'une icone check, rouge vif accompagne d'une icone croix.

L'orientation paysage est forcee comme pour le reste de l'application. La planche est concue pour etre lue confortablement sur l'ecran douze pouces de la Tab P12.

## Tests prevus

Les tests unitaires couvrent la logique de chargement et de parsing du JSON d'annotation (verifier que tous les personnages sont bien lus, que les emotions sont valides, que les coordonnees sont coherentes avec la taille de la planche), la logique de detection de tap (verifier qu'un tap aux coordonnees correctes touche le bon personnage, qu'un tap a cote ne touche rien, qu'un tap sur un personnage deja trouve n'est pas compte deux fois), la logique de calcul de score (verifier la formule avec divers cas), et la logique de fin de manche (terminer quand toutes les cibles sont trouvees, ou sur clic du bouton, ou sur abandon).

Les tests de widget couvrent l'affichage de l'ecran principal du jeu, la reaction aux taps simules sur le canvas, l'enchainement des manches, et l'ecran recapitulatif final.

Le test manuel sur Lenovo Tab P12 (tache 13 du sprint) couvre l'ergonomie reelle, la fluidite d'affichage des planches denses, la lisibilite des emotions a taille reelle, la qualite des retours sensoriels et l'experience utilisateur globale.

## Risques identifies

Le risque principal de ce modele est la qualite et la coherence des planches generees par ChatGPT. Bien que la premiere planche test produite soit excellente, rien ne garantit que les deux suivantes auront le meme niveau de qualite et de coherence stylistique. Le risque est attenue par le fait que le prompt est tres detaille et reutilisable. En cas de qualite insuffisante d'une planche, on peut iterer plusieurs fois avec des ajustements de prompt jusqu'a obtenir un resultat satisfaisant.

Le second risque est la performance d'affichage d'une grande planche scrollable sur la Tab P12. Une image de 1536x1024 pixels pese typiquement entre cinq cents et mille kilo-octets en PNG. L'affichage dans un widget Flutter avec gestion du scroll devrait etre fluide mais doit etre verifie tot dans l'implementation. Si necessaire, on pourra redimensionner les planches a une resolution adaptee a l'ecran de la tablette.

Le troisieme risque est la justesse de l'annotation manuelle. Une planche mal annotee (un visage joyeux marque comme triste par erreur) introduirait un biais clinique. L'outil HTML d'annotation prevoit une fonction de revue qui permet au developpeur de relire ses annotations en survolant chaque marqueur, et de corriger les erreurs avant l'export final.

Le quatrieme risque est l'equilibrage du scoring. La formule actuelle (T / (T + R)) * 100 - F * 5 est une premiere estimation. Le facteur de penalite des faux positifs et les seuils des etoiles devront etre ajustes apres les premiers tests utilisateurs reels. Une variable de configuration centralisee dans la feature jeu_emotions permettra de modifier ces parametres sans toucher au code metier.
