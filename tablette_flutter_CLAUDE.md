# CLAUDE.md - Sous-projet tablette Flutter

## Contexte

Ce sous-projet contient l'application Flutter installée sur la Lenovo Tab P12 sous Android 13. Elle est utilisée par le patient pendant la séance, sous la supervision du praticien. Elle propose un jeu de reconnaissance des émotions, stocke localement les métriques de chaque session, et permet d'exporter ces métriques vers le PC du praticien par génération d'un QR code scanné via webcam.

Le `CLAUDE.md` racine du dépôt définit les règles globales du projet. Ce fichier complète ces règles avec les spécificités Flutter.

## Stack et paquets retenus

Le projet utilise Flutter 3.41 et Dart 3.11. Le SDK minimum Android est 33 pour cibler la Tab P12 sans embarquer d'anciennes API inutiles. Les paquets retenus sont les suivants. Pour la génération de QR à afficher, le paquet `qr_flutter`. Pour le scan de QR par caméra arrière, le paquet `mobile_scanner`. Pour le stockage local SQLite, le paquet `sqflite` accompagné de `path_provider` pour résoudre le chemin de la base. Pour la gestion d'état, le paquet `flutter_riverpod` qui est plus léger que `bloc` et suffisant pour la taille du projet. Pour les routes, le paquet `go_router`. Pour la cryptographie utilisée dans la signature des QR sortants, le paquet `cryptography`.

Aucun autre paquet ne doit être ajouté sans création préalable d'un ADR justifiant le choix.

## Architecture côté tablette

Le code est organisé sous `lib/` selon une séparation par couche fonctionnelle. Le dossier `lib/main.dart` est le point d'entrée minimal qui configure les providers et démarre l'application. Le dossier `lib/app/` contient le shell applicatif, le routage et les thèmes. Le dossier `lib/features/` contient un sous-dossier par fonctionnalité métier, à savoir `appairage/` pour le scan du QR du PC, `profil_patient/` pour la création de profil, `jeu_emotions/` pour le jeu, et `export_session/` pour la génération du QR à scanner par le PC. Le dossier `lib/core/` contient les éléments transverses comme l'accès SQLite, la cryptographie et le format de données partagé. Le dossier `lib/shared_widgets/` contient les composants graphiques réutilisables comme les boutons à grosse taille tactile et les cartes patient.

Chaque feature suit la même structure interne. Un fichier `domain.dart` qui définit les types métier purs. Un fichier `data.dart` qui contient les accès au stockage et aux services. Un fichier `controller.dart` qui contient les providers Riverpod. Un dossier `ui/` qui contient les écrans et widgets propres à la feature.

## Conventions Flutter spécifiques

L'interface est conçue tablette en orientation paysage, avec des cibles tactiles d'au moins 80 pixels de côté pour être adaptées à des enfants. Les couleurs respectent un contraste suffisant. Les sons sont systématiquement accompagnés d'un retour visuel équivalent pour ne pas dépendre du son seul. Aucune publicité, aucune connexion réseau, aucune analytique.

Les widgets sont construits en `StatelessWidget` ou `ConsumerWidget` Riverpod. L'usage de `setState` est limité aux cas où l'état est strictement local au widget et n'a pas vocation à être partagé. Les fonctions asynchrones renvoient des `Future` typés explicitement, jamais `Future<dynamic>`.

Les chaînes affichées à l'utilisateur sont placées dans un fichier de constantes `lib/core/textes.dart` pour faciliter une internationalisation future et éviter les chaînes en dur dans le code des widgets.

## Tests

Les tests unitaires sont écrits avec `flutter_test` et sont placés dans `test/` en miroir de l'arborescence `lib/`. Les tests de widget utilisent `flutter_test` et se concentrent sur les écrans clés du jeu et sur l'écran de création de profil. Les tests d'intégration utilisant `integration_test` sont prévus pour le canal QR et seront ajoutés au sprint 2.

La commande de référence est `flutter test`. Aucun commit ne casse les tests existants.

## Build

L'APK de debug se construit par `flutter build apk --debug` et s'installe par `flutter install`. L'APK release nécessite une configuration de signature qui sera ajoutée plus tard, hors périmètre du sprint 1.

## Règle de validation par étapes

La règle de validation par étapes du `CLAUDE.md` racine s'applique strictement ici. Tu ne fais qu'une seule chose à la fois, tu décris ce que tu as fait et tu attends confirmation avant de passer à la suite.
