# Note de cadrage - Projet annuel

## Contexte général

Le projet consiste à concevoir un dispositif logiciel composé de deux éléments complémentaires destinés à des praticiens travaillant avec des patients atteints de TDAH ou de troubles du spectre autistique. Le premier élément est une application Android tournant sur tablette et présentée au patient pendant la séance. Le second élément est un logiciel de bureau utilisé par le praticien sur un PC Windows pour suivre l'évolution de chaque patient au fil des séances. Les deux éléments fonctionnent ensemble mais ne communiquent jamais par internet, l'échange de données se fait uniquement par scan de QR code sur le réseau local du cabinet.

L'application tablette propose des jeux d'entraînement cognitif. Pour la première itération un seul jeu est ciblé, la reconnaissance des émotions sur des visages, avec un retour visuel immédiat sous forme de point vert ou rouge selon la justesse de la réponse. Plusieurs niveaux de difficulté sont prévus.

Le logiciel praticien stocke les fiches patients de manière nominative, reçoit les données de séance depuis la tablette, et propose des graphiques d'évolution par patient.

## Parties prenantes

Le porteur du projet conçoit, développe et présente le projet en fin d'année universitaire. Le praticien est l'utilisateur final du logiciel PC et le destinataire des retours d'usage qui alimenteront les itérations. Le patient est l'utilisateur final de la tablette pendant la séance. Sur le plan légal le praticien est le responsable de traitement des données de santé puisque c'est lui qui exploite l'outil dans son cadre professionnel. Le porteur du projet fournit l'outil et garantit que celui-ci respecte les principes de minimisation et de sécurité des données.

## Périmètre de la première livraison

La cible visée pour la soutenance de fin juin comprend la création d'un profil patient sur tablette par saisie d'initiales et génération d'un identifiant aléatoire, le jeu de reconnaissance des émotions complet avec plusieurs niveaux de difficulté et feedback temps réel, l'enregistrement local sur tablette de toutes les métriques de séance comme le taux de réussite, le temps de réaction moyen, le nombre d'erreurs, les abandons et le niveau atteint, l'appairage initial entre tablette et PC par scan d'un QR code généré par le PC, l'export des données de séance depuis la tablette par génération d'un QR code scanné par la webcam du PC, le logiciel PC sous Windows avec création de fiches patients nominatives, réception des données depuis la tablette et affichage d'un graphique d'évolution par patient. L'interface est en français.

Tout ce qui sort de ce périmètre est placé en backlog post-soutenance. Cela inclut les jeux supplémentaires, le multi-praticien, la synchronisation entre plusieurs PC, l'export vers un dossier patient externe, et l'impression de bilans.

## Hypothèses

La tablette retenue est une Lenovo Tab P12 sous Android 13. Le PC praticien tourne sous Windows 10 ou 11. La tablette et le PC se trouvent sur le même réseau Wi-Fi local au cabinet, ce qui permet l'utilisation de la caméra de la tablette pour scanner un QR affiché à l'écran du PC, et inversement de la webcam du PC pour scanner un QR affiché sur la tablette. Aucune connexion internet n'est requise pour le fonctionnement du dispositif. Le développement se fait sur un poste sous Arch Linux, la cible Windows est gérée par compilation croisée Go.

## Contraintes

Le projet doit être prêt à être présenté en démonstration fin juin. Les données patients doivent être protégées en accord avec les principes du RGPD applicable aux données de santé même si le responsable de traitement est le praticien. La tablette ne doit jamais contenir de donnée nominative, seulement des initiales et un identifiant aléatoire. La réconciliation nom-identifiant n'existe que côté PC. Le projet est développé en cycle en V avec documentation continue à chaque sprint.

## Stack technique retenue

Le front mobile est développé en Flutter et déployé sur Android. Le logiciel PC ainsi que toute la logique métier transverse sont développés en Go. Le stockage local côté tablette utilise une base SQLite embarquée dans Flutter. Le stockage côté PC utilise également SQLite, suffisant pour un usage mono-praticien sans serveur. La génération et la lecture de QR code sont assurées par des bibliothèques Flutter côté tablette et Go côté PC. L'IDE utilisé est Goland pour le code Go et un éditeur compatible Flutter pour la partie mobile, l'assistance au développement passe par Claude Code en ligne de commande sur le poste Arch Linux.

## Risques principaux

Le risque le plus structurant est le délai. Sept à huit semaines pour livrer deux applications synchronisées et un jeu complet est tenable seulement si le périmètre est tenu fermement. Le second risque concerne la qualité du jeu de reconnaissance des émotions, qui nécessite des images de visages pour lesquelles il faut soit produire ou acquérir un jeu d'illustrations soit utiliser des banques d'images sous licence compatible. Le troisième risque concerne la fiabilité du transfert par QR code, en particulier la quantité de données transmissibles dans un seul QR ce qui peut nécessiter un découpage en plusieurs codes successifs ou un format compressé. Le quatrième risque concerne la conformité RGPD, qui sera traitée par documentation des choix de minimisation et par une note d'information à destination du praticien.

## Jalons macro

Le projet est découpé en sprints de deux semaines. Le sprint 1 couvre l'amorçage technique, la mise en place des dépôts, le squelette buildable des deux applications et la documentation initiale. Le sprint 2 couvre l'appairage par QR code et le canal de transfert de données. Le sprint 3 couvre le jeu de reconnaissance des émotions complet sur tablette avec stockage local des métriques. Le sprint 4 couvre le logiciel praticien avec fiches patients et graphiques d'évolution. La dernière phase couvre la recette terrain, les corrections et la préparation de la soutenance.

## Critère de réussite

Le projet est considéré comme réussi pour la soutenance si une démonstration de bout en bout peut être faite. Cela signifie qu'un patient fictif est créé sur la tablette par initiales et identifiant aléatoire, qu'il joue une session complète au jeu des émotions avec retour temps réel, que les données de session sont transférées vers le PC par QR code, et que le PC affiche la fiche du patient avec un graphique reflétant la session jouée. Tous les éléments doivent fonctionner sans accès internet et sans intervention manuelle hors des actions naturelles du patient et du praticien.
