# ADR-07 - Identification patient confiée exclusivement au PC

## Contexte

Le projet a démarré avec une cinématique où la tablette était responsable de la création d'un profil patient par saisie d'initiales et génération d'un identifiant aléatoire local. Cette décision avait été prise très tôt dans le projet, avant que le rôle réel des deux applications soit pleinement compris.

À l'usage et après réflexion sur le scénario d'utilisation réel en cabinet, plusieurs faiblesses sont apparues. La saisie des initiales sur la tablette par le praticien introduisait un risque d'erreur de frappe au moment où le patient est devant lui, sous pression de séance. La génération d'un identifiant aléatoire côté tablette obligeait ensuite à un travail de réconciliation côté PC quand les données de session étaient reçues, avec un risque non négligeable de créer des doublons si le praticien saisissait à nouveau les mêmes initiales pour un patient déjà enregistré. La possibilité que deux patients aient les mêmes initiales rendait cette réconciliation manuelle inévitable.

Plus fondamentalement, cette répartition mélangeait deux niveaux de responsabilité. La tablette est utilisée pendant la séance par un enfant ou adolescent, elle doit rester un outil de jeu simple et focalisé. Le PC du praticien est le lieu naturel de la gestion administrative et nominative des patients. Confier à la tablette la création de profils, même anonymes, c'était introduire de la complexité administrative dans un outil qui doit être ludique.

## Options envisagées

La première option était de conserver la cinématique initiale en améliorant ses faiblesses. On aurait pu ajouter des écrans de confirmation, de modification après création, de vérification de doublons par recherche dans la base tablette. Cette option a été écartée parce qu'elle accumulait des correctifs sur une architecture mal calibrée plutôt que de revoir le partage des responsabilités.

La seconde option, retenue, est de déplacer entièrement la responsabilité de l'identification patient vers le PC. Le praticien crée et gère ses patients dans le logiciel PC qui dispose d'un environnement administratif adapté. Pour démarrer une séance avec un patient, le praticien sélectionne ce patient dans le logiciel PC, génère un QR code spécifique à ce patient, et le scanne avec la tablette. La tablette ne crée jamais de patient elle-même, elle reçoit un contexte de session par QR et l'utilise pour la durée de la session.

La troisième option envisagée était une approche hybride avec création possible des deux côtés et synchronisation. Elle a été écartée parce qu'elle réintroduirait la même complexité de réconciliation qu'on cherche à éliminer.

## Option retenue

La responsabilité de l'identification patient est confiée exclusivement au PC. Le logiciel PC dispose de la base patients nominative complète, génère les identifiants anonymes, et produit pour chaque séance un QR code patient qui contient le strict nécessaire pour que la tablette puisse mener la séance et étiqueter ses données de retour.

Le QR patient contient deux champs. Premier champ, le `patient_id` qui est l'identifiant anonyme unique généré par le PC à la création du patient, qui sert de clé de jointure entre les données de la tablette et la fiche nominative côté PC. Second champ, les `patient_initiales` qui sont les initiales du patient, présentes uniquement pour permettre au praticien de confirmer visuellement sur la tablette qu'il a chargé le bon patient avant de démarrer la séance. La tablette affiche par exemple "Patient MD chargé, prêt à jouer".

La tablette ne stocke aucune information nominative ni quasi-nominative. Le `patient_id` est un identifiant opaque sans signification, et les initiales sont uniquement transitoires pour la durée de la session courante. Quand une nouvelle session démarre par scan d'un autre QR patient, le contexte précédent est remplacé.

La cinématique de correction d'erreur est simple. Si le praticien s'est trompé de patient avant que la session ne commence vraiment, il scanne simplement un autre QR patient et le nouveau patient remplace l'ancien. Aucun écran de modification, aucune saisie manuelle, aucun risque de fausse manipulation.

## Conséquences

Cette décision a plusieurs implications structurantes sur le projet.

Côté tablette, la feature `profil_patient` qui était planifiée n'existera jamais. La fonctionnalité de création et de sélection de patient est entièrement supprimée du périmètre tablette. Le module `stockage` côté tablette n'a plus de table patient, il stocke uniquement la session en cours liée au `patient_id` reçu par QR. Cette simplification réduit le périmètre fonctionnel de la tablette d'environ vingt à trente pour cent.

Côté PC, le périmètre s'enrichit. Le logiciel PC doit maintenant gérer une vraie base patients nominative et exposer la création de patients et la génération du QR patient. Ces fonctionnalités, qui étaient prévues pour le sprint 4, deviennent partiellement nécessaires dès le sprint 3 puisque sans elles la tablette ne peut pas être testée.

Le protocole QR évolue vers une version 2 qui introduit un nouveau type de message `creation_patient` allant du PC vers la tablette. Le type `session` est conservé mais adapté pour utiliser le `patient_id` reçu plutôt qu'un identifiant généré par la tablette. La spec QR sera mise à jour en conséquence.

La répartition des sprints est ajustée. Le sprint 3 fait maintenant le jeu complet sur la tablette plus le minimum côté PC pour créer un patient et générer son QR. Le sprint 4 enrichit le côté PC avec les fiches patients détaillées, le graphique d'évolution, et l'export Excel mère qui agrège toutes les sessions.

Cette décision est cohérente avec les ADR précédents. Elle renforce l'ADR-06 sur la souveraineté des données en réduisant la quantité d'informations stockées côté tablette. Elle est conforme à la politique de minimisation RGPD : la tablette ne manipule plus que des identifiants opaques et des initiales transitoires, jamais de données nominatives. Elle ne contredit aucun autre ADR existant.

Le code déjà livré n'est pas perdu. Le module crypto, le module qr, l'appairage bidirectionnel, et le module stockage côté tablette restent valides. Seule la table patient prévue dans le stockage tablette ne sera pas implémentée, et l'écran de profil patient sur tablette ne sera pas développé.
