# CLAUDE.md - Projet annuel

## Contexte projet

Ce dépôt contient deux applications complémentaires destinées à un praticien travaillant avec des patients TDAH ou autisme. La première application tourne sur tablette Android Lenovo Tab P12 et est utilisée par le patient pendant la séance pour jouer à des jeux d'entraînement cognitif. La seconde application tourne sur PC Windows et est utilisée par le praticien pour gérer les fiches patients et suivre l'évolution séance après séance.

Les deux applications ne communiquent jamais par internet. L'échange se fait uniquement par scan de QR code, soit le PC qui affiche un QR scanné par la tablette pour l'appairage, soit la tablette qui affiche un QR scanné par la webcam du PC pour transférer les données de séance.

La présentation du projet est prévue fin juin. Le périmètre fin juin est volontairement réduit à un seul jeu, la reconnaissance des émotions sur des visages.

## Emplacement local du projet

Le dépôt est situé dans `~/Documents/Projets/Projet_Annuel_2025-2026/` sur un poste de développement Arch Linux.

## Stack technique

L'application tablette est en Flutter 3.41 ciblant Android 13. Le logiciel PC est en Go 1.26 ciblant Windows par compilation croisée depuis Arch Linux. Le stockage local est SQLite des deux côtés. La génération et la lecture de QR utilisent une bibliothèque Flutter côté tablette et une bibliothèque Go côté PC. Aucun backend serveur, aucune API REST, aucune dépendance réseau autre que le protocole QR.

## Arborescence du dépôt

```
Projet_Annuel_2025-2026/
    CLAUDE.md                       fichier que tu lis en premier
    README.md                       presentation generale du depot
    .gitignore                      exclusions Flutter et Go
    docs/
        cadrage/                    note de cadrage et plan
        sprints/                    plans detailles de chaque sprint
        adr/                        decisions d'architecture
        specs/                      specifications fonctionnelles et techniques
        comptes_rendus/             compte rendu en fin de chaque sprint
    tablette_flutter/               application Flutter Android
        CLAUDE.md                   contexte specifique tablette
        lib/
        test/
        pubspec.yaml
    logiciel_pc_go/                 application Go Windows
        CLAUDE.md                   contexte specifique PC
        cmd/
        internal/
        go.mod
    shared/
        protocole_qr/               format de donnees commun documente
    scripts/
        build_apk.sh                build et installation Flutter sur tablette
        build_pc_windows.sh         compilation croisee Go vers Windows
```

## Règles de fonctionnement avec Claude Code

À chaque session, lis ce fichier en premier puis lis le `CLAUDE.md` du sous-projet sur lequel tu travailles. Avant d'écrire du code, vérifie qu'un ADR couvre la décision technique sous-jacente. Si ce n'est pas le cas, propose un ADR avant l'implémentation. Après chaque session de travail significative, mets à jour le compte rendu de sprint en cours dans `docs/comptes_rendus/sprint_NN.md` avec ce qui a été fait, les décisions prises et ce qui reste à faire.

Pour toute modification de code écris d'abord les tests, puis l'implémentation. Les tests unitaires sont obligatoires pour toute logique métier. Les tests d'intégration sont obligatoires pour le canal QR et pour l'accès SQLite.

Le code ne contient pas de commentaires. La documentation est dans les fichiers `.md` du dossier `docs/`. Les noms de variables, fonctions et types sont suffisamment explicites pour que le code soit lisible sans commentaire. Les messages utilisateur sont en français. Les noms techniques dans le code sont en anglais.

## Règles de sécurité et confidentialité

La tablette ne contient jamais de donnée nominative. Un patient est identifié par ses initiales saisies par le praticien et par un identifiant aléatoire généré au moment de la création du profil. Le rapprochement entre cet identifiant et le nom complet n'existe que côté PC dans la base du praticien.

Aucune donnée n'est envoyée vers un serveur externe. Aucune télémétrie. Aucune analyse d'usage. Toute connexion sortante détectée pendant le développement est un bug à corriger immédiatement.

Les données échangées par QR sont signées cryptographiquement avec une clé partagée établie lors de l'appairage initial, pour empêcher l'injection de fausses sessions.

## Conventions de commit

Les commits suivent une forme courte en français commençant par un verbe à l'infinitif et précisant le périmètre. Exemples acceptables : `tablette: ajouter ecran creation profil patient`, `pc: implementer scan webcam du QR session`, `docs: rediger ADR-04 stockage SQLite`. Les commits sur le code sont accompagnés d'un commit ou d'une mise à jour de la documentation correspondante quand pertinent.

## Convention pour les ADR

Chaque ADR est un fichier `docs/adr/NN-titre-court.md`. Il contient le contexte de la décision, les options envisagées, l'option retenue, et les conséquences. Un ADR n'est jamais modifié une fois validé, il est remplacé par un nouvel ADR qui le supersède.

## Convention pour les comptes rendus

Chaque sprint a un fichier `docs/comptes_rendus/sprint_NN.md`. Il contient les objectifs initiaux, ce qui a été réellement fait, les décisions prises en cours de sprint, les défauts identifiés et les actions à reporter au sprint suivant. Le compte rendu est rédigé en prose, sans liste à puces.

## Règle de validation par étapes

Tu ne déroules jamais plusieurs tâches d'affilée sans validation. À la fin de chaque tâche tu t'arrêtes, tu décris ce que tu as fait et ce que la prochaine étape va faire, et tu attends une confirmation explicite avant de continuer. Cette règle est non négociable, elle existe pour que le porteur du projet reste maître de son code et puisse expliquer chaque décision en soutenance.

## État courant du projet

Sprint 1 en cours, phase d'amorçage technique. Les sous-projets Flutter et Go ne sont pas encore initialisés. La documentation de cadrage est en place dans `docs/cadrage/`.
