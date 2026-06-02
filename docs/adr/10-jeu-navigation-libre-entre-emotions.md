# ADR-10 - Jeu a navigation libre entre emotions sur une planche

## Statut

Accepte. Supersede partiellement l'ADR-08 sur la partie mode de jeu. L'ADR-08 reste valide pour tout ce qui concerne les planches scenes pre-dessinees, leur production, leur annotation et leur format ; seule la mecanique d'interaction du jeu est revisee ici.

## Contexte

L'ADR-08 a acte le passage a des planches scenes pre-dessinees de style "Ou est Charlie" et un mode de jeu ou chaque partie consistait a chercher une seule emotion, choisie avant le lancement de la partie. Ce mode a ete implemente et teste sur Lenovo Tab P12.

Lors de ce test, le praticien a formule une demande d'evolution. Le modele a une emotion par partie est rigide : pour faire travailler le patient sur plusieurs emotions d'une meme scene, il fallait lancer une partie distincte par emotion, en repassant a chaque fois par un ecran de configuration. Le praticien souhaite au contraire pouvoir, sur une meme planche affichee, faire chercher au patient les differentes emotions dans l'ordre qu'il veut, en basculant librement de l'une a l'autre, avec un suivi en temps reel du nombre de cibles trouvees pour chaque emotion. Cette souplesse correspond mieux au deroulement d'une seance reelle et permet surtout un diagnostic plus fin, en identifiant precisement l'emotion sur laquelle le patient se trompe.

## Decision

Le mode de jeu devient la navigation libre entre emotions sur une meme planche.

Le praticien choisit une planche. L'ecran de jeu affiche cette planche en occupant le maximum d'espace, le zoom et le defilement restant disponibles pour examiner les visages de pres. Une barre laterale presente les quatre emotions de la planche, chacune accompagnee d'un compteur indiquant le nombre de cibles trouvees sur le nombre total de cibles de cette emotion sur la planche.

Le praticien ou le patient selectionne une emotion dans la barre, ce qui definit l'emotion cible courante. Le patient tape les tetes qu'il pense exprimer cette emotion. Une tete correcte recoit un marqueur vert persistant, une tete d'une autre emotion recoit un marqueur rouge persistant, et un tap dans le vide n'a aucun effet. L'emotion courante peut etre changee a tout moment via la barre laterale, et tous les marqueurs deja poses restent affiches. Les compteurs de toutes les emotions restent visibles et se mettent a jour en temps reel.

Le marqueur rouge de faux positif devient persistant, alors qu'il disparaissait apres un court instant dans la version precedente. Ce changement permet au praticien de garder une trace visible des erreurs du patient pendant toute la planche.

Le bouton de fin indique s'il reste des cibles a trouver, tout en laissant le praticien libre de terminer la planche a tout moment.

## Decision sur la fin d'une planche

Quand le praticien termine une planche, le comportement depend de l'etat d'avancement. Si toutes les emotions ont ete entierement traitees, on passe directement a l'ecran de resultat. Si certaines emotions n'ont pas ete traitees ou pas terminees, un tableau a cases a cocher est presente au praticien pour qu'il selectionne les emotions sur lesquelles le patient doit etre evalue. Le score ne porte alors que sur les emotions cochees. Ce tableau n'apparait que lorsque la planche est incomplete ; il est omis si tout a ete fait.

Ce comportement conditionnel respecte le principe selon lequel on n'evalue le patient que sur les emotions qu'on lui a reellement fait chercher.

## Decision sur la structure d'une seance

Une seance porte sur un patient et peut comporter plusieurs planches jouees successivement. Apres avoir termine une planche, le praticien peut en lancer une autre ou terminer la seance. Les resultats de toutes les planches jouees sont accumules et transmis au PC en fin de seance via un unique QR de session.

## Decision sur le scoring et les donnees

Le score est calcule par emotion, puis agrege en un score global de planche. Pour chaque emotion, on conserve le nombre de cibles trouvees, le nombre total de cibles, le nombre de faux positifs et un score borne entre zero et cent. Le score global de la planche est la moyenne des scores des emotions retenues pour l'evaluation, soit toutes les emotions si la planche est complete, soit les emotions cochees si elle est incomplete.

Les donnees transmises au PC sont structurees par seance, par planche et par emotion. Le detail tap par tap reste collecte en memoire mais n'est pas transmis dans le QR, ce qui preserve la capacite du QR puisqu'on ne transmet que des compteurs et des scores. Cette structure par emotion permet au PC de constituer un suivi montrant les emotions sur lesquelles le patient rencontre des difficultes, ce qui est l'objectif clinique central de cette evolution.

## Consequences

La specification du jeu docs/specs/jeu_emotions.md est refondue pour decrire ce mode de navigation libre.

L'interface du jeu est refondue pour ajouter la barre laterale d'emotions avec compteurs en temps reel et afficher la planche en plein espace. La detection des taps et l'affichage de la planche, deja corriges precedemment, ne changent pas dans leur principe.

La structure de donnees evolue. Au lieu d'une partie portant une seule emotion, une planche jouee porte le resultat de plusieurs emotions, et une seance porte plusieurs planches. La persistance des planches jouees, volontairement differee dans l'ADR-09, sera traitee sur cette nouvelle structure une fois celle-ci stabilisee.

Cette decision n'introduit aucune nouvelle bibliotheque, ne modifie pas le canal de communication QR et respecte la souverainete des donnees, tout restant local. Elle est conforme a l'ADR-06 et constitue une evolution de la seule mecanique de jeu actee par l'ADR-08.

## Mise a jour de l'ADR-08

L'ADR-08 doit recevoir en tete une mention indiquant que sa section sur le mode de jeu est superseded par le present ADR-10, le reste de l'ADR-08 demeurant valide.
