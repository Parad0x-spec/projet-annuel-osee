# Test manuel de bout en bout - Sprint 3

Ce document sert de support pendant le test interactif de la tâche 13 du sprint 3. Il déroule pas à pas la boucle complète PC vers tablette vers PC, dans l'ordre, avec pour chaque étape l'action à réaliser, le résultat attendu, et une case à cocher. Il se remplit au fur et à mesure du test. Le bilan en fin de document est à compléter une fois la séquence terminée.

## Environnement matériel cible

Le test se fait sur le matériel de production, pas sur l'environnement de développement. Côté tablette, une Lenovo Tab P12 sous Android 13 avec l'APK debug installé. Côté praticien, un PC Windows physique exécutant le binaire `logiciel_pc.exe` compilé par cross-compile, avec une webcam externe branchée et orientée pour cadrer l'écran de la tablette. L'éclairage est celui d'un cabinet réel, c'est-à-dire ni studio ni pénombre, ce qui fait partie de ce qu'on veut éprouver puisque la lecture des QR par la webcam dépend des conditions lumineuses.

## Pré-requis avant de commencer

Avant de lancer la séquence, vérifier que les éléments suivants sont en place. La cross-compile Windows doit être récente, produite par `./scripts/build_pc_windows.sh` après le dernier commit de la tâche 12, et le binaire `logiciel_pc_go/build/logiciel_pc.exe` copié sur le PC Windows. L'APK debug doit être lui aussi récent, reconstruit par `flutter build apk --debug` après le dernier commit tablette. La tablette doit partir d'un état propre, donc désinstaller l'application existante puis réinstaller l'APK pour garantir une base SQLite tablette vierge sans appairage résiduel. Côté PC, le dossier de données du praticien doit être vide, ce qui signifie supprimer le dossier `%USERPROFILE%\.projet_annuel\` sur Windows, équivalent de `~/.projet_annuel/` sur le poste de développement, afin de démarrer sans patient, sans appairage et sans session.

Pour les vérifications en base SQLite décrites plus bas, prévoir un outil de lecture de la base sur le PC Windows, par exemple DB Browser for SQLite, ou l'exécutable `sqlite3.exe` en ligne de commande. La base à ouvrir est `%USERPROFILE%\.projet_annuel\patients.db`, fichier unique qui contient les trois tables `patients`, `appairage` et `sessions`.

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

### Étape 5 - Scan du QR de retour par le PC

Sur le PC, cliquer sur « Scanner QR tablette ». La zone de statut doit afficher « Capture en cours... » pendant que la webcam capture l'écran de la tablette présentant le QR de retour. Présenter la tablette devant la webcam. Après lecture et vérification de la signature, le statut doit afficher « Appairage enregistre. ». Si la lecture échoue, ajuster la distance, l'angle et l'éclairage, puis relancer le scan.

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

### Étape 11 - Passage au placeholder de jeu et déclenchement de l'export

Sur la tablette, appuyer sur « Commencer le jeu ». L'écran placeholder intitulé « Jeu » doit s'afficher avec le texte « Mode test infrastructure : permet de valider la boucle PC ↔ tablette avant l'implémentation du jeu. » et un bouton « Exporter session de test ». Appuyer sur ce bouton.

- [ ] OK    - [ ] KO    - [ ] Non testable

### Étape 12 - Génération et affichage du QR session côté tablette

L'écran « Export de la séance » doit s'afficher, présentant le QR de session, la consigne « Faites scanner ce QR au praticien. », le sous-texte « Session pour MD » pour confirmation visuelle, et un bouton « Terminé, retourner à l'accueil ». Le QR de session encode le payload minimaliste de la tâche 11, avec le `patient_id` reçu, le niveau 3, le type de jeu `emotions` et un tableau de manches vide, signé par la tablette.

- [ ] OK    - [ ] KO    - [ ] Non testable

### Étape 13 - Scan du QR session par le PC et insertion en base

Sur le PC, cliquer sur « Scanner QR tablette » et présenter l'écran d'export de la tablette devant la webcam. Le statut doit afficher « Capture en cours... » puis, après lecture, vérification de la signature avec la `tab_pub` rechargée à l'étape 7 et insertion en base, le message « Session recue pour patient MD - niveau 3 ». La réussite de cette vérification de signature après le redémarrage de l'étape 7 valide le rechargement de l'appairage depuis SQLite.

- [ ] OK    - [ ] KO    - [ ] Non testable

### Étape 14 - Vérification finale de la session en base

Ouvrir de nouveau `patients.db` avec l'outil SQLite et exécuter `SELECT s.id, p.initiales, s.jeu_type, s.niveau, s.session_date, s.date_reception FROM sessions s JOIN patients p ON p.patient_id = s.patient_id;`. La requête doit retourner une ligne dont les initiales sont MD, le `jeu_type` est `emotions` et le `niveau` est 3, ce qui confirme que la session reçue est bien rattachée au bon patient par le `patient_id`. Vérifier accessoirement que la colonne `payload_complet` de la table `sessions` contient le JSON brut du payload.

- [ ] OK    - [ ] KO    - [ ] Non testable

## Tests de cas d'erreur

### Cas A - Scan d'un QR session sans appairage préalable

Ce cas vérifie le garde-fou côté PC lorsqu'aucun appairage n'a été établi. Repartir d'un dossier `%USERPROFILE%\.projet_annuel\` vide, ou d'une base dont la table `appairage` est vide, relancer le logiciel PC, puis tenter de scanner directement un QR de session sans avoir fait l'appairage. Le logiciel ne doit pas insérer de session et doit afficher dans le statut le message « Aucun appairage enregistre. Appairez d'abord la tablette. ». Comme ce cas exige par ailleurs un QR de session valide, il peut être réalisé en réutilisant la tablette d'un test précédent, ou marqué Non testable si aucun QR de session n'est disponible dans cet état.

- [ ] OK    - [ ] KO    - [ ] Non testable

### Cas B - Export d'une session sans patient chargé côté tablette

Ce cas vérifie le garde-fou côté tablette. Dans la cinématique normale, l'écran d'export n'est atteignable qu'après le chargement d'un patient via un QR `creation_patient`, puisque l'accès au placeholder de jeu passe par l'écran de confirmation patient. Atteindre l'écran d'export sans patient chargé n'est donc pas censé être possible par les chemins de navigation prévus. Si une manipulation permet malgré tout d'y parvenir, l'écran d'export doit afficher le message « Aucun patient chargé. » plutôt que de générer un QR. Ce garde-fou est par ailleurs couvert par les tests automatisés de la tâche 11, donc ce cas peut être marqué Non testable s'il n'existe aucun chemin manuel pour l'atteindre.

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
