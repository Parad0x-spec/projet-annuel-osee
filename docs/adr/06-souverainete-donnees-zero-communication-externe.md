# ADR-06 - Souveraineté des données et politique zéro communication externe

## Contexte

Le projet manipule des données rattachées à des patients suivis pour des troubles du déficit de l'attention avec ou sans hyperactivité, et pour des troubles du spectre autistique. Même après la pseudonymisation appliquée par construction (initiales et identifiant aléatoire côté tablette, table de réconciliation cantonnée au PC du praticien), ces données restent qualifiées de données de santé au sens du RGPD, articles 4-15 et 9-1, parce qu'elles permettent de relier un comportement cognitif à un individu identifiable dès lors qu'on dispose de la base nominative côté PC. Le régime juridique applicable est donc celui des données sensibles, qui impose des garanties renforcées de minimisation, d'intégrité, de confidentialité, et de souveraineté.

Le porteur du projet a posé comme exigence non négociable qu'aucune donnée du dispositif ne quitte les deux applications, ni vers un serveur tiers, ni vers un service cloud, ni sous forme de télémétrie applicative, ni à des fins d'analyse d'usage. Cette exigence dépasse la stricte conformité RGPD ; elle adopte une posture de souveraineté numérique fondée sur le principe que la donnée la plus sûre est celle qui ne quitte pas l'environnement local du cabinet.

L'enjeu n'est pas seulement technique. Le porteur du projet doit pouvoir défendre cette posture devant un jury de soutenance qui posera nécessairement la question. Une réponse vague, du type « il n'y a pas de cloud parce qu'on n'en a pas eu le temps », serait fragile. Une réponse architecturée et tracée par ADR, qui montre que le choix est délibéré, motivé, et vérifiable empiriquement, est défendable.

## Options envisagées

La première option est une architecture cloud classique, avec un backend hébergé qui centralise les données patient et auquel les applications se synchronisent en permanence. Elle est rejetée pour quatre raisons cumulées : elle introduit un sous-traitant au sens RGPD avec les obligations de DPA et de garanties que cela implique, elle ajoute une surface d'attaque réseau qui nécessite chiffrement en transit, gestion des certificats, authentification, journalisation des accès, elle dépend d'une connectivité fiable au cabinet ce qui n'est pas systématiquement assuré, et elle introduit un coût récurrent d'hébergement qui n'a pas de justification fonctionnelle pour un cabinet mono-praticien.

La seconde option est une architecture hybride avec une synchronisation optionnelle vers un serveur privé du praticien, par exemple un NAS local ou un VPS personnel. Elle est rejetée pour la première version pour une raison de discipline de périmètre : elle introduit une complexité de gestion de clés, de réconciliation de schémas et de sauvegardes qui doublerait l'effort de développement sans apporter de valeur fonctionnelle pour un usage mono-poste. Elle pourra être réévaluée dans une future itération, à condition qu'elle fasse l'objet d'un nouvel ADR avec ré-évaluation RGPD complète.

La troisième option est une architecture strictement offline, où les deux applications fonctionnent sans aucun protocole réseau et où le seul transfert entre elles passe par scan optique de QR code. Cette option est retenue. Elle est cohérente avec le besoin fonctionnel réel (un praticien, une tablette, un PC, un cabinet), elle réduit drastiquement la surface d'attaque, elle évite tout sous-traitant RGPD, et elle est défendable de manière simple et claire devant un jury.

## Option retenue

La politique de souveraineté retenue se traduit par cinq engagements concrets qui s'appliquent à tout le code du projet et à toutes ses futures évolutions tant que cet ADR reste actif.

Premier engagement, aucune fonction des deux applications ne nécessite ni n'autorise une connexion internet. Toute la chaîne fonctionnelle (création de profil, jeu, métriques, transfert vers PC, fiche patient, graphique d'évolution) est conçue pour fonctionner avec un appareil placé en mode avion. Toute proposition de feature future qui dérogerait à ce principe sera traitée comme un changement architectural majeur, pas comme une simple évolution.

Deuxième engagement, aucune bibliothèque tierce intégrée au projet n'effectue d'appel réseau à l'exécution dans le périmètre d'usage du projet. La liste des paquets et la vérification de leur comportement réseau est tenue à jour dans l'ADR-05 « Bibliothèques tierces retenues et politique d'évaluation ». Toute mise à jour majeure d'un de ces paquets déclenche une nouvelle revue avant intégration.

Troisième engagement, aucune télémétrie applicative, aucun rapport d'erreur automatique vers un serveur tiers (type Sentry, Bugsnag, Firebase Crashlytics ou équivalent), aucune analyse d'usage. Les défaillances de l'application sont remontées par l'utilisateur au porteur du projet par des canaux humains, hors du dispositif lui-même.

Quatrième engagement, le seul transfert de données entre les deux applications passe par scan optique de QR code. Ce canal est air-gapped par construction : il n'utilise aucune pile réseau, aucun socket TCP ou UDP, aucun service de découverte. La tablette affiche un QR sur son écran, le PC le lit avec sa webcam, ou inversement. Le transfert est physiquement contraint à la pièce où se trouvent les deux appareils.

Cinquième engagement, le réseau local Wi-Fi du cabinet est utilisé uniquement comme moyen de fait pour que la tablette et le PC se trouvent à proximité ; aucun protocole réseau n'est utilisé par les applications elles-mêmes. La tablette pourrait être en Wi-Fi, en données mobiles désactivées, ou en mode avion, sans aucune incidence fonctionnelle sur le dispositif.

## Conséquences

### Audits opérationnels avant soutenance

Le sprint 5 de recette comportera explicitement quatre audits dont les résultats seront documentés et inclus au dossier de soutenance.

Audit 1, fonctionnel en mode avion sur la tablette. Une session complète de bout en bout est jouée avec la Lenovo Tab P12 mise en mode avion, depuis la création d'un patient fictif jusqu'à l'export de session par QR code. Toutes les fonctions du périmètre soutenance doivent passer sans dégradation. Tout point qui échouerait en mode avion serait par définition une régression à corriger.

Audit 2, analyse statique du binaire Windows produit par la cross-compile Go vers Windows. La commande `strings logiciel_pc.exe` est exécutée et le résultat est filtré pour rechercher la présence d'URLs externes, de noms de domaines suspects et de chaînes de type API key. Toute occurrence non triviale est tracée et justifiée ou corrigée.

Audit 3, capture réseau Wireshark sur la machine Windows pendant une session complète d'usage du logiciel praticien. La capture est filtrée sur le PID du processus `logiciel_pc.exe` et l'absence de paquet sortant vers une destination autre que la machine locale doit être confirmée. La capture brute et le filtrage sont archivés.

Audit 4, observation logcat sur la tablette Android pendant une session complète. Tous les évènements émis par le processus de l'application sont collectés et inspectés. La présence éventuelle d'appels réseau émanant de la couche applicative serait un défaut à traiter.

Les quatre rapports d'audit sont documentés dans `docs/comptes_rendus/sprint_05.md` et sont inclus au dossier de soutenance.

### Limitation connue hors périmètre projet

La tablette Lenovo Tab P12 fonctionne sous Android 13 stock, qui inclut nativement les Google Mobile Services et qui effectue, en arrière-plan, des communications avec l'écosystème Google pour la vérification de mises à jour, les services de localisation passive, la synchronisation des comptes utilisateur, et d'autres fonctions système. Ces communications ne sont pas émises par le code applicatif du projet et ne contiennent pas de données de l'application, mais elles existent au niveau OS et ne sont pas contrôlables depuis l'application. Pour atteindre une étanchéité réseau totale au niveau du système d'exploitation, il faudrait remplacer la couche Android stock par une distribution sans Google Services type LineageOS sans GApps ou GrapheneOS, ce qui est techniquement faisable mais sort du périmètre réaliste de la première itération du projet.

Cette limitation est documentée ouvertement plutôt qu'occultée. Elle est une honnêteté défensive en soutenance : reconnaître ce qu'on ne contrôle pas, et expliquer où s'arrête la responsabilité applicative, est plus solide que prétendre une étanchéité totale qui ne tient pas à l'inspection.

### Évolutivité encadrée

Toute future évolution du projet qui réintroduirait une forme de communication externe, qu'il s'agisse d'une synchronisation multi-cabinets, d'une sauvegarde cloud chiffrée, d'un module de télésoin, ou d'un export vers un dossier patient externe type DMP, devra obligatoirement faire l'objet d'un nouvel ADR explicite qui supersède ou amende le présent ADR-06. Ce nouvel ADR devra détailler le besoin fonctionnel, les options techniques envisagées, et surtout une ré-évaluation RGPD complète incluant identification des sous-traitants éventuels, base légale du traitement, mesures de chiffrement en transit et au repos, et procédure d'exercice des droits des personnes concernées.

Tant qu'un tel ADR n'est pas adopté, toute introduction d'une dépendance réseau dans le code, même par accident transitivement via une mise à jour de paquet, est traitée comme une régression critique à corriger immédiatement.
