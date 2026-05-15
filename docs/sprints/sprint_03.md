# Sprint 3 - Jeu des émotions et création patient côté PC

## Objectif

Livrer le premier jeu cognitif complet sur la tablette, et implémenter côté PC le minimum nécessaire pour créer un patient et générer son QR de séance. À la fin du sprint, le scénario suivant doit fonctionner de bout en bout : le praticien crée un patient sur le PC, génère son QR, le scanne avec la tablette, lance le jeu des émotions, joue une session, exporte les données par QR retour, et le PC stocke les métriques rattachées au bon patient.

Le sprint 4 enrichira ensuite le côté PC avec les fiches patients détaillées, le graphique d'évolution, et la génération du fichier Excel mère.

Ce plan révisé succède au plan initial du sprint 3 daté d'avant le recalibrage tracé dans l'ADR-07. La spec du jeu des émotions reste valide en l'état, c'est principalement la partie identification patient qui change : elle est entièrement reprise côté PC.

## Pré-requis

Le sprint 2 doit être clos. Cela inclut le canal QR bidirectionnel fonctionnel, la cross-compile Windows validée, et le compte rendu écrit. La nouvelle spec QR version 2 doit également être adoptée et tracée dans le protocole.

Le code déjà livré au sprint 2 reste valide à l'exception de deux choses qui seront retirées ou neutralisées en début de sprint. D'abord, la table patient prévue dans le module stockage côté tablette n'est pas implémentée. Ensuite, le routage conditionnel actuel de l'écran d'accueil sur la tablette ("Nouveau patient" qui va vers `/jeu` si appairé, vers `/appairage` sinon) est repensé pour intégrer le scan du QR patient en début de séance.

## Tâches du sprint

La première tâche est l'adoption de la nouvelle spec QR version 2 dans le code. Cela couvre la mise à jour du package `internal/qr` côté PC et du module `lib/features/appairage/data.dart` côté tablette pour reconnaître le champ `version = 2` à la place de `version = 1`, et pour ajouter le nouveau type de message `creation_patient`. Le code des deux côtés rejette explicitement les messages version 1 avec le message d'erreur prévu.

La deuxième tâche est l'implémentation côté PC du module `internal/patients`. Cela couvre le schéma SQLite de la table patient (id, patient_id qui est l'UUID anonyme, nom, prenom, initiales, date_naissance, date_creation, notes), les opérations CRUD, et les tests unitaires. Le module utilise `modernc.org/sqlite` comme déjà acté à l'ADR-03.

La troisième tâche est l'implémentation côté PC de l'écran de création et sélection de patient dans la fenêtre Fyne. Cela couvre une liste des patients existants avec recherche par nom, un bouton "Nouveau patient" qui ouvre un formulaire de saisie, et un bouton "Démarrer une séance" sur chaque patient sélectionné qui appelle la nouvelle fonction de génération de QR patient.

La quatrième tâche est l'implémentation côté PC de la génération du QR `creation_patient` dans le module `internal/qr`. Cela couvre la construction de l'enveloppe avec le type `creation_patient` et la version 2, la signature avec `pc_priv`, l'encodage selon la chaîne JSON canonique + zlib + base64 + QR, et l'affichage dans une fenêtre Fyne secondaire.

La cinquième tâche est l'implémentation côté tablette de la réception du QR `creation_patient`. Cela couvre l'adaptation du décodeur d'enveloppe pour reconnaître ce nouveau type, la vérification de la signature avec `pc_pub` issue de la base d'appairage, l'extraction du `patient_id` et des `patient_initiales`, et l'affichage de l'écran de confirmation "Patient MD chargé. Prêt à jouer." avec un bouton pour démarrer le jeu.

La sixième tâche est l'adaptation de l'écran d'accueil côté tablette pour la nouvelle cinématique. Le bouton "Nouveau patient" ouvre maintenant directement le scanner caméra qui attend un QR `creation_patient`. Le routage conditionnel actuel basé uniquement sur la présence d'appairage est conservé pour l'appairage initial mais étendu pour gérer le cas "appairage présent mais pas de patient chargé".

La septième tâche est la constitution de la banque d'images Open Peeps pour le jeu des émotions. Cela couvre la sélection ou composition de visages pour chaque émotion (joie, tristesse, colère, peur, surprise, dégoût), avec un minimum de 8 variantes par émotion, format PNG 200×200 transparent, rangées dans `tablette_flutter/assets/visages/<emotion>/`. Cette tâche est faite tôt parce que c'est le risque principal du sprint.

La huitième tâche est l'implémentation de la logique métier du jeu des émotions, sans interface graphique. Cela couvre les types métier dans `lib/features/jeu_emotions/domain.dart`, la fonction de composition de planche pseudo-aléatoire, la fonction de calcul de score, et la fonction d'évaluation de fin de manche. Tests unitaires obligatoires.

La neuvième tâche est l'implémentation du moteur d'adaptation de difficulté dans `lib/features/jeu_emotions/adaptation.dart`. Cela couvre la décision de monter ou descendre de niveau selon les sessions précédentes, la règle d'hystérésis, et le mécanisme de forçage par le praticien depuis le QR `creation_patient` (qui pourra optionnellement transporter un niveau forcé dans une future version mineure du protocole, à débattre).

La dixième tâche est l'implémentation de l'interface graphique du jeu. Cela couvre l'écran de consigne et planche, le rendu des visages dans une grille pseudo-aléatoire, la gestion des taps avec retours visuels sonores et haptiques, l'écran de transition entre manches, et l'écran récapitulatif de fin de session.

La onzième tâche est l'intégration de l'export de session par QR vers le PC. Le payload `session` contient maintenant le `patient_id` reçu en début de séance, conformément à la spec QR version 2.

La douzième tâche est l'implémentation côté PC de la réception du QR `session`. Le PC vérifie la signature, extrait le `patient_id`, et insère les métriques dans une table `sessions` rattachée à la table `patients`. Pour cette première version, l'affichage des sessions reçues est minimal, juste un message de confirmation. Les écrans de fiche détaillée et graphique d'évolution sont au sprint 4.

La treizième tâche est le test manuel complet sur Lenovo Tab P12 plus PC Windows d'une session de bout en bout. Cette tâche valide le critère d'acceptation du sprint.

La quatorzième tâche est la rédaction du compte rendu de sprint dans `docs/comptes_rendus/sprint_03.md`.

## Critères d'acceptation

Le sprint est validé quand la démonstration suivante peut être faite. Le praticien lance le logiciel PC, crée un patient fictif avec ses nom prénom date de naissance, clique sur "Démarrer une séance", un QR s'affiche. Il prend la tablette, clique sur "Nouveau patient", scanne le QR du PC, la tablette confirme "Patient MD chargé". Le patient fictif joue une session complète au jeu des émotions avec les retours visuels corrects et les métriques bien stockées. La tablette génère un QR retour. Le praticien revient sur le PC, scanne le QR retour avec la webcam, le PC affiche "Session reçue pour le patient MD" et insère les données en base.

Tous les tests unitaires et de widget passent.

## Risques sur ce sprint

Le risque principal reste la constitution de la banque d'images Open Peeps. Si la bibliothèque ne permet pas de générer facilement des expressions distinctes pour les six émotions, il faudra adapter avec une banque complémentaire ou réduire le nombre d'émotions du jeu. La tâche 7 est positionnée tôt dans le sprint pour pouvoir replanifier si nécessaire.

Le second risque est la complexité de l'écran de gestion patients côté PC. Une UI Fyne avec liste, recherche, formulaire, et bouton d'action demande du soin pour rester ergonomique. Il faudra rester sobre et fonctionnel sans chercher à faire joli, le polish viendra au sprint 4.

Le troisième risque est le volume de travail du sprint qui est sensiblement plus important que les sprints précédents puisqu'il combine du travail côté PC et côté tablette. Une attention particulière sera portée à ne pas dériver sur des fonctionnalités non essentielles et à tenir le périmètre.
