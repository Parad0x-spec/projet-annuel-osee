# ADR-11 - Protocole de session version 3 et stockage PC structure par planche et par emotion

## Statut

Accepte. Supersede le format du message `session` defini par l'ADR-07 et la
specification protocole_qr.md version 2. Corrige l'affirmation de l'ADR-10
selon laquelle l'evolution du jeu ne modifiait pas le canal de communication QR.
Complete l'ADR-03 qui actait SQLite sans figer le schema des sessions cote PC.

## Contexte

L'ADR-10 a refondu le jeu en navigation libre entre emotions. Une seance porte
desormais plusieurs planches, et chaque planche porte un resultat pour chacune
des quatre emotions. L'ADR-10 a explicitement prevu que les donnees transmises
au PC soient structurees par seance, par planche et par emotion.

La tablette a ete implementee conformement a cette decision : elle emet un
payload de session dont la cle `planches` contient, pour chaque planche, son
numero, son score global et le detail par emotion. Mais le logiciel PC decode
encore l'ancien format version 2, qui attendait un tableau `manches` mono-emotion
issu de l'ADR-07.

Le decalage n'a pas produit d'erreur visible : la deserialisation JSON cote PC
ignore les cles inconnues, la signature reste valide, et le PC stocke le payload
brut sans le parser. Le PC acceptait donc les sessions tout en jetant
silencieusement le detail par emotion. Un echec silencieux de ce type est plus
dangereux qu'un rejet franc, car il donne l'illusion d'une boucle fonctionnelle
alors que la donnee clinique centrale est perdue.

Par ailleurs, ce changement de schema a eu lieu sans incrementer le champ
`version` de l'enveloppe, reste a 2 des deux cotes. Le garde-fou de version,
concu precisement pour rejeter les messages incompatibles, etait donc aveugle a
cette incompatibilite.

L'ADR-10 affirmait que l'evolution du jeu ne modifiait pas le canal QR. Cela
s'est revele inexact des lors que la structure du payload `session` a change.

## Options envisagees

Sur le transport, une premiere option etait de conserver la version 2 et de
reecrire simplement le decodeur PC, au motif que la version 2 n'a jamais ete
deployee en production. Elle a ete ecartee : laisser deux schemas distincts sous
un meme numero de version prive le protocole de son seul mecanisme de detection
d'incompatibilite et reproduirait a l'avenir le meme echec silencieux.

Sur le stockage PC, une premiere option etait de continuer a ne stocker que le
payload JSON brut et de le re-parser au moment de produire l'export Excel du
sprint 4. Elle a ete ecartee car elle reporte toute la complexite de requetage
sur le sprint 4, interdit l'agregation en SQL et fragilise le suivi des qu'on
veut filtrer ou moyenner par emotion. Une deuxieme option etait une table unique
a plat dupliquant le contexte de planche sur chaque ligne d'emotion ; ecartee
pour denormalisation. L'option retenue est un schema relationnel normalise.

## Decision sur le protocole

Le protocole QR passe en version 3. La tablette emet `version` valant 3 et le PC
n'accepte que `version` valant 3. Tout message recu avec une version differente
est rejete avec un message clair d'incompatibilite, des deux cotes.

Le message `session` version 3 remplace le tableau `manches` par un tableau
`planches`. Chaque planche contient `numero_planche`, `score_global`, et
`resultats_par_emotion`, ce dernier etant la liste des resultats des quatre
emotions. Chaque resultat d'emotion contient `emotion`, `nb_cibles_total`,
`nb_cibles_trouvees`, `nb_faux_positifs`, `score` borne entre zero et cent, et un
booleen `evaluee` indiquant si l'emotion a ete retenue pour l'evaluation sur
cette planche. Le detail tap par tap n'est pas transmis, conformement a l'ADR-10.
Les champs d'entete `patient_id`, `patient_initiales`, `session_date`, `jeu_type`
et `niveau` sont inchanges.

Le PC valide reellement le payload recu : presence d'au moins une planche, valeur
d'emotion appartenant a l'ensemble connu, et scores dans les bornes attendues.
Un payload malforme est rejete franchement plutot qu'enregistre partiellement.

## Decision sur le stockage PC

Le PC stocke les sessions selon un schema relationnel normalise. La table
`sessions` existante est conservee et continue de porter les champs d'entete
ainsi que `payload_complet`, le JSON brut signe, garde a des fins d'audit et de
verification a posteriori de la signature. Deux tables filles sont ajoutees.
La table `planches_jouees` reference une session et porte `numero_planche` et
`score_global`. La table `resultats_emotion` reference une planche jouee et porte
le detail d'une emotion. L'insertion d'une session recue est transactionnelle :
la session, ses planches et leurs resultats sont ecrits en tout ou rien.

Ce schema permet au sprint 4 de produire la progression par emotion d'un patient
par une simple requete SQL agregee, une ligne par seance et par emotion, en
filtrant sur les emotions reellement evaluees, sans re-parser de JSON.

## Consequences

La specification protocole_qr.md est mise a jour pour decrire le format version 3
et marquer le format `manches` version 2 comme obsolete. Le detail des nouvelles
tables est consigne dans docs/specs/schemas_donnees.md.

Cote tablette, seule la constante de version du protocole passe de 2 a 3 ; la
serialisation du payload est deja conforme. Cote PC, le decodeur, la validation,
le schema SQLite et la fonction d'enregistrement sont adaptes, avec leurs tests
unitaires et d'integration du canal QR.

Aucune nouvelle bibliotheque n'est introduite. La souverainete des donnees de
l'ADR-06 est preservee : tout reste local, le detail par emotion ne contient
aucune donnee nominative. Aucune migration de donnees existantes n'est requise,
aucune session n'ayant ete recue en production sous l'ancien format.

## Mise a jour de l'ADR-10

L'ADR-10 doit recevoir en tete une mention indiquant que sa phrase affirmant que
l'evolution du jeu ne modifie pas le canal de communication QR est corrigee par
le present ADR-11, le reste de l'ADR-10 demeurant valide.
