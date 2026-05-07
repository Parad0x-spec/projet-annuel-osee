# ADR-03 - SQLite pour le stockage local des deux applications

## Contexte

Les deux applications doivent stocker des données localement et de manière persistante. Côté tablette, il s'agit du profil patient anonymisé, des sessions de jeu et des métriques associées. Côté PC, il s'agit des fiches patients nominatives, du lien entre identifiant anonyme et nom complet, et des sessions agrégées reçues depuis les tablettes. Aucune donnée n'est partagée par réseau, l'échange est manuel par QR.

## Options envisagées

La première option est SQLite. C'est une base de données embarquée stockée dans un fichier unique, sans serveur, parfaitement adaptée à un usage mono-utilisateur. Elle est extrêmement bien supportée à la fois en Flutter via le paquet `sqflite` et en Go via les pilotes `mattn/go-sqlite3` ou `modernc.org/sqlite`. La seconde option est un stockage par fichiers JSON. Elle est simple mais devient pénible dès que l'on veut requêter par patient, agréger des sessions ou faire évoluer le schéma. La troisième option est une base orientée document type BoltDB ou BadgerDB côté Go. Elle est performante mais ne se prête pas aux requêtes relationnelles dont a besoin le suivi par patient sur de multiples sessions.

## Option retenue

SQLite est retenu des deux côtés. Le schéma sera versionné par migrations.

## Conséquences

Côté tablette le fichier SQLite est stocké dans le répertoire privé de l'application Flutter, inaccessible aux autres applications Android par le cloisonnement standard. Côté PC le fichier SQLite est stocké dans le dossier utilisateur du praticien, dans un emplacement qu'il connaît pour pouvoir le sauvegarder ou le copier. La cohérence des schémas et la documentation des migrations est tenue dans `docs/specs/schemas_donnees.md` qui sera créé au sprint 3.
