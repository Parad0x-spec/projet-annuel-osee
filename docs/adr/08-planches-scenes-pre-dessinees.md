# ADR-08 - Planches scenes pre-dessinees pour le jeu des emotions

## Contexte

La specification initiale du jeu des emotions, redigee avant le sprint 3 et mise a jour apres le recalibrage de l'ADR-07, prevoyait une mecanique de composition de planche a la volee. Le principe etait de stocker une banque de visages individuels (huit variantes par emotion, format PNG 200x200 transparent, rangees dans assets/visages/<emotion>/) et de composer dynamiquement chaque planche du jeu en tirant aleatoirement les visages necessaires selon le niveau de difficulte.

Au moment d'attaquer concretement la tache 7 (constitution de la banque d'images), une recherche d'images plus realistes a fait emerger un autre modele : la planche scene complete pre-dessinee dans le style "Ou est Charlie". Au lieu d'une grille de visages individuels composee a la volee, on dispose d'une seule image illustrant une scene (un parc avec des enfants qui jouent, font la fete, se disputent), avec dans cette scene de nombreux personnages exprimant chacun une emotion differente. Le patient doit alors trouver dans la scene les personnages correspondant a la consigne.

L'evaluation du modele a ete faite par la production d'une planche test sur ChatGPT (image-1), avec un prompt detaille decrivant une scene de parc denses contenant des personnages exprimant les emotions de base. Le resultat est superieur a l'approche grille sur plusieurs points cliniques et techniques, ce qui motive le changement de cap.

## Options envisagees

La premiere option etait de conserver la mecanique de grille composee a la volee, avec une banque de visages individuels. Cette option a l'avantage d'etre algorithiquement plus flexible (chaque planche est differente, on peut faire varier le nombre de cibles, le nombre de distracteurs, etc.) et de demander un travail de production limite (huit variantes par emotion suffisent). Elle a ete ecartee pour les raisons developpees dans la section suivante.

La seconde option, retenue, est de passer a un modele de planches scenes pre-dessinees. Une planche scene est une image unique illustrant un contexte (un parc, une fete, une classe, une plage) dans laquelle de nombreux enfants sont representes avec chacun une emotion definie. Le jeu utilise un nombre fini de planches (trois pour la premiere version), chacune annotee avec les coordonnees de chaque personnage et l'emotion qu'il exprime. Le patient explore visuellement la scene et clique sur les personnages correspondant a la consigne.

La troisieme option envisagee etait un modele hybride avec des scenes pre-dessinees comme decor de fond et des visages composes par dessus. Elle a ete ecartee comme techniquement plus complexe sans apporter d'avantage clinique majeur par rapport au modele de planches pre-dessinees.

## Option retenue

Le modele de planches scenes pre-dessinees est retenu pour la premiere version du jeu, qui sera celle presentee en soutenance.

Trois planches sont produites pour cette premiere version, correspondant aux trois niveaux de difficulte du jeu. La planche de niveau 1 illustre une scene aeree avec quatre emotions de base (joie, colere, tristesse, surprise) clairement lisibles. La planche de niveau 2 illustre une scene plus dense avec cinq emotions (ajout de la peur) et davantage de personnages. La planche de niveau 3 illustre la scene la plus dense avec six emotions (ajout du degout), des distracteurs et des expressions plus subtiles.

Chaque planche est produite via le service de generation d'images de ChatGPT (Image-1 ou equivalent) a partir d'un prompt detaille en francais. Le prompt specifie le contexte (un parc, une fete...), le nombre approximatif de personnages, la liste des emotions a representer, l'instruction d'expressions faciales tres lisibles et exagerees, et l'absence de bulles BD ou de smileys flottants pour conserver le realisme de la scene.

Chaque planche est ensuite annotee manuellement par le developpeur du projet, ce qui consiste a marquer pour chaque personnage de la planche ses coordonnees x et y dans l'image et l'emotion qu'il exprime. Cette annotation est stockee dans un fichier JSON associe a la planche, sous la forme d'une liste d'objets contenant les champs x, y, rayon et emotion. Pour faciliter ce travail, un outil HTML d'annotation est livre dans le projet sous outils/annotateur_planche.html, qui permet de charger une planche et de cliquer sur chaque visage pour generer le JSON automatiquement.

Les emotions retenues pour le jeu sont, par ordre d'introduction dans les niveaux : joie, colere, tristesse, surprise pour le niveau 1, peur ajoutee au niveau 2, degout ajoute au niveau 3. Ce sont les six emotions universelles identifiees par Paul Ekman dans ses travaux sur la communication non verbale, qui constituent le socle de la communication emotionnelle humaine.

## Justification du changement

Le modele de planches pre-dessinees est superieur sur plusieurs dimensions.

Sur le plan clinique, l'objectif du jeu est de developper la reconnaissance des emotions chez l'enfant TDAH ou autiste, dans une visee de transfert vers les situations sociales reelles. Une grille de visages individuels alignes presente les emotions hors contexte, ce qui ne correspond pas a la vie reelle ou les emotions sont toujours percues dans une scene sociale globale. Une planche scene reproduit au contraire un contexte social riche, ou plusieurs enfants interagissent, ressentent des emotions liees a leur situation, et ou l'enfant patient doit scanner cette scene comme il scannerait une scene de cour de recreation. C'est cliniquement plus pertinent et plus transferable.

Sur le plan de la production, la grille de visages composes a la volee aurait demande huit variantes par emotion soit quarante-huit images individuelles a generer et a maintenir coherentes entre elles en termes de style, d'eclairage et de cadrage. Une planche scene unique resout ce probleme par construction : tous les personnages sont dans le meme style puisqu'ils sont dans la meme image, l'eclairage et la coherence visuelle sont naturels. Le travail de production passe de quarante-huit images individuelles a trois planches scenes, plus l'effort d'annotation manuelle.

Sur le plan de la propriete intellectuelle et de l'ethique, le modele de planches pre-dessinees ne represente pas d'enfants reels. Les personnages sont des illustrations cartoon clairement non realistes, ce qui evite tout risque de confusion avec une personne reelle, de droit a l'image, ou de declenchement de souvenirs personnels chez le patient lors d'une seance. C'est conforme a la posture ethique du projet et a l'esprit de l'ADR-06 sur la souverainete des donnees.

Sur le plan technique, le modele de planches pre-dessinees simplifie aussi l'implementation. La logique metier devient simplement : charger une planche selon le niveau, charger son JSON d'annotation, afficher la planche dans un canvas scrollable, detecter les clics aux coordonnees annotees, comparer l'emotion clic vs l'emotion consigne, mettre a jour le score. Pas de composition aleatoire, pas de placement pseudo-random de visages, pas de calcul de densite. Le code est plus simple et plus testable.

## Consequences

La specification du jeu des emotions docs/specs/jeu_emotions.md est mise a jour en consequence, avec une refonte de la section sur la banque d'images et de la section sur la logique metier. La structure des niveaux est simplifiee de cinq a trois niveaux.

La structure des assets dans le projet evolue. Au lieu de tablette_flutter/assets/visages/<emotion>/ avec plusieurs PNG par dossier, on a tablette_flutter/assets/planches/ qui contient pour chaque planche son image (planche_1.png, planche_2.png, planche_3.png) et son fichier d'annotation (planche_1.json, planche_2.json, planche_3.json).

La logique metier du jeu, qui faisait l'objet de la tache 8 dans le plan initial du sprint 3, change de nature. Au lieu de composer une planche aleatoire selon le niveau, elle charge la planche correspondant au niveau, lit son annotation, et orchestre les manches. Cette tache reste dans le perimetre du sprint 3 mais sa specification est mise a jour.

L'interface graphique du jeu, qui faisait l'objet de la tache 10, change egalement. Au lieu d'une grille pseudo-aleatoire de cellules contenant des visages, on a un canvas Flutter scrollable affichant la planche complete, avec des zones cliquables invisibles aux coordonnees annotees. Plus simple a implementer.

Le travail de production des trois planches et de leur annotation est ajoute au perimetre du sprint 3 comme une tache prealable a la tache 8. Cette production est faite par le developpeur du projet hors session de code, avec l'aide de l'outil d'annotation HTML livre dans outils/.

Cette decision est compatible avec les ADR precedents. Elle ne contredit pas l'ADR-05 sur les bibliotheques retenues puisqu'aucune nouvelle bibliotheque n'est introduite (juste un changement de modele de donnees). Elle reste conforme a l'ADR-06 sur la souverainete des donnees puisque les planches generees par ChatGPT sont des images statiques embarquees dans l'APK, sans aucune communication runtime avec un service externe.

La possibilite d'evoluer vers une banque enrichie post-soutenance reste ouverte. On pourra ajouter de nouvelles planches au fil du temps en suivant le meme processus de production et d'annotation, ou meme mixer le modele actuel avec une mecanique d'adaptation automatique de difficulte cote PC en suggerant la planche en fonction de l'historique du patient. Ces evolutions sont hors perimetre soutenance mais documentees comme pistes possibles.
