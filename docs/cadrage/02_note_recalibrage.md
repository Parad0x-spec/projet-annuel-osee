# Note de cadrage mise à jour - Recalibrage post sprint 2

## Objet de cette mise à jour

La note de cadrage initiale a été rédigée au démarrage du projet. Après l'expérience des sprints 1 et 2, plusieurs choix architecturaux ont été révisés. Cette mise à jour ne remplace pas la note initiale, elle la complète pour acter les décisions de recalibrage et les éclairer pour les sprints à venir.

Les changements structurants sont consignés dans l'ADR-07 sur l'identification patient confiée exclusivement au PC. Cette mise à jour de la note de cadrage en tire les conséquences sur la vision d'ensemble du projet.

## Vision révisée du dispositif

Le dispositif est composé de deux applications jumelles qui ont maintenant des rôles clairement distincts.

Le logiciel PC du praticien est le **centre administratif** du dispositif. Il porte toute la gestion nominative des patients, la création des dossiers, la génération des contextes de séance, la réception et le stockage des données de jeu, et la production du fichier Excel mère qui agrège toutes les sessions. Le PC est utilisé par le praticien en dehors de la séance pour préparer et exploiter, et brièvement pendant la séance pour générer le QR patient et recevoir le QR de session.

La tablette est un **outil de jeu focalisé**. Elle ne stocke aucune information nominative ni administrative. Elle reçoit un contexte de séance par scan de QR, fait jouer le patient, et restitue les métriques par QR retour. Elle est utilisée par le patient sous supervision du praticien pendant la séance, et n'a pas vocation à être consultée en dehors.

Cette répartition est plus claire et plus défendable que la version initiale. Elle simplifie le code des deux côtés, elle réduit la surface d'attaque sur la tablette, et elle est cohérente avec la posture de souveraineté des données posée par l'ADR-06.

## Cinématique d'usage type

Le scénario nominal d'une séance complète se déroule en cinq temps.

D'abord la préparation, hors séance. Le praticien dans son logiciel PC crée le patient s'il n'existe pas encore, en remplissant son nom prénom date de naissance et notes éventuelles. Le PC génère et stocke un identifiant anonyme unique pour ce patient, le `patient_id` au format UUID. Cet identifiant ne change jamais et sert de clé de liaison entre la base nominative PC et toutes les données qui transiteront par la tablette.

Ensuite le démarrage de séance. Le praticien sélectionne le patient dans le logiciel PC et clique sur "Démarrer une séance". Le PC affiche un QR code qui contient le `patient_id` et les initiales du patient. Sur la tablette, le praticien clique "Nouveau patient" et scanne ce QR. La tablette affiche "Patient MD chargé, prêt à jouer" et propose de lancer le jeu.

Puis le jeu lui-même. Le patient joue une session du jeu des émotions ou de tout autre jeu futur. La tablette enregistre toutes les métriques en local, rattachées au `patient_id` courant.

Ensuite la fin de séance. La tablette construit un QR de session signé qui contient les métriques et le `patient_id`. Le praticien revient au PC, clique "Recevoir une session", et la webcam scanne le QR de la tablette. Le PC vérifie la signature, extrait les données, et les insère dans sa base en les rattachant à la fiche patient correspondante par le `patient_id`.

Enfin l'exploitation. Le PC met automatiquement à jour le fichier Excel mère qui contient toutes les sessions de tous les patients du praticien. Le praticien peut consulter dans son logiciel PC les fiches patients avec leur graphique d'évolution, ou exploiter le fichier Excel pour ses propres analyses, partages, ou archivages.

## Cas de correction d'erreur

Si le praticien se trompe de patient au moment du scan, la situation est gérée naturellement. Avant que le jeu commence, il suffit de rescanner un autre QR depuis le PC, le nouveau patient remplace l'ancien dans le contexte tablette. Si le jeu a déjà commencé pour un mauvais patient, la session en cours est abandonnée (la tablette propose un bouton "Annuler la session") et un nouveau scan démarre une nouvelle session avec le bon patient.

Cette robustesse à l'erreur humaine est un point fort du dispositif. Elle a été obtenue par simplification architecturale et non par accumulation de garde-fous.

## Sur la responsabilité des données

La répartition entre le PC et la tablette correspond au cloisonnement RGPD que nous voulions. Les données nominatives, qui sont la matière sensible, ne quittent jamais le PC du praticien qui en est le responsable de traitement. La tablette ne manipule que des identifiants opaques et des initiales transitoires, donc des pseudonymes au sens du RGPD article 4 paragraphe 5.

Cette répartition est plus stricte que la version initiale du projet et elle renforce l'ADR-06 sur la souveraineté des données. Elle pourra être présentée en soutenance comme un point fort du dispositif.

## Sur le périmètre soutenance

Le périmètre cible pour la soutenance de fin juin reste centré sur le jeu des émotions. Avec cette nouvelle répartition, le périmètre s'enrichit légèrement côté PC puisqu'il faut une gestion patients fonctionnelle dès le sprint 3 alors qu'on l'avait initialement repoussée au sprint 4. En contrepartie, le périmètre tablette se simplifie puisque la gestion patients y est entièrement supprimée. Le solde global est tenable dans le calendrier.

Le sprint 3 couvre maintenant le jeu complet sur tablette plus la gestion patients minimale sur PC. Le sprint 4 enrichit le PC avec les fiches patients détaillées, le graphique d'évolution, et le fichier Excel mère. Le sprint 5 reste consacré à la recette terrain et la préparation de la soutenance.

## Sur le travail déjà livré

Le travail des sprints 1 et 2 reste valide à plus de 90%. Les ADR, le canal QR, le module crypto, l'appairage bidirectionnel, le module stockage côté tablette, et l'interface Fyne de base sont tous réutilisés tels quels. Les seules portions à retirer ou neutraliser sont la table patient prévue dans le stockage tablette (jamais implémentée donc rien à retirer) et l'écran de profil patient prévu sur la tablette (jamais implémenté donc rien à retirer).

Le recalibrage tombe donc à un moment idéal : avant que du code dédié à l'ancienne vision ait été écrit. Le coût du changement de cap est essentiellement documentaire (mise à jour des spec et plans) plus l'ajout d'un quatrième type de message dans le protocole QR.
