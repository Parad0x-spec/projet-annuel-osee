# Specification du jeu des emotions

## Note de version

Cette specification est refondue pour le mode de jeu a navigation libre entre emotions, acte par l'ADR-10 apres les premiers tests sur Lenovo Tab P12. Elle supersede les versions anterieures qui decrivaient un jeu a une seule emotion par partie.

## Objet

Le jeu des emotions est le premier contenu cognitif du projet, integre dans l'application tablette, destine a des patients suivis pour TDAH ou troubles du spectre autistique et encadres par un praticien qui pilote la seance.

Le format est inspire des livres "Ou est Charlie". Le patient voit une planche dense illustrant une scene sociale ou de nombreux enfants expriment chacun une emotion. Le patient cherche et tape les enfants exprimant l'emotion demandee. Le jeu travaille a la fois l'attention visuelle selective et la reconnaissance des emotions en contexte social.

## Banque de planches

La banque comprend quatre planches scenes de niveau equivalent, produites via ChatGPT et annotees manuellement. Elles representent toutes les quatre memes emotions et constituent un pool de variete pour eviter la memorisation. Elles sont au format JPG dans tablette_flutter/assets/planches/, chacune accompagnee d'un fichier JSON d'annotation listant les personnages avec coordonnees, rayon de zone cliquable et emotion.

Les quatre emotions du jeu sont la joie, la colere, la tristesse et la peur, identifiees dans le code par les chaines joie, colere, tristesse, peur.

## Deroulement d'une seance

Une seance porte sur un patient charge, qu'il provienne du vrai flux de scan QR ou du mode demo. Une seance peut comporter plusieurs planches jouees successivement.

Le praticien choisit une premiere planche et lance le jeu. Le patient joue sur cette planche en cherchant les differentes emotions. Quand la planche est terminee, le praticien peut en lancer une autre ou terminer la seance. Les resultats de toutes les planches jouees sont accumules et transmis au PC en fin de seance via un unique QR de session.

## Deroulement d'une planche jouee

Le praticien selectionne une planche. L'ecran de jeu affiche la planche en occupant le maximum d'espace disponible, avec le zoom et le defilement disponibles pour examiner les visages de pres. Une barre laterale presente les quatre emotions, chacune accompagnee d'un compteur indiquant le nombre de cibles trouvees sur le nombre total de cibles de cette emotion sur la planche.

Le praticien ou le patient selectionne une emotion dans la barre, ce qui definit l'emotion cible courante. La consigne affichee reflete cette emotion, par exemple "Trouve tous les enfants en colere". Le patient tape les tetes qu'il pense correspondre.

A chaque tap, l'application determine si les coordonnees tombent dans la zone cliquable d'un personnage annote. Si oui, elle compare l'emotion du personnage avec l'emotion cible courante. Si le personnage exprime l'emotion cible et n'a pas deja ete trouve, un marqueur vert avec une icone de validation est pose sur la tete et reste affiche jusqu'a la fin de la planche, et le compteur de cette emotion est incremente. Si le personnage exprime une autre emotion, un marqueur rouge avec une icone de croix est pose sur la tete et reste affiche, et le nombre de faux positifs est incremente. Si le tap ne tombe sur aucun personnage, rien ne se passe.

Le patient peut changer d'emotion cible a tout moment en selectionnant une autre emotion dans la barre laterale. Les marqueurs deja poses, verts comme rouges, restent affiches. Les compteurs de toutes les emotions restent visibles et a jour en permanence.

Le bouton de fin, intitule "J'ai fini", indique s'il reste des cibles a trouver. Tant que toutes les cibles de la planche ne sont pas trouvees, le bouton signale qu'il en reste, par exemple par un libelle ou un indicateur visuel distinct. Le praticien reste libre de terminer la planche meme s'il reste des cibles.

## Marqueurs persistants

Une difference importante avec la version precedente est que le marqueur rouge de faux positif reste affiche jusqu'a la fin de la planche, au lieu de disparaitre apres un court instant. Cela permet au praticien de garder une trace visible des erreurs commises par le patient pendant toute la planche. Les marqueurs verts de reussite restent egalement affiches comme avant.

## Fin d'une planche

Quand le praticien termine une planche via le bouton de fin, le comportement depend de l'etat d'avancement.

Si toutes les emotions de la planche ont ete entierement traitees, c'est-a-dire que toutes les cibles de toutes les emotions ont ete trouvees, on passe directement a l'ecran de resultat de la planche.

Si certaines emotions n'ont pas ete traitees ou pas terminees, un tableau a cases a cocher est presente au praticien. Ce tableau liste les quatre emotions et permet au praticien de cocher celles sur lesquelles il souhaite que le patient soit evalue. Cette possibilite respecte le principe selon lequel on n'evalue le patient que sur les emotions qu'on lui a reellement fait chercher. Le score de la planche ne portera que sur les emotions cochees. Ce tableau n'apparait que lorsque la planche est incomplete ; si tout a ete fait, il est inutile et donc omis.

## Calcul du score

Le score est calcule par emotion puis agrege.

Pour une emotion donnee, on note T le nombre de cibles trouvees pour cette emotion, R le nombre de cibles de cette emotion non trouvees, et F le nombre de faux positifs attribues a cette emotion, c'est-a-dire les fois ou le patient a tape une tete de cette emotion alors qu'une autre emotion etait ciblee, ou inversement selon la convention retenue a l'implementation. Le score par emotion suit la meme logique que la version precedente, soit une proportion de reussite diminuee d'une penalite pour les faux positifs, bornee entre zero et cent.

Le score global d'une planche est la moyenne des scores des emotions retenues pour l'evaluation, c'est-a-dire toutes les emotions si la planche est complete, ou seulement les emotions cochees dans le tableau de fin si la planche est incomplete.

Comme dans la version precedente, un affichage en etoiles de une a trois traduit le score pour le patient de maniere ludique et bienveillante, sans feedback negatif. Les seuils restent parametrables via une configuration centralisee.

## Donnees enregistrees et transmises au PC

Le detail tap par tap reste collecte en memoire pendant le jeu mais n'est pas transmis dans le QR, pour respecter la capacite limitee d'un QR.

Les donnees transmises au PC sont structurees par seance, par planche et par emotion. Au niveau de la seance, on transmet l'identifiant et les initiales du patient et le niveau demande recu du PC. Pour chaque planche jouee, on transmet le numero de la planche et, pour chaque emotion evaluee, le nombre de cibles trouvees, le nombre total de cibles, le nombre de faux positifs et le score de cette emotion, ainsi que le score global de la planche. On indique aussi quelles emotions ont ete retenues pour l'evaluation lorsque la planche etait incomplete.

Cette structure permet au PC de constituer un suivi fin montrant, planche par planche et emotion par emotion, l'evolution du patient et les emotions sur lesquelles il rencontre des difficultes. Le fichier de suivi cote PC exploite ces donnees sous forme de tableau et de diagramme.

## Ecrans et navigation

Apres chargement d'un patient et confirmation, le praticien accede a un ecran de choix de planche. Il selectionne une planche, ce qui lance l'ecran de jeu.

L'ecran de jeu affiche la planche au maximum de l'espace disponible avec zoom et defilement, la barre laterale des quatre emotions avec leurs compteurs en temps reel, la consigne de l'emotion courante, et le bouton de fin indiquant s'il reste des cibles.

A la fin d'une planche, soit l'ecran de resultat s'affiche directement si la planche est complete, soit le tableau de selection des emotions a evaluer s'affiche d'abord si la planche est incomplete, puis le resultat.

L'ecran de resultat de planche affiche le score en etoiles pour le patient et le detail par emotion, et propose de jouer une autre planche ou de terminer la seance.

A la fin de la seance, l'ecran recapitulatif liste les planches jouees avec leurs scores et propose de generer le QR de session contenant toutes les donnees accumulees, ou de quitter sans transferer. En mode demo, la generation du QR est desactivee.

## Considerations ergonomiques et accessibilite

Le rayon de la zone cliquable de chaque personnage est defini dans le JSON d'annotation, typiquement trente pixels, ajustable pour eviter les recouvrements. Les zones cliquables sont invisibles. Le zoom permet de viser precisement les petits visages sur les planches denses, ce qui est necessaire et a ete confirme indispensable lors des tests.

Les couleurs des marqueurs respectent un contraste suffisant, vert avec icone de validation et rouge avec icone de croix. L'orientation est verrouillee en paysage. Les retours sonores et haptiques sont une amelioration future non incluse dans cette version.

## Tests prevus

Les tests unitaires couvrent le chargement et le parsing des planches, la detection de tap, le suivi des compteurs par emotion, la logique de changement d'emotion cible, le calcul de score par emotion et global, la logique de fin de planche conditionnelle au tableau de selection, et la gestion d'une seance a plusieurs planches.

Les tests de widget couvrent l'ecran de choix de planche, l'ecran de jeu avec la barre laterale et la simulation de taps sur l'emotion courante, le changement d'emotion, le tableau de selection en cas de planche incomplete, l'ecran de resultat et le recapitulatif de seance.

Le test manuel sur Lenovo Tab P12 couvre l'ergonomie reelle de la barre laterale, la lisibilite des compteurs, la fluidite du zoom, la persistance des marqueurs, et le deroulement complet d'une seance a plusieurs planches avec transfert final au PC.

## Risques identifies

Le risque principal de cette refonte est l'ergonomie de la barre laterale sur l'ecran de la tablette, a valider en condition reelle. Le risque de justesse des annotations subsiste et fait l'objet d'un mode de verification visuelle des planches. L'equilibrage du scoring reste ajustable via la configuration centralisee apres les premiers tests reels.
