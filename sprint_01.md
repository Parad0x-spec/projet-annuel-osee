# Sprint 1 - Amorçage technique

## Objectif

Mettre en place les fondations techniques du projet pour que les sprints suivants puissent se concentrer sur la fonctionnalité. Cela inclut la création du dépôt local, l'initialisation des deux sous-projets Flutter et Go, la mise en place de la documentation projet et de Claude Code, et la production de deux applications minimales qui buildent et démarrent sur leurs cibles respectives.

## Pré-requis poste de développement

Sur le poste Arch Linux il faut le SDK Flutter avec une version stable récente et l'Android SDK avec les outils de plateforme. Il faut le toolchain Go en version 1.22 ou supérieure. Il faut Git pour le versionning local. Il faut un câble USB et le mode développeur activé sur la Lenovo Tab P12 pour pouvoir installer et tester l'APK. Il faut MinGW ou un toolchain équivalent si la bibliothèque Fyne nécessite des dépendances C pour la compilation croisée Windows.

## Tâches du sprint

La première tâche est la création du dépôt dans `/home/cengi/projects/projet_annuel/` avec un dépôt Git initialisé localement, un fichier `.gitignore` couvrant les artefacts Flutter et Go, et l'arborescence de documentation telle que définie dans le `CLAUDE.md` racine.

La deuxième tâche est l'initialisation du sous-projet Flutter via `flutter create tablette_flutter` avec les options pour cibler uniquement Android, puis la configuration du `pubspec.yaml` pour préparer les futures dépendances QR, caméra et SQLite sans encore les implémenter. L'écran d'accueil affiche un titre et un bouton qui ouvre un écran vide de futur jeu.

La troisième tâche est l'initialisation du sous-projet Go via `go mod init projet_annuel/logiciel_pc_go` dans le dossier `logiciel_pc_go/`, l'ajout de la dépendance Fyne, et la production d'une fenêtre minimale qui s'ouvre avec un titre et un bouton placeholder pour le futur scan webcam.

La quatrième tâche est la rédaction du `CLAUDE.md` de chaque sous-projet, qui détaille pour Claude Code les conventions spécifiques à ce sous-projet, les bibliothèques retenues et les patterns à suivre.

La cinquième tâche est la mise en place d'un script `scripts/build_pc_windows.sh` qui automatise la compilation croisée du binaire Windows depuis Arch Linux, et d'un script `scripts/build_apk.sh` qui automatise le build et l'installation de l'APK sur la tablette connectée.

La sixième tâche est la rédaction du compte rendu de sprint dans `docs/comptes_rendus/sprint_01.md`.

## Critères d'acceptation

Le sprint est validé quand un `git log` montre les commits attendus, quand `flutter run` lance l'application sur la Lenovo Tab P12 et affiche son écran d'accueil, quand l'exécution du script de build Windows produit un fichier `.exe` qui démarre sur une machine Windows et affiche sa fenêtre, quand les fichiers `CLAUDE.md` racine et par sous-projet sont en place, quand les trois ADR sont rédigés, et quand le compte rendu de sprint est écrit.

## Risques sur ce sprint

Le risque principal est l'environnement de compilation croisée de Fyne qui peut nécessiter des paquets supplémentaires sur Arch Linux notamment `mingw-w64-gcc`. Si la compilation croisée pose problème, un repli est de développer initialement le PC sous Linux et de reporter le passage Windows en fin de sprint 4. Le second risque est la version de Flutter SDK et la compatibilité avec Android 13 sur la Tab P12, à vérifier dès le premier déploiement.
