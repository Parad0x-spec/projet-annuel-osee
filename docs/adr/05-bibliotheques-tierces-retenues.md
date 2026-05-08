# ADR-05 - Bibliothèques tierces retenues et politique d'évaluation

## Contexte

Le sprint 1 a figé une dizaine de bibliothèques tierces directement dans les `CLAUDE.md` des deux sous-projets, sans rédaction d'ADR formel pour chacune. Le sprint 2 a complété ce socle avec `github.com/google/uuid` côté PC pour la génération des identifiants d'appairage, et `sqflite_common_ffi` côté tablette en `dev_dependencies` uniquement pour les tests SQLite headless. Ces deux ajouts ont été tracés dans les comptes rendus mais n'avaient pas non plus d'ADR dédié.

Le présent ADR consolide à posteriori les choix retenus, justifie chacun par rapport aux alternatives envisagées, atteste l'absence de communication réseau dans le code source intégré au binaire de production, et pose une politique d'évaluation pour les futurs ajouts. Il ne se substitue pas aux ADR existants : ADR-01 reste la décision-mère sur Flutter, ADR-02 sur Go, ADR-03 sur SQLite, ADR-04 sur la capture webcam et le décodage QR. Il les complète en couvrant le second cercle des dépendances pratiques.

## Options envisagées

L'option par défaut était de continuer sans ADR formel sur les bibliothèques de second rang, en se reposant sur les `CLAUDE.md` de sous-projet pour la traçabilité. Cette option a été écartée parce qu'elle ne traite pas la question de la souveraineté des données et de l'attestation réseau, qui devient critique à l'approche de la soutenance et qui sera reprise dans l'ADR-06 sur la souveraineté. Une seconde option aurait été de produire un ADR distinct par paquet, ce qui aurait gonflé le dossier de douze à quinze fichiers pour une valeur informationnelle marginale par rapport à un document consolidé. Le présent format consolidé est retenu.

## Options retenues

### Côté PC Go

#### `fyne.io/fyne/v2`

Retenue pour l'UI desktop, sous licence BSD-3-Clause, version `v2.7.3`. Les alternatives étudiées sont Wails (qui repose sur un moteur web embarqué et ajoute une chaîne de build node.js inutile pour ce projet), `lxn/walk` (Windows-only, donc incompatible avec le développement multiplateforme depuis Arch Linux), et Gioui (séduisant techniquement mais beaucoup moins documenté que Fyne pour les usages pratiques). Fyne offre le meilleur ratio rapidité de prise en main / qualité du livrable Windows pour un projet à temps contraint. La conséquence CGO via `go-gl/glfw` est actée par l'ADR-04. Au sprint 2, la cross-compile depuis Arch Linux a produit un binaire PE32+ valide qui, lancé sous Wine, charge correctement et atteint la couche fenêtrage Windows (invocations `DwmSetWindowAttribute` et `ChangeWindowMessageFilterEx` tracées), ce qui est un signal positif sur la chaîne Go plus CGO plus mingw plus Fyne. La fenêtre ne s'est cependant pas affichée visuellement sous Wine à cause du combo NVIDIA plus Wayland plus Mesa documenté dans le compte rendu de la tâche 2 du sprint 2 ; c'est une limite de l'environnement de test sur ce poste, pas un défaut du binaire. La validation visuelle officielle reste à faire sur VM Proxmox Windows réel.

#### `modernc.org/sqlite`

Retenue pour le pilote SQLite, sous licence BSD-3-Clause, version `v1.50.0`. C'est un port pur Go du moteur SQLite, transcompilé depuis le C source par l'auteur Jan Mercl. L'alternative principale est `mattn/go-sqlite3` qui est largement plus mature mais nécessite CGO et une chaîne de compilation C correctement configurée pour la cible Windows, ce qui réintroduirait une complexité que l'on a explicitement voulu éviter pour le pilote SQLite (l'ADR-04 dérogation CGO ne s'applique qu'à l'UI et à la webcam). Le port pur Go est légèrement plus lent que le binding CGO mais largement suffisant pour les volumes attendus en cabinet, soit quelques dizaines de patients et quelques centaines de sessions au plus.

#### `github.com/skip2/go-qrcode`

Retenue pour la génération de QR côté PC, sous licence MIT, dernier hash de release `v0.0.0-20200617195104-da1b6568686e` daté de juin 2020. Le dépôt est faiblement maintenu mais l'API publique est stable depuis longtemps et le code est suffisamment court pour être audité en quelques minutes. L'alternative `yeqown/go-qrcode` est plus récente et offre des options de stylisation que ce projet n'utilise pas. La maturité de skip2 et la simplicité de son API ont primé sur la fraîcheur de yeqown. Si une régression apparaissait pendant la fin du sprint 2 ou au sprint 3, le coût de bascule vers yeqown serait faible, l'API d'encodage étant comparable.

#### `github.com/makiuchi-d/gozxing`

Retenue pour le décodage de QR à partir d'images, sous licence Apache 2.0, version `v0.1.1`. C'est un port Go du décodeur Java ZXing largement utilisé dans le monde Android et qui sert de référence pour le décodage de codes-barres et de QR. Aucune alternative pure Go crédible et maintenue n'a été identifiée. La bibliothèque accepte une `image.Image` standard de la bibliothèque Go en entrée, ce qui s'interface naturellement avec ce que produit `pion/mediadevices` retenu en ADR-04.

#### `github.com/google/uuid`

Retenue pour la génération des UUID v4 utilisés comme `pairing_id` dans le protocole QR, sous licence BSD-3-Clause, version `v1.6.0` publiée en janvier 2024. La bibliothèque est strictement locale, vérifiée par lecture du dépôt GitHub : aucun appel réseau, aucune télémétrie, aucune intégration aux services Google. Elle implémente RFC 9562 et DCE 1.1 et expose une API minimale `uuid.NewString()` et `uuid.Parse()`. L'alternative `gofrs/uuid` est techniquement équivalente, légèrement plus active, mais n'apporte pas de différentiateur fonctionnel pour notre usage. Le choix de google/uuid s'est fait sur sa présence transitive depuis `modernc.org/sqlite` au sprint 1, ce qui évite d'introduire un nouveau graphe de dépendances pour un usage qui se résume à deux appels `NewString` et `Parse` dans tout le projet.

#### `github.com/pion/mediadevices`

Retenue pour la capture webcam, justification complète dans l'ADR-04 dont les conclusions ne sont pas reprises ici. Périmètre d'usage : raw frame uniquement, sans aucun import de codec.

### Côté tablette Flutter

#### `flutter_riverpod`

Retenue pour la gestion d'état, sous licence MIT, version `^3.3.1`. Les alternatives étudiées sont `bloc` (très puissant mais syntaxiquement plus lourd et surdimensionné pour le périmètre de la tablette qui reste limité à une poignée de providers), `provider` (le prédécesseur historique de Riverpod, en perte de vitesse), et `getx` (écarté pour son couplage fort de plusieurs préoccupations dans une seule API et son adoption controversée dans la communauté Flutter). Riverpod 3 offre une API moderne, des `Notifier` et `AsyncNotifier` propres, et une excellente compatibilité avec les tests via `ProviderScope` et son mécanisme d'`overrides`. Le code de la tablette en bénéficie déjà : les tests widget de la tâche 5 utilisent `appairageActuelProvider.overrideWith` pour court-circuiter SQLite sans mock complexe.

#### `go_router`

Retenue pour le routage, sous licence BSD-3-Clause, version `^17.2.3`, maintenue par l'équipe Flutter elle-même via le package officiel `flutter/packages`. L'alternative `auto_route` propose de la génération de code et un typage plus strict mais introduit un build runner et une étape de codegen qui ralentit les itérations de développement. Pour un projet à quelques routes (`/`, `/appairage`, `/jeu`, plus celles à venir au sprint 3 et 4), la simplicité de `go_router` est plus appropriée.

#### `mobile_scanner`

Retenue pour le scan QR via caméra Android, sous licence BSD-3-Clause, version `^7.2.0`, maintenue par `steenbakker.dev` en publisher vérifié sur pub.dev. Le paquet s'appuie sur CameraX et ML Kit côté Android, ce qui est l'API moderne recommandée par Google pour la caméra et le décodage de codes-barres. L'alternative historique `qr_code_scanner` est officiellement archivée depuis 2022 et son auteur recommande la migration vers `mobile_scanner`. Aucune autre option active n'a été identifiée.

#### `qr_flutter`

Retenue pour la génération de QR côté tablette (utilisée à la tâche 6 du sprint 2 pour le QR de session signé), sous licence BSD-3-Clause, version `^4.1.0`. C'est le choix de facto dans l'écosystème Flutter pour la génération de QR. Aucune alternative sérieuse n'a été identifiée.

#### `sqflite`

Retenue pour le stockage SQLite local côté tablette, sous licence BSD-2-Clause, version `^2.4.2+1`. C'est le binding officiel SQLite pour Flutter mobile, en cohérence avec le choix global SQLite acté en ADR-03. L'alternative `drift` (anciennement Moor) propose un ORM avec types générés par codegen, ce qui est puissant mais surdimensionné pour deux ou trois tables très simples. Le coût de l'abstraction supplémentaire ne se justifie pas à l'échelle de ce projet.

#### `sqflite_common_ffi` (uniquement en `dev_dependencies`)

Retenue uniquement pour les tests headless de la couche stockage, sous licence BSD-2-Clause, version `^2.4.0+3`. Cette dépendance est strictement dev-only : elle n'est pas embarquée dans l'APK livré à la tablette, comme tout paquet listé sous `dev_dependencies` dans `pubspec.yaml`. Sa fonction est de fournir une factory `databaseFactoryFfi` qui permet d'ouvrir une base SQLite en mémoire (`:memory:`) depuis un environnement de test Dart sans Android ni émulateur, en s'appuyant sur la bibliothèque native `sqlite3` du système hôte. Cela rend possibles les tests unitaires de la couche stockage en CI locale ou en `flutter test` direct sur Arch Linux.

#### `path_provider`

Retenue pour résoudre les chemins de stockage système (notamment `getApplicationDocumentsDirectory()`), sous licence BSD-3-Clause, version `^2.1.5`. C'est le standard de facto Flutter, maintenu par l'équipe Flutter elle-même. Aucune alternative n'a été sérieusement envisagée.

#### `cryptography`

Retenue pour les primitives ed25519 côté tablette, sous licence Apache 2.0, version `^2.9.0`, maintenue par `dint.dev` en publisher vérifié sur pub.dev. L'alternative `pointycastle` est plus complète et plus ancienne mais expose une API beaucoup plus bas niveau qui demanderait davantage de code de glue pour ed25519. Le paquet `cryptography` offre une API async moderne `Ed25519().newKeyPair()`, `sign()`, `verify()` qui s'aligne directement avec ce dont la feature appairage a besoin. Les signatures produites sont compatibles bit à bit avec celles produites par le `crypto/ed25519` de la stdlib Go côté PC, ce qui est validé empiriquement par les tests crypto des deux sous-projets.

## Politique d'évaluation pour les futurs ajouts

Tout nouveau paquet ajouté à l'un des deux sous-projets doit satisfaire les quatre critères suivants, vérifiés et tracés dans l'ADR qui justifie l'ajout :

Premier critère, licence permissive. Les licences acceptées sont MIT, BSD-2-Clause, BSD-3-Clause, Apache 2.0, et ISC. Sont exclues les licences GPL et AGPL qui contamineraient le livrable, et les licences propriétaires non-open-source.

Deuxième critère, absence de communication réseau dans le code source. Pour les paquets Go, vérification par recherche des imports `net`, `net/http`, `golang.org/x/net` et équivalents dans le code et ses dépendances directes. Pour les paquets Dart, vérification de l'absence d'imports `dart:io HttpClient`, `package:http`, `package:dio` et équivalents. Toute exception doit être documentée et justifiée par un usage explicite cohérent avec le périmètre du projet, qui ne fait à ce stade aucun appel réseau intentionnel.

Troisième critère, maintenance active. Le paquet doit avoir reçu une mise à jour ou un commit dans les douze mois précédant l'évaluation, sauf exception justifiée par la stabilité d'une API et la simplicité du code (cas de `skip2/go-qrcode` retenu malgré sa faible maintenance grâce à une API minimale et stable depuis quatre ans).

Quatrième critère, préférence pure Go ou pure Dart. À fonctionnalité équivalente, une bibliothèque sans dépendance C ou native est préférée pour préserver la simplicité de la chaîne de build, en particulier pour la cross-compilation. Les deux exceptions actées dans ce projet sont la stack UI Fyne et la capture webcam pion/mediadevices, dérogations actées dans l'ADR-04 et qui ne valent pas blanc-seing.

## Attestation du comportement réseau

Au moment où cet ADR est rédigé, après revue manuelle des sources des paquets retenus, aucun ne réalise de communication réseau dans le périmètre d'usage du projet. Les paquets `path_provider`, `sqflite`, `sqflite_common_ffi`, `flutter_riverpod`, `go_router`, `qr_flutter`, `cryptography` côté tablette et `modernc.org/sqlite`, `skip2/go-qrcode`, `gozxing`, `google/uuid`, `crypto/ed25519` côté PC sont strictement locaux. Les paquets `mobile_scanner` (Flutter) et `pion/mediadevices` (Go) accèdent à la caméra système mais ne réalisent aucun appel réseau. Le paquet `fyne.io/fyne/v2` peut faire de la résolution réseau pour des images distantes via `canvas.ImageFromURI` mais ce projet n'utilise pas cette API.

Cette attestation est valable pour les versions citées dans cet ADR. Toute mise à jour majeure d'un de ces paquets doit déclencher une nouvelle revue rapide pour confirmer que le comportement n'a pas dérivé.

## Sur les paquets hébergés par des organisations comme Google ou Pion

`github.com/google/uuid` et `github.com/pion/mediadevices` sont hébergés sur GitHub sous des organisations qui correspondent à des entreprises ou collectifs identifiés. Cette appartenance organisationnelle ne change rien au comportement du code une fois compilé. Un paquet open source publié sous licence BSD ou MIT par n'importe quelle organisation est strictement équivalent dans ses propriétés d'exécution à un paquet équivalent publié par un développeur individuel. Le critère opérationnel est la lecture du code source et la vérification de ses imports, pas l'identité de l'organisation hébergeuse.

`google/uuid` ne contient aucun appel à un service Google, aucune télémétrie, aucune dépendance à `cloud.google.com/go` ou à un quelconque SDK propriétaire. C'est un paquet utilitaire RFC 9562 que l'organisation Google maintient publiquement et que l'écosystème Go utilise massivement. `pion/mediadevices` est maintenu par le collectif Pion qui produit également la bibliothèque WebRTC Go de référence. Aucun des deux paquets ne pose de question particulière de souveraineté qui ne se poserait pas pour `mattn/go-isatty` ou `dustin/go-humanize` ou tout autre paquet utilitaire courant.

## Conséquences

Les `CLAUDE.md` des deux sous-projets restent la référence opérationnelle pour les développeurs et pour les sessions Claude Code. Le présent ADR est cité par eux comme source de la politique d'évaluation et comme attestation du comportement réseau, mais il n'a pas vocation à être lu intégralement à chaque session de travail.

Toute proposition d'ajout d'une nouvelle bibliothèque doit, avant de modifier `go.mod` ou `pubspec.yaml`, faire l'objet d'une note dans le compte rendu de sprint en cours, ou d'un ADR dédié si le choix est structurant. La règle minimale est qu'aucune dépendance ne soit ajoutée silencieusement.

À la fin du sprint 2, un `go mod tidy` côté PC et un `flutter pub upgrade --major-versions` blanc côté tablette seront exécutés pour aligner les versions résolues sur les contraintes de pubspec, et pour nettoyer les marqueurs `// indirect` qui ne reflètent plus la réalité après les imports concrets ajoutés au cours des sprints 1 et 2.

L'ADR-06 à venir sur la souveraineté des données s'appuiera sur l'attestation réseau du présent ADR pour formaliser le constat « aucune donnée patient ne quitte l'environnement local du cabinet », et pour le tracer au format attendu par la conformité RGPD documentaire.
