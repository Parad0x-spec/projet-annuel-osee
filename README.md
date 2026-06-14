# OSEE — Outil de Suivi de l'Évolution Émotionnelle

OSEE est un dispositif logiciel destiné à un praticien qui accompagne des enfants dans la reconnaissance des émotions, en particulier des enfants suivis pour un TDAH ou un trouble du spectre de l'autisme.

Le dispositif se compose de deux applications complémentaires :

- une **application sur tablette** (Android), avec laquelle l'enfant joue à reconnaître des émotions sur des visages ;
- un **logiciel sur ordinateur** (Windows), avec lequel le praticien gère ses patients et suit leur évolution au fil des séances.

Le jeu reprend le principe des images « où est Charlie » : l'enfant retrouve, sur une planche, les visages exprimant une émotion donnée (joie, colère, tristesse, peur).

## Particularité : un système sans réseau

OSEE fonctionne **entièrement hors ligne**. La tablette et l'ordinateur ne sont jamais connectés à internet et ne communiquent pas directement entre eux. Tout échange passe par des **QR codes** affichés à l'écran d'un appareil et lus par la caméra de l'autre.

Ce choix répond à une exigence de confidentialité : les données concernent des mineurs suivis dans un cadre de soin, et le dispositif est conçu pour qu'aucune donnée ne puisse fuir par le réseau. Les QR codes échangés sont signés cryptographiquement (Ed25519) pour garantir leur authenticité.

## Organisation du dépôt

```
.
├── tablette_flutter/      Application tablette (Flutter / Dart)
├── logiciel_pc_go/        Logiciel praticien (Go / Fyne)
├── outils/                Outil d'annotation des planches (HTML)
├── scripts/               Scripts de compilation (APK, exécutable Windows)
├── docs/                  Documentation du projet
└── README.md
```

## Technologies

**Application tablette** — Flutter 3.41 / Dart 3.11
flutter_riverpod (état), go_router (navigation), sqflite (SQLite), cryptography (Ed25519), qr_flutter (génération de QR), mobile_scanner (lecture de QR).

**Logiciel praticien** — Go 1.26
fyne (interface), modernc.org/sqlite (base, pur Go), excelize (export Excel), go-qrcode (génération de QR), gozxing (lecture de QR), pion/mediadevices (webcam). La signature Ed25519 utilise la bibliothèque standard.

## Compilation

### Application tablette (APK)

La compilation se lance depuis le dossier `tablette_flutter/` :

```bash
cd tablette_flutter
flutter pub get
flutter build apk --debug
```

L'APK produit se trouve dans `tablette_flutter/build/app/outputs/flutter-apk/`. Il s'installe sur la tablette avec `adb install`.

### Logiciel praticien (exécutable Windows)

La compilation produit un exécutable Windows autonome. Elle nécessite l'outillage de compilation croisée mingw-w64 (le logiciel utilise du code natif pour l'interface et la webcam) :

```bash
cd logiciel_pc_go
mkdir -p build
CC=x86_64-w64-mingw32-gcc CXX=x86_64-w64-mingw32-g++ CGO_ENABLED=1 GOOS=windows GOARCH=amd64 \
  go build -ldflags="-s -w -H=windowsgui -extldflags '-static'" -o build/logiciel_pc.exe ./cmd/logiciel_pc
```

Ces deux commandes de compilation sont également disponibles clés en main dans `scripts/build_apk.sh` et `scripts/build_pc_windows.sh`.

L'exécutable produit ne demande aucune installation de dépendance sur le poste du praticien.

## Documentation

La documentation complète se trouve dans le dossier `docs/` :

- **documentation_generale** — vue d'ensemble du système, architecture, protocole QR, sécurité, modèle de données ;
- **documentation_logiciel_praticien** — détail technique du logiciel PC (Go / Fyne) ;
- **documentation_application_tablette** — détail technique de l'application tablette (Flutter / Dart) ;
- **guide_utilisation** — mode d'emploi à destination du praticien.

Chaque document est disponible en Markdown (lisible directement) et en PDF (rendu mis en forme, dans `docs/pdf/`).

## Auteur

Clément Boyer — ESGI — Projet annuel, juin 2026.
