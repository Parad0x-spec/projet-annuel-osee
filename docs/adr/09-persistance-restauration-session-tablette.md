# ADR-09 - Persistance et restauration du contexte de session sur la tablette

## Contexte

Le test interactif sur Lenovo Tab P12 a revele que lorsque l'application passe en arriere-plan puis revient, le patient charge et la partie en cours sont perdus et l'utilisateur se retrouve sur l'accueil vide. Le diagnostic par elimination a etabli que la cause est la destruction de l'application par Android en arriere-plan, suivie d'un redemarrage a froid. En effet l'etat de session vit uniquement en memoire dans des providers Riverpod montes a la racine et non autoDispose ; aucune recreation d'activite n'est possible sur changement de configuration puisque le manifest absorbe ces changements ; aucun mecanisme ne reinitialise l'etat tant que l'isolate Dart vit. La perte ne peut donc venir que de la destruction de l'isolate par le systeme, faute de quoi l'etat serait preserve. C'est le cas classique du recyclage memoire agressif d'une tablette a RAM modeste, accentue par un APK de debug gourmand en memoire.

La seule parade a une destruction par le systeme est la persistance de l'etat sur le stockage local, puis sa restauration au demarrage. Le maintien en memoire par keepAlive est inoperant ici puisque c'est la memoire elle-meme qui est detruite.

## Options envisagees

La premiere option est la restauration d'etat native de Flutter via RestorationMixin et restorationScopeId. Elle est concue pour l'etat de widgets et s'integre mal a un etat metier porte par des providers Riverpod, et ne couvre pas proprement la mort de process.

La deuxieme option est de persister l'integralite de l'etat de jeu, c'est-a-dire le patient charge, les parties terminees de la seance et la partie en cours avec son moteur (taps, indices trouves, horloge, score). Cette option est robuste mais lourde, et surtout elle porte sur des structures qui vont etre entierement refondues par la prochaine evolution du gameplay (barre laterale d'emotions, nouveau scoring). La persister maintenant reviendrait a ecrire un schema et une serialisation jetes au lot suivant.

La troisieme option est de persister uniquement le contexte de session, c'est-a-dire le patient charge et le drapeau mode demo, qui sont des donnees stables et independantes du gameplay et du scoring. Cette option est legere et ne sera pas chamboulee par la refonte.

## Option retenue

La troisieme option est retenue pour ce lot. Le contexte de session, soit les initiales, l'identifiant, le niveau demande du patient et le drapeau estDemo, est persiste dans la base SQLite locale de la tablette dans une nouvelle table contexte_session, sur le modele de la table appairage existante. Le schema passe de la version 1 a la version 2.

Le contexte est ecrit lors du chargement d'un patient, qu'il provienne du vrai flux de scan QR ou du mode demo, et il est efface lors de la reinitialisation de la session en fin de seance. Au demarrage de l'application, ce contexte est relu ; s'il existe, la session en cours est reamorcee et l'application route directement vers l'ecran de configuration de partie au lieu de l'accueil, afin que l'utilisateur retrouve son patient deja charge.

## Perimetre minimal assume

La partie en cours et les parties terminees de la seance ne sont volontairement pas persistees a ce stade. La raison est que leur structure va etre refondue avec le nouveau gameplay et le nouveau scoring ; les persister maintenant serait un travail jete. La consequence acceptee est qu'une partie a moitie jouee est perdue si le systeme detruit l'application au beau milieu d'une partie. Ce cas est rare et juge acceptable pour ce lot. La persistance des parties sera traitee dans un lot ulterieur, une fois la structure du gameplay stabilisee, et fera l'objet d'un ADR complementaire si necessaire.

## Consequences

Cette decision est une application concrete de l'ADR-03 qui retient SQLite comme stockage local versionne par migrations, dont elle constitue la deuxieme migration cote tablette. Elle reste conforme a l'ADR-06 sur la souverainete des donnees, puisque le contexte de session ne quitte jamais la tablette et n'est transmis par aucun canal reseau. Le contexte persiste reste anonyme cote tablette, conformement a la regle generale du projet selon laquelle la tablette ne contient jamais de donnee nominative.

Au prochain lot gameplay, lorsque la structure de partie sera figee, un ADR complementaire pourra etendre la persistance a la partie en cours et aux parties terminees, en reutilisant le mecanisme de table et de migration introduit ici.
