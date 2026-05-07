# Instructions pour la première session Claude Code

Ce document explique pas à pas comment dérouler le sprint 1 avec Claude Code. Il contient les prompts exacts à coller, les points d'arrêt où tu dois vérifier ce qu'il a fait, et les commandes à lancer toi-même pour tester.

L'idée directrice est de ne jamais laisser Claude Code dérouler plus d'une étape sans validation. À chaque étape tu lis ce qu'il a produit, tu testes, et seulement ensuite tu passes à la suivante.

## Avant de lancer Claude Code

Tu dois avoir, dans ton dossier `~/Documents/Projets/Projet_Annuel_2025-2026/`, déposé tous les fichiers de documentation que je t'ai livrés, à savoir le `CLAUDE.md` racine, le `README.md`, le `.gitignore`, le dossier `docs/` complet avec ses sous-dossiers, le dossier `scripts/` avec les deux scripts, et les deux fichiers `tablette_flutter_CLAUDE.md` et `logiciel_pc_go_CLAUDE.md` que tu vas déplacer dans leurs sous-dossiers respectifs au cours du sprint.

Tu dois aussi avoir initialisé Git par `git init` puis `git add . && git commit -m "docs: initialiser cadrage projet"`.

Tu rends les scripts exécutables par `chmod +x scripts/build_apk.sh scripts/build_pc_windows.sh`.

Une fois cela fait, place-toi dans le dossier du projet et lance `claude`.

## Étape 1 - Initialiser le sous-projet Flutter

Colle ce prompt dans Claude Code :

```
Lis le CLAUDE.md racine. Nous sommes au sprint 1.

Premiere tache : initialiser le sous-projet Flutter.

1. Cree le sous-dossier tablette_flutter en lancant la commande Flutter d'initialisation, en ciblant uniquement Android, et en utilisant comme nom d'organisation com.projet_annuel.

2. Une fois le projet initialise, deplace le fichier tablette_flutter_CLAUDE.md qui est a la racine vers tablette_flutter/CLAUDE.md.

3. Modifie pubspec.yaml pour ajouter les paquets retenus selon le CLAUDE.md du sous-projet, mais ne les utilise pas encore dans le code.

4. Verifie que flutter pub get passe sans erreur.

Arrete-toi a la fin de cette tache, decris ce que tu as fait, et attends ma validation explicite avant toute autre action.
```

Quand Claude Code aura fini, tu vérifies par toi-même :

```
ls tablette_flutter/
cat tablette_flutter/pubspec.yaml
cat tablette_flutter/CLAUDE.md | head -20
```

Tu dois voir l'arborescence Flutter standard, le pubspec avec les paquets `qr_flutter`, `mobile_scanner`, `sqflite`, `path_provider`, `flutter_riverpod`, `go_router` et `cryptography`, et le `CLAUDE.md` à sa place.

Tu commits ce qui a été fait :

```
git add tablette_flutter/
git commit -m "tablette: initialiser sous-projet Flutter"
```

Tu valides à Claude Code en disant simplement `Valide, passe a la tache suivante.`

## Étape 2 - Squelette d'écran d'accueil tablette

Prompt à coller :

```
Tache 2 : creer un ecran d'accueil minimal pour la tablette.

L'ecran d'accueil affiche en grand le titre "Atelier d'entrainement", et trois boutons en colonne, "Nouveau patient", "Patient existant", et "Parametres". Aucun bouton n'a encore de logique, ils peuvent simplement afficher une SnackBar avec le nom du bouton.

Utilise go_router pour declarer une seule route racine, meme si on a qu'un ecran. Cela prepare la suite.

Le code respecte les conventions du CLAUDE.md du sous-projet : aucun commentaire, noms explicites, chaines en francais centralisees dans lib/core/textes.dart.

Ecris egalement un test de widget minimal qui verifie que les trois boutons sont presents a l'ecran.

Arrete-toi, decris ce que tu as fait, et attends validation.
```

Tu vérifies :

```
flutter test
```

Le test doit passer. Tu lances ensuite l'application sur la tablette branchée :

```
./scripts/build_apk.sh
```

Tu vois l'écran d'accueil avec les trois boutons. Tu cliques dessus, ça affiche les SnackBar. Tu commits :

```
git add tablette_flutter/
git commit -m "tablette: ajouter ecran accueil et test widget"
```

Et tu valides à Claude Code.

## Étape 3 - Initialiser le sous-projet Go

Prompt :

```
Tache 3 : initialiser le sous-projet Go logiciel_pc_go.

1. Cree le sous-dossier logiciel_pc_go avec go mod init projet_annuel/logiciel_pc_go.

2. Deplace le fichier logiciel_pc_go_CLAUDE.md qui est a la racine vers logiciel_pc_go/CLAUDE.md.

3. Cree la structure cmd/logiciel_pc/ et internal/ui/.

4. Ajoute la dependance Fyne v2 et ecris dans cmd/logiciel_pc/main.go un programme minimal qui ouvre une fenetre Fyne intitulee "Suivi patients" et affiche un label "Logiciel praticien".

5. Verifie que go build ./cmd/logiciel_pc passe sans erreur sous Linux.

Arrete-toi, decris ce que tu as fait, et attends validation.
```

Tu vérifies :

```
cd logiciel_pc_go
go run ./cmd/logiciel_pc
```

Une fenêtre s'ouvre avec le titre et le label. Tu fermes. Tu testes la compilation croisée :

```
cd ..
./scripts/build_pc_windows.sh
```

Le binaire `logiciel_pc_go/build/logiciel_pc.exe` est produit. Tu commits :

```
git add logiciel_pc_go/
git commit -m "pc: initialiser sous-projet Go avec fenetre Fyne minimale"
```

Et tu valides à Claude Code.

## Étape 4 - Compte rendu de sprint

Prompt :

```
Tache 4 : rediger le compte rendu du sprint 1.

Cree le fichier docs/comptes_rendus/sprint_01.md selon les conventions du CLAUDE.md racine, c'est-a-dire en prose sans liste a puces.

Le compte rendu couvre les objectifs initiaux du sprint, ce qui a ete realise concretement, les decisions prises au passage, et les points qui restent ouverts pour le sprint 2 notamment l'integration des paquets caméra et SQLite cote tablette et le module QR cote PC.

Apres ecriture, propose un commit avec ce fichier.
```

Tu relis le compte rendu, tu corriges si besoin, tu commits.

## Fin du sprint 1

À ce stade tu as :

Une arborescence projet propre avec documentation complète. Une application Flutter qui démarre sur ta Lenovo Tab P12 avec un écran d'accueil et un test qui passe. Une application Go qui compile en `.exe` Windows et qui affiche une fenêtre Fyne. Un Git avec un historique de commits clair. Un compte rendu de sprint écrit.

Tu peux te reposer, tu reviens me voir avec le résultat et on enchaîne sur le sprint 2 qui attaquera le canal QR.

## Si quelque chose se passe mal

Si Claude Code propose autre chose que ce qui est demandé, par exemple s'il veut ajouter un paquet non listé ou s'il commence à dérouler plusieurs étapes, tu lui dis simplement `Stop, tu sors du cadre. Reprends la tache demandee uniquement, et arrete-toi en fin de tache.`

Si une commande échoue de ton côté, tu colles l'erreur dans Claude Code et tu lui demandes de la corriger. Tu ne touches rien manuellement sans avoir compris ce qu'il propose.

Si tu es perdu, tu fermes Claude Code, tu reviens ici, tu me décris ce qui se passe et on reprend ensemble.
