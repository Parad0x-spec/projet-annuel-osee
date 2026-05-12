# Sprint 3 - Jeu des émotions

## Objectif

Implémenter le premier jeu cognitif complet sur la tablette : le jeu de reconnaissance d'émotions dans une planche dense, inspiré du format "Où est Charlie". À la fin du sprint, une session complète peut être jouée sur la Lenovo Tab P12 et exportée vers le logiciel PC par QR code.

La spécification fonctionnelle complète du jeu est dans `docs/specs/jeu_emotions.md`. Ce plan ne refait pas le détail de la spec, il enchaîne les tâches techniques nécessaires pour la livrer.

## Pré-requis

Le sprint 2 doit être clos, ce qui signifie que le canal QR bidirectionnel est fonctionnel, que la cross-compile Windows est validée, et que le compte rendu du sprint 2 est écrit. Sans ces fondations, le sprint 3 ne peut pas être démarré.

La banque d'images Open Peeps doit être constituée et présente dans le dépôt avant la première tâche d'implémentation du jeu. Cette constitution est une tâche préparatoire à part entière, c'est la tâche 1 du sprint.

## Tâches du sprint

La première tâche est la constitution de la banque d'images. Elle consiste à parcourir Open Peeps, sélectionner ou composer pour chaque émotion (joie, tristesse, colère, peur, surprise, dégoût) un ensemble de visages variés en termes de coiffures, traits, accessoires. Les images sont normalisées au format PNG avec fond transparent, taille 200×200 pixels, et rangées dans `tablette_flutter/assets/visages/<emotion>/` avec un nommage explicite. Un minimum de 8 visages par émotion est visé pour permettre une diversité raisonnable dans la composition des planches.

La deuxième tâche est l'implémentation du module de stockage côté tablette pour les patients et les sessions. Le schéma SQLite est étendu avec une table `patient` (id, initiales, identifiant_aleatoire, date_creation) et une table `session` (id, patient_id, date_debut, date_fin, niveau, score_global, payload_json) qui stocke le payload complet en JSON pour pouvoir le re-générer en cas de besoin. Les tests unitaires couvrent les opérations CRUD.

La troisième tâche est l'implémentation de la feature `profil_patient/`. Cela inclut l'écran de sélection ou création de patient, la logique de génération de l'identifiant aléatoire unique, et le couplage avec le stockage. Les tests de widget couvrent les deux cas (patient existant et nouveau patient).

La quatrième tâche est l'implémentation de la logique métier du jeu, sans interface graphique. Cela couvre les types métier dans `lib/features/jeu_emotions/domain.dart`, la fonction de composition de planche, la fonction de calcul de score, et la fonction d'évaluation de fin de manche. Les tests unitaires couvrent tous ces calculs avec table-driven tests pour balayer les niveaux et les cas limites.

La cinquième tâche est l'implémentation du moteur d'adaptation de difficulté dans `lib/features/jeu_emotions/adaptation.dart`. Cela couvre la décision de monter ou descendre de niveau selon les sessions précédentes, la règle d'hystérésis, et le mécanisme de forçage par le praticien. Tests unitaires obligatoires.

La sixième tâche est l'implémentation de l'interface graphique du jeu. Cela couvre l'écran de consigne et planche, le rendu des visages dans une grille pseudo-aléatoire, la gestion des taps avec retours visuels, sonores et haptiques, l'écran de transition entre manches, et l'écran récapitulatif de fin de session. Les tests de widget couvrent les interactions principales.

La septième tâche est l'intégration de l'export de session par QR vers le PC. Le payload session est construit selon la spec QR, signé avec la clé privée de la tablette, compressé et encodé selon la chaîne déjà utilisée pour l'appairage, et affiché dans un QR. Si le payload dépasse la capacité d'un QR, la mécanique de découpage en plusieurs QR successifs est activée (déjà spécifiée dans `docs/specs/protocole_qr.md`).

La huitième tâche est le test manuel complet sur Lenovo Tab P12 d'une session de bout en bout, du choix du patient à l'export du QR. Cette tâche n'est pas une tâche de code mais une tâche de validation indispensable. Les retours sur l'ergonomie, la fluidité, et l'expérience utilisateur sont consignés dans le compte rendu du sprint et alimentent les ajustements éventuels du sprint suivant.

La neuvième tâche est la rédaction du compte rendu de sprint dans `docs/comptes_rendus/sprint_03.md`.

## Critères d'acceptation

Le sprint est validé quand un patient fictif peut être créé sur la tablette par ses initiales, qu'une session complète de cinq manches peut être jouée sur le jeu des émotions avec les retours visuels et sonores corrects, que les métriques de session sont bien stockées en SQLite, que le QR de session peut être généré et qu'il contient un payload conforme à la spec QR signé correctement. Tous les tests unitaires et de widget passent.

La validation finale par le PC qui scannerait le QR de session n'est pas dans le périmètre du sprint 3, elle sera couverte par le sprint 4 quand le PC saura recevoir et stocker une vraie session.

## Risques sur ce sprint

Le risque principal est la production de la banque d'images. Si Open Peeps ne permet pas de générer facilement des expressions distinctes pour les six émotions, il faudra soit dessiner manuellement les visages manquants, soit chercher une banque complémentaire, soit réduire le nombre d'émotions du jeu. Cette tâche est donc faite en premier pour pouvoir replanifier si nécessaire.

Le second risque est la performance d'affichage de planches denses sur la Tab P12. Une vérification précoce avec une planche factice de 56 visages doit être faite dès la sixième tâche pour s'assurer que Flutter rend ça à 60 fps.

Le troisième risque est l'équilibrage du jeu, qui ne peut pas être validé sans tests sur de vrais patients. La huitième tâche couvre un premier test manuel par le porteur du projet, mais l'équilibrage réel ne sera affiné qu'après recette terrain au sprint 5.
