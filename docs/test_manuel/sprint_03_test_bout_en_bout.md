# Test manuel de bout en bout - Sprint 3

Ce document sert de support pendant le test interactif de la tâche 13 du sprint 3. Il déroule pas à pas la boucle complète PC vers tablette vers PC, dans l'ordre, avec pour chaque étape l'action à réaliser, le résultat attendu, et une case à cocher. Il se remplit au fur et à mesure du test. Le bilan en fin de document est à compléter une fois la séquence terminée.

## Environnement matériel cible

Le test se fait sur le matériel de production, pas sur l'environnement de développement. Côté tablette, une Lenovo Tab P12 sous Android 13 avec l'APK debug installé. Côté praticien, un PC Windows physique exécutant le binaire `logiciel_pc.exe` compilé par cross-compile, avec une webcam externe branchée et orientée pour cadrer l'écran de la tablette. L'éclairage est celui d'un cabinet réel, c'est-à-dire ni studio ni pénombre, ce qui fait partie de ce qu'on veut éprouver puisque la lecture des QR par la webcam dépend des conditions lumineuses.

## Pré-requis avant de commencer

Avant de lancer la séquence, vérifier que les éléments suivants sont en place. La cross-compile Windows doit être récente, produite par `./scripts/build_pc_windows.sh` après le dernier commit de la tâche 12, et le binaire `logiciel_pc_go/build/logiciel_pc.exe` copié sur le PC Windows. L'APK debug doit être lui aussi récent, reconstruit par `flutter build apk --debug` après le dernier commit tablette. La tablette doit partir d'un état propre, donc désinstaller l'application existante puis réinstaller l'APK pour garantir une base SQLite tablette vierge sans appairage résiduel. Côté PC, le dossier de données du praticien doit être vide, ce qui signifie supprimer le dossier `%USERPROFILE%\.projet_annuel\` sur Windows, équivalent de `~/.projet_annuel/` sur le poste de développement, afin de démarrer sans patient, sans appairage et sans session.

Pour les vérifications en base SQLite décrites plus bas, prévoir un outil de lecture de la base sur le PC Windows, par exemple DB Browser for SQLite, ou l'exécutable `sqlite3.exe` en ligne de commande. La base à ouvrir est `%USERPROFILE%\.projet_annuel\patients.db`, fichier unique qui contient les trois tables `patients`, `appairage` et `sessions`.

Penser également à vérifier visuellement, après installation de l'APK, que les quatre planches sont bien embarquées et accessibles, ce qui se voit indirectement à l'écran de configuration de partie où les quatre boutons « Planche 1 » à « Planche 4 » doivent être présents et que le lancement de chacune affiche bien la planche correspondante. Une planche absente du bundle se manifesterait par une zone vide ou un message d'erreur dans l'écran de jeu.

Le bouton « Scanner QR tablette » de la fenêtre principale ouvre désormais une fenêtre de scan dédiée avec aperçu vidéo en direct de la webcam, et non plus une capture aveugle. Cette fenêtre se ferme automatiquement quand un QR est décodé, ou manuellement via le bouton « Annuler » ou la croix qui libèrent tous deux la caméra proprement.

## Séquence de test

### Étape 1 - Démarrage initial côté PC

Lancer `logiciel_pc.exe` sur le PC Windows à partir du dossier de données vide. La fenêtre Fyne intitulée « Suivi patients » doit s'ouvrir, avec le panneau de gestion des patients vide, un champ de recherche, et en bas la zone « Appairage du dispositif » présentant les boutons « Generer QR appairage » et « Scanner QR tablette ». Le fichier `%USERPROFILE%\.projet_annuel\patients.db` doit être créé sur le disque. Aucun appairage n'est chargé en mémoire à ce stade puisque la base est vide.

- [ ] OK    - [ ] KO    - [ ] Non testable

### Étape 2 - Démarrage initial côté tablette

Lancer l'application sur la Lenovo Tab P12. L'écran d'accueil intitulé « Atelier d'entraînement » doit s'afficher en orientation paysage, avec les boutons « Nouveau patient », « Patient existant » et « Paramètres ». La base SQLite de la tablette ne contient aucun appairage à ce stade.

- [ ] OK    - [ ] KO    - [ ] Non testable

### Étape 3 - Génération du QR d'appairage côté PC

Sur le PC, cliquer sur « Generer QR appairage ». Une nouvelle fenêtre intitulée « QR d'appairage PC » doit s'ouvrir, affichant un `pairing_id` sous forme d'UUID, le QR code, et la consigne « Scannez ce QR depuis la tablette ». Noter le `pairing_id` affiché pour le recouper plus tard avec la base.

- [ ] OK    - [ ] KO    - [ ] Non testable

### Étape 4 - Scan du QR d'appairage par la tablette

Sur la tablette, depuis l'écran d'accueil, appuyer sur « Nouveau patient », ce qui ouvre directement l'écran de scan caméra intitulé « Scan du QR ». Cadrer le QR d'appairage affiché sur le PC avec la caméra arrière de la tablette. La tablette doit détecter et décoder le QR, enregistrer la clé publique du PC et générer en réponse son propre QR de retour. L'écran doit basculer vers l'affichage du QR de retour avec la consigne de le faire scanner par le praticien.

- [ ] OK    - [ ] KO    - [ ] Non testable

### Étape 5 - Scan du QR de retour par le PC avec aperçu vidéo

Sur le PC, cliquer sur « Scanner QR tablette ». Une fenêtre dédiée intitulée « Scan du QR tablette » doit s'ouvrir et un aperçu vidéo en direct de la webcam doit apparaître au centre, après une latence de quelques secondes le temps que la caméra s'ouvre. Si l'aperçu reste gris alors que la webcam est branchée, ou si le message « Aucune caméra détectée. Vérifiez le branchement. » apparaît, vérifier que la webcam n'est pas utilisée par un autre logiciel puis fermer et réessayer.

Présenter la tablette affichant le QR de retour devant la webcam, en s'aidant de l'aperçu vidéo pour cadrer le QR au centre de l'image et ajuster la distance jusqu'à ce que le QR soit net et bien visible. Le décodage est automatique : dès que le QR est lisible, la fenêtre de scan se ferme et le statut de la fenêtre principale affiche « Appairage enregistre. ».

Tester aussi la sortie sans QR détecté : ouvrir la fenêtre de scan, présenter une image quelconque sans QR pendant quelques secondes, puis appuyer sur le bouton « Annuler ». La fenêtre doit se fermer immédiatement et la caméra doit être libérée, ce qui se vérifie en regardant la LED de la webcam si elle en a une, ou en réouvrant la fenêtre de scan tout de suite après pour confirmer qu'elle peut rouvrir la caméra sans erreur. Refaire le même test avec fermeture par la croix de la fenêtre au lieu du bouton « Annuler », le comportement doit être identique.

- [ ] OK    - [ ] KO    - [ ] Non testable

### Étape 6 - Vérification de la persistance de l'appairage en base

Ouvrir `%USERPROFILE%\.projet_annuel\patients.db` avec l'outil SQLite et exécuter `SELECT pairing_id, substr(tab_pub, 1, 16), date_appairage, date_dernier_usage FROM appairage;`. La requête doit retourner exactement une ligne, dont le `pairing_id` correspond à celui noté à l'étape 3, avec un `tab_pub` non vide et une `date_appairage` renseignée. La colonne `date_dernier_usage` peut être vide à ce stade puisqu'aucune session n'a encore été reçue.

- [ ] OK    - [ ] KO    - [ ] Non testable

### Étape 7 - Redémarrage du logiciel PC et persistance

C'est le point critique introduit par la tâche 12. Fermer entièrement `logiciel_pc.exe`, puis le relancer. Sans regénérer de QR d'appairage et sans rescanner la tablette, le logiciel doit recharger automatiquement l'appairage depuis la base SQLite, ce qui rend la `tab_pub` de la tablette de nouveau disponible en mémoire pour vérifier une future session. Ce comportement ne produit pas de message visible à l'écran, il sera confirmé indirectement à l'étape 12 par la réussite de la vérification de signature de la session après ce redémarrage.

- [ ] OK    - [ ] KO    - [ ] Non testable

### Étape 8 - Création d'un patient côté PC

Sur le PC, dans le panneau de gestion des patients, cliquer sur « Nouveau patient ». Renseigner le formulaire avec un patient fictif, par exemple nom « Dupont » et prénom « Marie », la date de naissance et les notes étant optionnelles, puis valider par « Creer ». Le patient doit apparaître dans la liste sous la forme « Dupont Marie (MD) », les initiales MD étant calculées automatiquement à partir du prénom et du nom.

- [ ] OK    - [ ] KO    - [ ] Non testable

### Étape 9 - Génération du QR creation_patient avec niveau 3

Dans la liste, sur la ligne du patient « Dupont Marie », cliquer sur « Demarrer une seance ». Une boîte de dialogue de choix du niveau s'ouvre, proposant cinq niveaux de difficulté. Laisser ou sélectionner « 3 - Moyen », puis valider. Une fenêtre intitulée « Seance pour MD - Niveau 3 » doit s'ouvrir, affichant le QR `creation_patient` signé et la consigne de le faire scanner par la tablette.

- [ ] OK    - [ ] KO    - [ ] Non testable

### Étape 10 - Scan du QR creation_patient et confirmation côté tablette

Sur la tablette, depuis l'écran d'accueil, appuyer de nouveau sur « Nouveau patient » pour ouvrir le scanner, puis cadrer le QR `creation_patient` affiché sur le PC. Après vérification de la signature avec la clé publique du PC issue de l'appairage, la tablette doit basculer vers l'écran de confirmation intitulé « Patient chargé », affichant le texte « Patient MD chargé. Prêt à jouer. » ainsi que les boutons « Commencer le jeu » et « Annuler ».

- [ ] OK    - [ ] KO    - [ ] Non testable

### Étape 11 - Accès à l'écran de configuration de partie

Sur la tablette, depuis l'écran de confirmation patient, appuyer sur « Commencer le jeu ». L'écran intitulé « Configuration de la partie » doit s'afficher, présentant la consigne « Choisissez la planche » suivie de quatre boutons « Planche 1 » à « Planche 4 », puis la consigne « Choisissez l'émotion à chercher » suivie de quatre boutons « Joie », « Colère », « Tristesse » et « Peur », et en bas un bouton « Lancer la partie » initialement désactivé (grisé).

- [ ] OK    - [ ] KO    - [ ] Non testable

### Étape 12 - Choix d'une planche et d'une émotion et lancement

Appuyer sur « Planche 1 », le bouton doit se colorer en bleu pour signaler la sélection. Appuyer sur « Joie », le bouton doit se colorer en orange. Le bouton « Lancer la partie » doit alors devenir actif. Appuyer dessus. La tablette doit charger la planche en mémoire et basculer vers l'écran intitulé « Partie en cours », avec en haut la consigne « Trouve tous les enfants joie » et en bas les boutons « Arrêter » et « J'ai fini ».

- [ ] OK    - [ ] KO    - [ ] Non testable

### Étape 13 - Vérification critique de la conversion des coordonnées de tap

C'est le point technique le plus sensible de l'implémentation. Sur la planche affichée, repérer visuellement un visage clairement joyeux (large sourire) parmi les enfants. Taper précisément sur ce visage. Le résultat attendu est qu'un cercle vert avec une coche apparaisse exactement centré sur le visage tapé, et reste affiché. Tester sur trois visages joyeux différents répartis dans la planche (un en haut, un au centre, un en bas) pour s'assurer que la précision est constante quel que soit l'endroit. Si le cercle vert apparaît décalé par rapport au visage, c'est le symptôme d'un bug de conversion de coordonnées à corriger. Tester également après avoir zoomé puis dézoomé et panné la planche dans l'InteractiveViewer, pour confirmer que la conversion reste correcte sous transformation.

- [ ] OK    - [ ] KO    - [ ] Non testable

### Étape 14 - Comportement des feedbacks vert, rouge et neutre

Taper sur un visage exprimant une autre émotion que joie (par exemple un visage en colère ou triste). Un cercle rouge avec une croix doit apparaître brièvement sur le visage tapé puis disparaître au bout d'environ une seconde. Taper ensuite dans une zone vide de la planche (un buisson, une zone de ciel, un coin sans personnage). Aucun feedback ne doit apparaître et rien ne doit changer dans les compteurs. Revérifier qu'un nouveau tap sur un visage joyeux affiche bien un cercle vert qui s'ajoute aux précédents sans les remplacer.

- [ ] OK    - [ ] KO    - [ ] Non testable

### Étape 15 - Fin automatique de la partie

Poursuivre les taps jusqu'à avoir trouvé tous les visages joyeux de la planche. Au moment où le dernier visage joyeux est tapé, la tablette doit basculer automatiquement vers l'écran de transition sans qu'il soit nécessaire d'appuyer sur « J'ai fini ». Le score doit refléter le ratio cibles trouvées sur cibles totales avec déduction des éventuels faux positifs accumulés.

- [ ] OK    - [ ] KO    - [ ] Non testable

### Étape 16 - Écran de transition et étoiles

L'écran intitulé « Résultat de la partie » doit afficher en haut une rangée de trois étoiles dont une à trois sont remplies en jaune selon le score (les autres en contour), suivie d'un message d'encouragement neutre. Deux boutons en bas proposent « Terminer la séance » et « Nouvelle partie ». Si la partie a été terminée sans faute ni cible ratée, trois étoiles pleines doivent être affichées.

- [ ] OK    - [ ] KO    - [ ] Non testable

### Étape 17 - Enchaînement d'une seconde partie avec autre planche et émotion

Appuyer sur « Nouvelle partie » pour revenir à l'écran de configuration. Choisir cette fois « Planche 2 » et « Colère », puis lancer. Jouer la partie en mode plus rapide, par exemple en tapant seulement deux ou trois visages en colère puis en appuyant sur « J'ai fini ». L'écran de transition doit s'afficher avec un score correspondant à un nombre partiel de cibles trouvées, et donc probablement une ou deux étoiles. Cela valide que deux parties peuvent s'enchaîner dans la même séance.

- [ ] OK    - [ ] KO    - [ ] Non testable

### Étape 18 - Terminer la séance et récapitulatif

Sur l'écran de transition de la seconde partie, appuyer sur « Terminer la séance ». L'écran intitulé « Récapitulatif de la séance » doit s'afficher, listant les deux parties jouées dans leur ordre, par exemple « Partie 1 — Planche 1, joie — score 100 / 100 » et « Partie 2 — Planche 2, colère — score 50 / 100 ». En bas, un bouton « Quitter sans transférer » et un bouton « Générer le QR de séance ».

- [ ] OK    - [ ] KO    - [ ] Non testable

### Étape 19 - Génération et affichage du QR de séance

Appuyer sur « Générer le QR de séance ». L'écran « Export de la séance » doit s'afficher avec le QR encodant le payload signé. Le payload contient maintenant la liste agrégée des deux parties jouées (et non plus une liste vide comme à la tâche 11), donc le QR est sensiblement plus dense qu'avant. Vérifier que le QR reste bien lisible visuellement et que la consigne « Faites scanner ce QR au praticien. » apparaît correctement avec le sous-texte « Session pour MD ».

- [ ] OK    - [ ] KO    - [ ] Non testable

### Étape 20 - Scan du QR de séance par le PC avec aperçu vidéo

Sur le PC, cliquer sur « Scanner QR tablette ». La fenêtre dédiée « Scan du QR tablette » doit s'ouvrir avec l'aperçu vidéo en direct, comme à l'étape 5. Présenter l'écran d'export de la tablette devant la webcam en s'aidant de l'aperçu pour cadrer correctement. Comme le QR de session est plus dense que celui d'appairage parce qu'il porte la liste agrégée des parties jouées, ajuster la distance et la mise au point en privilégiant un cadrage plus large où l'intégralité du QR est visible avec une bonne netteté. La présence de l'aperçu vidéo facilite ce cadrage, qui aurait été impossible à régler à l'aveugle dans la version précédente.

Dès que le QR est décodé avec succès, la fenêtre de scan se ferme automatiquement et le statut de la fenêtre principale affiche, après vérification de la signature avec la `tab_pub` rechargée à l'étape 7 et insertion en base, le message « Session recue pour patient MD - niveau 3 ». La réussite de cette vérification de signature après le redémarrage de l'étape 7 valide le rechargement de l'appairage depuis SQLite, comme à la version précédente du test.

- [ ] OK    - [ ] KO    - [ ] Non testable

### Étape 21 - Vérification finale de la séance et des parties en base

Ouvrir de nouveau `patients.db` avec l'outil SQLite et exécuter `SELECT s.id, p.initiales, s.jeu_type, s.niveau, s.session_date, s.date_reception FROM sessions s JOIN patients p ON p.patient_id = s.patient_id;`. La requête doit retourner une ligne dont les initiales sont MD, le `jeu_type` est `emotions` et le `niveau` est 3, ce qui confirme que la session reçue est bien rattachée au bon patient. Vérifier ensuite que la colonne `payload_complet` de la table `sessions` contient le JSON brut du payload, et que ce JSON inclut une clé `parties` qui est une liste de deux objets correspondant aux deux parties jouées, chacun avec son `emotion_cible`, son `numero_planche`, son `score`, son `mode_fin` et les compteurs `nb_cibles_total`, `nb_cibles_trouvees`, `nb_faux_positifs`, `nb_cibles_ratees`. Les valeurs doivent correspondre à ce qui a été observé pendant les parties (planche 1 joie score élevé, planche 2 colère score partiel).

- [ ] OK    - [ ] KO    - [ ] Non testable

## Tests de cas d'erreur

### Cas A - Scan d'un QR session sans appairage préalable

Ce cas vérifie le garde-fou côté PC lorsqu'aucun appairage n'a été établi. Repartir d'un dossier `%USERPROFILE%\.projet_annuel\` vide, ou d'une base dont la table `appairage` est vide, relancer le logiciel PC, puis tenter de scanner directement un QR de session sans avoir fait l'appairage. Le logiciel ne doit pas insérer de session et doit afficher dans le statut le message « Aucun appairage enregistre. Appairez d'abord la tablette. ». Comme ce cas exige par ailleurs un QR de session valide, il peut être réalisé en réutilisant la tablette d'un test précédent, ou marqué Non testable si aucun QR de session n'est disponible dans cet état.

- [ ] OK    - [ ] KO    - [ ] Non testable

### Cas B - Accès aux écrans du jeu sans patient chargé côté tablette

Ce cas vérifie le garde-fou côté tablette. Dans la cinématique normale, les écrans de configuration de partie, de jeu, de transition, de récapitulatif et d'export ne sont atteignables qu'après le chargement d'un patient via un QR `creation_patient`, puisque le bouton « Commencer le jeu » de l'écran de confirmation patient est la seule porte d'entrée. Atteindre l'un de ces écrans sans patient chargé n'est donc pas censé être possible par les chemins de navigation prévus. Si une manipulation permet malgré tout d'y parvenir, les écrans concernés doivent afficher le message « Aucun patient chargé. » plutôt que de tenter de charger une planche ou de générer un QR. Ce garde-fou est par ailleurs couvert par les tests automatisés de la partie B, donc ce cas peut être marqué Non testable s'il n'existe aucun chemin manuel pour l'atteindre.

- [ ] OK    - [ ] KO    - [ ] Non testable

## Bilan

À compléter après le test.

| Rubrique | À remplir |
| --- | --- |
| Date du test | |
| Testeur | |
| Résultat global (succès complet / partiel / échec) | |
| Étapes en échec (numéros) | |
| Lecture des QR par la webcam (fiabilité observée) | |
| Anomalies remontées | |
| Décisions ou corrections à reporter | |
| Tâches de suivi créées | |

En complément du tableau, rédiger en prose un court paragraphe de synthèse décrivant le déroulé réel du test, les écarts éventuels par rapport au comportement attendu, et l'appréciation globale de la maturité de la boucle de communication à ce stade du sprint.
