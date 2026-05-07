# Sprint 2 - Canal QR et appairage

## Objectif

Construire le système nerveux du projet : la communication entre la tablette et le PC via QR code. À la fin du sprint, deux choses fonctionnent de bout en bout. Premièrement, le PC peut générer un QR d'appairage que la tablette scanne avec sa caméra arrière, ce qui établit une clé partagée entre les deux applications. Deuxièmement, la tablette peut générer un QR de session de test que le PC scanne via webcam et décode correctement.

À la fin du sprint, on n'a pas encore de vraies données patient ni de jeu, on a juste prouvé que les deux mondes peuvent se parler de manière sûre et fiable.

## Pré-requis

La spécification du protocole QR doit être rédigée et validée avant toute ligne de code. Elle est dans `docs/specs/protocole_qr.md`. Sans cette spec, le risque est que la tablette et le PC implémentent des formats incompatibles et qu'on s'en rende compte trop tard.

Un ADR-04 sur le choix de la bibliothèque webcam Linux et Windows est dû en début de sprint, parce que la décision a été reportée au sprint 1.

La compilation croisée Go vers Windows doit être testée tôt dans le sprint pour ne pas accumuler de dette technique. Le binaire produit doit s'ouvrir sur une vraie machine Windows avec sa fenêtre Fyne, même si elle ne fait rien d'utile.

## Tâches du sprint

La première tâche est la rédaction de l'ADR-04 sur le choix webcam et décodage QR sous Linux et Windows. La règle CGO-free n'étant pas tenable pour la webcam, on doit acter explicitement la dérogation et choisir des bibliothèques qui croisent proprement vers Windows depuis Arch Linux.

La deuxième tâche est le test concret de la compilation croisée vers Windows du binaire actuel. On installe `mingw-w64-gcc` sur le poste Arch, on lance `./scripts/build_pc_windows.sh`, et on vérifie sur une machine Windows que la fenêtre Fyne s'ouvre. Si ça ne passe pas, on règle ça maintenant.

La troisième tâche est l'implémentation du module Go `internal/crypto` qui fournit la génération d'une paire de clés ed25519, la signature d'un payload, et la vérification d'une signature. Tests unitaires obligatoires.

La quatrième tâche est l'implémentation du module Go `internal/qr` côté PC qui produit le QR d'appairage. Le QR contient une clé publique ed25519 du PC plus un identifiant de session d'appairage. La fenêtre Fyne du logiciel PC affiche ce QR à la demande.

La cinquième tâche est l'implémentation côté tablette du scanner caméra arrière via `mobile_scanner`, du décodage du QR d'appairage, du stockage de la clé partagée dans SQLite, et d'un nouvel écran "Appairer avec le PC" accessible depuis l'écran d'accueil.

La sixième tâche est l'implémentation symétrique côté tablette du générateur de QR de test via `qr_flutter`, qui produit une charge utile signée avec la clé partagée.

La septième tâche est l'implémentation côté PC du scan webcam via la bibliothèque retenue par l'ADR-04, du décodage du QR de la tablette, et de la vérification de signature. La fenêtre Fyne affiche un message de confirmation quand le QR est correctement reçu et vérifié.

La huitième tâche est l'écriture des tests d'intégration de bout en bout du canal QR, en utilisant des fixtures d'images PNG de QR pour ne pas dépendre d'une vraie webcam dans la chaîne CI locale.

La neuvième tâche est la rédaction du compte rendu de sprint dans `docs/comptes_rendus/sprint_02.md`.

## Critères d'acceptation

Le sprint est validé quand on peut faire la démonstration suivante de bout en bout sur la Lenovo Tab P12 et un PC Windows. Le praticien ouvre le logiciel PC, clique sur "Afficher le QR d'appairage", la fenêtre affiche un QR. Le patient prend la tablette, ouvre l'application, clique sur "Appairer avec le PC", la caméra arrière scanne le QR affiché par le PC, un message de confirmation apparaît sur la tablette. La tablette propose alors un bouton "Envoyer un test au PC", au clic la tablette affiche son propre QR. Le praticien revient sur le PC, clique sur "Recevoir un test", la webcam scanne le QR de la tablette, le logiciel PC affiche un message de réception et de vérification de signature.

Tous les tests unitaires et d'intégration passent. Le binaire Windows compile et s'exécute. Aucune connexion réseau sortante n'est observable pendant la démonstration.

## Risques sur ce sprint

Le risque principal est la qualité du décodage webcam sous Windows, qui dépend du driver de la webcam du PC du praticien et de la lumière de la pièce. On le mitige par un éclairage convenable de la zone de scan et par un format de QR avec un niveau de correction d'erreur élevé.

Le second risque est la taille maximale d'un QR, environ 2950 caractères en mode alphanumérique pour un QR version 40 avec correction d'erreur basse, et beaucoup moins avec une correction élevée. La spec QR doit traiter explicitement ce point et prévoir un découpage en plusieurs QR successifs si nécessaire dès maintenant, même si la première session de test ne le déclenche pas.

Le troisième risque est la cinématique d'appairage qui doit être idiot-proof pour le praticien. Si le scan échoue, le message d'erreur doit être clair et la procédure de réessai évidente.
