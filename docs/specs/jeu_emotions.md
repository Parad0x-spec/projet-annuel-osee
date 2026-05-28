# Specification du jeu des emotions

## Note de version

Cette specification supersede les versions anterieures. Elle reflete le modele acte par l'ADR-08 dans sa forme definitive : quatre planches scenes pre-dessinees de niveau equivalent, quatre emotions (joie, colere, tristesse, peur), choix de la planche et de l'emotion par le praticien sur la tablette, accumulation de plusieurs parties dans une seance et transfert groupe par un seul QR en fin de seance.

## Objet

Le jeu des emotions est le premier contenu cognitif du projet, integre dans l'application tablette. Il est destine a des patients suivis pour TDAH ou troubles du spectre autistique, encadres par un praticien qui pilote la seance.

Le format est inspire des livres "Ou est Charlie". Le patient voit a l'ecran une planche dense illustrant une scene sociale (un parc) dans laquelle de nombreux enfants sont representes avec chacun une emotion. La consigne lui demande de trouver et taper tous les enfants exprimant une emotion donnee.

Ce format travaille deux competences simultanement. L'attention visuelle selective, souvent alteree dans le TDAH, est sollicitee par l'exploration d'un champ visuel charge. La reconnaissance des emotions sur des visages en contexte social, souvent alteree dans le spectre autistique, est sollicitee par l'identification de l'emotion cible.

## Banque de planches

La banque comprend quatre planches scenes pour cette premiere version. Les quatre planches sont de niveau de difficulte equivalent : elles representent toutes les quatre memes emotions et ont une densite comparable. Elles ne correspondent pas a des niveaux croissants, mais constituent un pool de variete permettant au praticien de changer de support pour un meme patient afin d'eviter la memorisation des emplacements et la lassitude.

Les planches sont produites par generation d'images via ChatGPT (Image-1) a partir d'un prompt detaille en francais. Le prompt decrit une scene de parc vivante, un nombre eleve de personnages, la repartition equilibree des quatre emotions, des expressions faciales tres lisibles et exagerees, et l'absence de bulles de bande dessinee ou de smileys flottants pour preserver le realisme de la scene.

Chaque planche est livree au format JPG, dimensions typiques autour de 1536 pixels de large, poids autour de 800 kilo-octets. Les quatre planches sont rangees dans tablette_flutter/assets/planches/ sous les noms planche_1.jpg a planche_4.jpg.

Chaque planche est associee a un fichier d'annotation JSON portant le meme nom de base. Ce fichier contient la liste des personnages avec, pour chacun, ses coordonnees x et y dans l'image en pixels depuis le coin haut gauche, le rayon de la zone cliquable autour du visage en pixels, et l'emotion exprimee.

Le format JSON de l'annotation est le suivant.

```json
{
  "planche": "planche_1.jpg",
  "largeur": 1536,
  "hauteur": 912,
  "personnages": [
    {"x": 265, "y": 195, "rayon": 30, "emotion": "joie"},
    {"x": 419, "y": 152, "rayon": 30, "emotion": "tristesse"},
    {"x": 539, "y": 240, "rayon": 30, "emotion": "colere"}
  ]
}
```

L'annotation est realisee avec l'outil HTML livre dans outils/annotateur_planche.html. Le champ planche du JSON peut contenir le nom du fichier original utilise lors de l'annotation et ne correspond pas necessairement au nom final du fichier ; le code charge l'image par son chemin d'asset reel et n'utilise pas ce champ pour localiser l'image.

Les quatre planches du projet sont annotees et contiennent chacune un nombre suffisant de personnages pour chaque emotion. A titre indicatif, les comptages observes vont d'environ trois a dix-sept personnages par emotion selon la planche, ce qui garantit qu'une consigne sur n'importe quelle emotion a toujours des cibles a trouver.

## Emotions

Les quatre emotions du jeu sont la joie, la colere, la tristesse et la peur. Elles sont identifiees dans le code par les chaines joie, colere, tristesse, peur. Toute autre valeur dans un fichier d'annotation est consideree comme invalide et provoque une erreur de chargement de la planche.

## Mecanique d'une partie

Une partie correspond a une planche et une emotion, choisies par le praticien sur la tablette avant le lancement.

Au lancement, la tablette affiche en haut la consigne, par exemple "Trouve tous les enfants en colere". En dessous, la planche complete est affichee dans un canvas qui peut etre scrolle si la planche depasse la taille de l'ecran.

Le patient tape sur les zones qu'il pense correspondre. A chaque tap, l'application verifie si les coordonnees tombent dans la zone cliquable d'un personnage annote. Si oui, elle compare l'emotion du personnage avec l'emotion consigne.

Si le tap correspond a un personnage cible, un point vert avec une icone de validation apparait sur le visage et reste affiche jusqu'a la fin de la partie. Le compteur de cibles trouvees est incremente.

Si le tap correspond a un personnage d'une autre emotion, un point rouge avec une icone de croix apparait sur le visage et reste affiche environ une seconde avant de s'effacer. Le compteur de faux positifs est incremente.

Si le tap ne tombe sur aucun personnage annote, rien ne se passe. On ne penalise pas un clic dans le vide.

La partie se termine de trois manieres. Soit le patient a trouve tous les personnages cibles de la planche, auquel cas elle se termine automatiquement. Soit le patient (ou le praticien) appuie sur le bouton "J'ai fini" qui valide la partie en l'etat. Soit la partie est abandonnee avant la fin via un bouton d'arret, auquel cas elle est marquee comme abandonnee dans les donnees.

Quand la partie se termine, un ecran de transition affiche le resultat sous deux formes. Pour le patient, une note ludique en etoiles de une a trois avec un message d'encouragement neutre. Cet ecran propose au praticien de lancer une nouvelle partie en choisissant une autre planche et une autre emotion, ou de terminer la seance.

## Accumulation des parties et fin de seance

Plusieurs parties s'accumulent au cours d'une seance. Chaque partie jouee est enregistree dans l'etat de la seance en memoire sur la tablette.

Quand le praticien decide de terminer la seance, un ecran recapitulatif affiche l'ensemble des parties jouees et propose de generer le QR de session. Ce QR unique contient les donnees agregees de toutes les parties de la seance. Il est scanne par le PC qui rapatrie l'ensemble pour mettre a jour le suivi du patient.

Un bouton permet aussi de quitter sans transferer, en mode degrade, en cas de probleme.

## Calcul du score

Le score d'une partie est calcule a partir du nombre de cibles trouvees note T, du nombre de cibles ratees note R, et du nombre de faux positifs note F.

Le score brut sur cent vaut (T / (T + R)) * 100 - F * 5. Le facteur cinq par faux positif est arbitraire pour cette premiere version et pourra etre ajuste apres les premiers tests. Le score est borne entre zero et cent.

L'affichage en etoiles cote patient suit la regle suivante. De zero a quarante, une etoile et un message encourageant. De quarante-et-un a soixante-quinze, deux etoiles. Au-dessus de soixante-quinze, trois etoiles. Aucun feedback negatif n'est donne, conformement au principe de bienveillance pose dans la note de cadrage.

## Donnees enregistrees et transmises au PC

Le jeu collecte des donnees pendant chaque partie. Le detail tap par tap (horodatage relatif au debut de partie, coordonnees, emotion du personnage tape, justesse) est collecte en memoire mais n'est pas transmis dans le QR pour cette version, en raison de la capacite limitee d'un QR code.

Les donnees transmises au PC sont agregees. Au niveau de la seance, on transmet l'identifiant du patient et ses initiales recus dans le message creation_patient, la date et l'heure de debut de seance, le niveau_demande recu (conserve comme intention du praticien), et la liste des parties jouees.

Au niveau de chaque partie, on transmet l'emotion cible, le numero de la planche utilisee, le nombre total de personnages de cette emotion presents sur la planche, le nombre de cibles trouvees, le nombre de faux positifs, le nombre de cibles ratees, le temps total de la partie en millisecondes, la maniere dont la partie s'est terminee (bouton, automatique, ou abandon), et le score de la partie.

Ces donnees agregees suffisent pour le suivi de progression longitudinale, qui s'appuie sur l'evolution du taux de reussite, du nombre de fautes et du temps au fil des seances. Le fichier Excel de suivi cote PC, alimente a chaque reception de seance, presente ces donnees sous forme de tableau et de diagramme.

## Ecrans et navigation

Le jeu s'integre dans l'application tablette. Apres scan du QR creation_patient et confirmation du patient charge, le praticien accede a un ecran de configuration de partie.

L'ecran de configuration de partie permet de choisir la planche parmi les quatre disponibles et l'emotion parmi les quatre possibles, puis de lancer la partie via un bouton. Cet ecran est destine au praticien.

L'ecran principal du jeu affiche en haut la consigne, au centre la planche dans un widget permettant le scroll, et en bas deux boutons : "J'ai fini" qui valide la partie, et "Arreter" qui propose une confirmation avant abandon.

La planche est affichee dans un Stack qui superpose l'image et les indicateurs de feedback. Au moment d'un tap, l'application calcule les coordonnees du tap dans le referentiel de l'image en tenant compte du facteur d'echelle et du scroll, puis ajoute soit un feedback vert persistant soit un feedback rouge transitoire.

L'ecran de transition de fin de partie affiche le score en etoiles et le message d'encouragement, avec deux options : lancer une nouvelle partie (retour a l'ecran de configuration) ou terminer la seance.

L'ecran recapitulatif de fin de seance reprend l'export QR deja implemente, avec cette fois les donnees reelles de toutes les parties de la seance a la place du payload minimaliste de la tache 11.

## Considerations ergonomiques et accessibilite

Le jeu cible des enfants et adolescents. Le rayon de la zone cliquable de chaque personnage, defini dans le JSON d'annotation, est typiquement de trente pixels, ajustable par le developpeur lors de l'annotation pour eviter les recouvrements sur les planches denses. Les zones cliquables sont invisibles pour ne pas perturber le rendu.

Les retours visuels (point vert ou rouge) sont accompagnes de retours sonores discrets et distincts, et de retours haptiques courts (vibration breve pour un tap correct, un peu plus longue pour un tap incorrect). Ces retours peuvent etre desactives dans les parametres.

Les couleurs des points respectent un contraste suffisant pour les patients avec perception alteree des couleurs : vert vif avec icone de validation, rouge vif avec icone de croix.

L'orientation paysage est forcee comme pour le reste de l'application. La planche est concue pour etre lue confortablement sur l'ecran douze pouces de la Lenovo Tab P12.

## Tests prevus

Les tests unitaires couvrent le chargement et le parsing du JSON d'annotation (lecture de tous les personnages, validation des emotions, coherence des coordonnees avec la taille de la planche), la detection de tap (un tap aux bonnes coordonnees touche le bon personnage, un tap a cote ne touche rien, un tap sur un personnage deja trouve n'est pas compte deux fois), le calcul de score sur divers cas, et la logique de fin de partie dans ses trois modes.

Les tests de widget couvrent l'ecran de configuration de partie, l'affichage de la planche et la reaction aux taps simules, l'ecran de transition, et l'ecran recapitulatif de fin de seance.

Le test manuel sur Lenovo Tab P12 couvre l'ergonomie reelle, la fluidite d'affichage des planches denses, la lisibilite des emotions a taille reelle, la qualite des retours sensoriels, et l'experience globale d'une seance complete avec plusieurs parties et transfert final.

## Risques identifies

Le risque de qualite des planches generees par ChatGPT est maitrise puisque les quatre planches sont deja produites, annotees et integrees.

Le risque de performance d'affichage d'une grande image scrollable sur la Tab P12 doit etre verifie tot dans l'implementation. Une image JPG de 800 kilo-octets devrait s'afficher de maniere fluide, mais en cas de ralentissement on pourra redimensionner les planches a une resolution adaptee a l'ecran.

Le risque de justesse de l'annotation manuelle subsiste : un visage mal etiquete introduirait un biais. L'outil HTML permet de relire les annotations avant export. Une verification visuelle des planches dans le jeu permettra de detecter d'eventuelles erreurs.

Le risque d'equilibrage du scoring est gere par une variable de configuration centralisee permettant d'ajuster le facteur de penalite et les seuils d'etoiles sans toucher au code metier, apres les premiers tests reels.
