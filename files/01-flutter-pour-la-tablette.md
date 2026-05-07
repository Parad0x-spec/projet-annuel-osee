# ADR-01 - Flutter pour l'application tablette

## Contexte

L'application tablette doit tourner sur une Lenovo Tab P12 sous Android 13. Elle doit afficher des jeux avec un retour visuel temps réel, capturer des évènements tactiles, accéder à la caméra pour scanner un QR code, générer un QR code à afficher, et stocker localement les données de session. Le développement se fait depuis un poste sous Arch Linux et doit produire un APK installable sur la tablette.

## Options envisagées

La première option est Kotlin natif avec Android Studio. Elle offre la performance maximale et l'accès direct à toutes les API Android, mais elle est plus longue à développer dans le temps imparti et oblige à gérer manuellement les écrans tactiles et la stack de rendu. La seconde option est Flutter avec Dart. Elle propose un rendu performant via Skia, des bibliothèques toutes faites pour la caméra et les QR codes, un développement rapide, et un build APK direct depuis Linux. La troisième option est React Native. Elle est moins bien adaptée à un rendu temps réel de jeu et impose un pont JavaScript qui complique le profilage des performances.

## Option retenue

Flutter est retenu pour la rapidité de développement, la qualité du rendu pour des interfaces de jeu simples, la bonne disponibilité des bibliothèques caméra et QR, et la maîtrise existante du framework dans des projets antérieurs.

## Conséquences

Le langage de la tablette est Dart. La stack mobile dépend du SDK Flutter qui doit être installé sur le poste de développement. Le build est fait par `flutter build apk` et l'installation par `adb install`. La maintenance future bénéficie d'un seul codebase si une cible iOS devait être ajoutée ultérieurement, ce qui n'est pas prévu pour cette livraison.
