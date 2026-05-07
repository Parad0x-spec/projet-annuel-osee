# CLAUDE.md - Sous-projet logiciel PC Go

## Contexte

Ce sous-projet contient le logiciel utilisé par le praticien sur son PC Windows. Il gère la base nominative des patients, génère le QR d'appairage initial scanné par la tablette, scanne par webcam le QR de session généré par la tablette en fin de séance, stocke les sessions reçues, et présente une fiche patient avec un graphique d'évolution. Le développement se fait sur Arch Linux et la cible de production est Windows 10 ou 11 par compilation croisée.

Le `CLAUDE.md` racine du dépôt définit les règles globales du projet. Ce fichier complète ces règles avec les spécificités Go.

## Stack et paquets retenus

Le projet utilise Go 1.26. Le module est nommé `projet_annuel/logiciel_pc_go`. Les paquets retenus sont les suivants. Pour l'interface graphique, `fyne.io/fyne/v2` qui produit un binaire autonome et compile vers Windows depuis Linux. Pour SQLite, `modernc.org/sqlite` qui est un pilote pur Go et évite la dépendance à CGO ce qui simplifie énormément la compilation croisée vers Windows. Pour la génération de QR, `github.com/skip2/go-qrcode`. Pour le décodage de QR depuis une image webcam, `github.com/makiuchi-d/gozxing` qui reste pure Go. Pour la capture webcam, `github.com/pion/mediadevices` utilisé en mode raw frame uniquement, sans imports de codecs, choix acté par l'ADR-04 pour couvrir Linux V4L2 et Windows DirectShow avec une seule bibliothèque. Pour la cryptographie de signature, la bibliothèque standard `crypto/ed25519`.

Aucun autre paquet ne doit être ajouté sans création préalable d'un ADR justifiant le choix. La règle CGO-free reste non négociable pour le pilote SQLite (`modernc.org/sqlite`) et pour les modules métier purs (`internal/patients`, `internal/sessions`, `internal/storage`, `internal/crypto`), qui doivent demeurer compilables et testables sans dépendance C. Elle ne s'applique pas, par dérogation actée dans l'ADR-04, à la stack UI Fyne ni à la capture webcam via `github.com/pion/mediadevices`, faute d'alternative pure Go portable Linux et Windows. Ces deux dérogations sont périmétrées et ne valent pas blanc-seing pour de futures dépendances.

## Architecture côté PC

Le code est organisé selon les conventions Go standard. Le dossier `cmd/logiciel_pc/` contient le point d'entrée `main.go` qui configure et démarre l'application Fyne. Le dossier `internal/` contient toute la logique métier, organisée par domaine. Les sous-dossiers prévus sont `internal/patients/` pour la gestion des fiches patients nominatives, `internal/sessions/` pour la réception et le stockage des sessions reçues, `internal/qr/` pour la génération du QR d'appairage et le scan webcam, `internal/storage/` pour l'accès SQLite et les migrations, `internal/crypto/` pour les opérations de signature et de vérification, et `internal/ui/` pour les écrans Fyne.

La logique métier dans `internal/` n'importe jamais de paquet `internal/ui/`. L'inverse est autorisé. Cette règle garantit que le métier reste testable sans démarrer d'interface graphique.

## Conventions Go spécifiques

Les noms de types et fonctions exportés respectent la convention Go en `PascalCase`. Les noms internes sont en `camelCase`. Les paquets ont des noms courts au singulier. Les erreurs sont retournées et non gérées par panic, sauf au démarrage de l'application si une dépendance critique manque. Les opérations longues acceptent un `context.Context` en premier paramètre.

Le code n'a pas de commentaires. Les noms suffisent. La documentation des comportements va dans `docs/specs/` côté projet.

Les tests sont placés dans le même dossier que le code testé, dans des fichiers suffixés `_test.go`. La commande de référence est `go test ./...`. Le mode race est activé pour les tests qui touchent à la concurrence par `go test -race ./...`.

## Build

Le build local pour test sous Linux se fait par `go run ./cmd/logiciel_pc`. La compilation croisée vers Windows se fait par `GOOS=windows GOARCH=amd64 go build -o build/logiciel_pc.exe ./cmd/logiciel_pc`. Cette commande est encapsulée dans le script `scripts/build_pc_windows.sh` à la racine du dépôt.

La compilation croisée vers Windows requiert le toolchain `mingw-w64-gcc` à cause de Fyne et de la capture webcam, dérogations CGO-free actées dans l'ADR-04. Le pilote SQLite reste en `modernc.org/sqlite` pour ne pas réintroduire de complexité supplémentaire, et les modules métier (`internal/patients`, `internal/sessions`, `internal/storage`, `internal/crypto`) doivent rester compilables sans dépendance C. Toute proposition de paquet CGO en dehors du périmètre déjà cadré (UI et webcam) doit être refusée ou justifiée par un nouvel ADR.

## Tests

Les tests unitaires couvrent la logique métier des paquets `internal/patients/`, `internal/sessions/`, `internal/crypto/` et `internal/storage/`. Les tests d'intégration couvrent le canal QR de bout en bout en utilisant des fixtures d'images. La couverture cible n'est pas un nombre fixe, mais chaque fonction publique doit avoir au moins un test nominal et un test d'erreur.

## Règle de validation par étapes

La règle de validation par étapes du `CLAUDE.md` racine s'applique strictement ici. Tu ne fais qu'une seule chose à la fois, tu décris ce que tu as fait et tu attends confirmation avant de passer à la suite.
