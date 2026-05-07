# ADR-04 - Bibliothèque de capture webcam et décodage QR côté PC

## Contexte

Le logiciel PC doit scanner via webcam le QR de session généré par la tablette, le décoder, vérifier sa signature ed25519, puis enregistrer la session. La cinématique est imposée par `docs/specs/protocole_qr.md`. Le développement se fait sur Arch Linux, la cible est Windows 10 ou 11. La capture doit donc fonctionner en V4L2 sous Linux et en DirectShow sous Windows. Le décodage QR proprement dit reste assuré par `github.com/makiuchi-d/gozxing` choisi au sprint 1, qui est pure Go et n'est pas remis en question dans cet ADR.

Le sprint 1 a montré que la règle CGO-free édictée dans le `CLAUDE.md` du sous-projet `logiciel_pc_go` ne peut pas s'appliquer à toute la stack. Fyne tire déjà du CGO via `go-gl/glfw` et la webcam, qui dépend de pilotes système, n'a pas d'alternative purement Go portable. Cet ADR tranche d'une part la nuance à apporter à la règle CGO-free, d'autre part la bibliothèque webcam à retenir.

## Options envisagées

`github.com/blackjack/webcam` est un binding V4L2 pur, léger, sans dépendance externe. Il est limité à Linux. Le portage Windows imposerait une seconde bibliothèque et un partitionnement par tags de build, doublant la surface de test et le risque de divergence comportementale. Écartée.

`gocv.io/x/gocv`, sous licence Apache 2.0, version 0.43.0 publiée en janvier 2026, est le binding Go d'OpenCV. Il supporte nativement Linux, Windows et macOS. Il dépend d'une installation OpenCV 4.12.0 sur la machine de build et sur la machine cible. Pour la compilation croisée depuis Arch vers Windows, cela imposerait d'installer en plus de `mingw-w64-gcc` les en-têtes et bibliothèques OpenCV pour Windows, et de livrer au praticien le binaire accompagné de 30 à 100 Mo de DLL OpenCV. La puissance d'OpenCV au-delà de la capture est inutile puisque le décodage est confié à gozxing. Disproportionnée pour un usage qui se limite à acquérir un cliché et le passer à un décodeur.

`github.com/pion/mediadevices`, sous licence MIT, version 0.10.0 publiée en avril 2026, issue de l'écosystème Pion. Elle expose une API uniforme pour l'accès caméra sur Linux, Windows et macOS via CGO. Son architecture permet d'utiliser la capture seule sans tirer la stack de codecs (`x264`, `vpx`, `opus`), ce qui est notre cas puisqu'on veut juste un cliché RGBA pour gozxing. Sous Linux elle utilise V4L2, sous Windows elle s'appuie sur DirectShow cohérent avec les drivers webcam standard de Windows 10 et 11. Aucune installation système supplémentaire n'est requise au-delà du `mingw-w64-gcc` déjà nécessaire pour Fyne, et aucune DLL n'est à livrer.

## Option retenue

`github.com/pion/mediadevices` est retenue pour la capture webcam, en mode raw frame uniquement, sans imports de codecs. Le décodage QR reste assuré par `github.com/makiuchi-d/gozxing` qui prend en entrée une `image.Image` standard, ce qui s'interface naturellement avec la sortie de pion.

La règle CGO-free du `CLAUDE.md` du sous-projet `logiciel_pc_go` est nuancée comme suit. Elle reste non négociable pour le pilote SQLite, qui doit demeurer `modernc.org/sqlite`, et pour les modules métier purs (`internal/patients`, `internal/sessions`, `internal/storage`, `internal/crypto`), qui doivent rester compilables et testables sans dépendance C. Elle ne s'applique pas à la stack UI, où Fyne tire du CGO sans alternative pure Go équivalente, ni à la capture webcam pour la même raison. Ces deux dérogations sont actées, périmétrées, et ne valent pas blanc-seing pour de futures dépendances.

Le critère décisif est la simplicité de la compilation croisée depuis Arch vers Windows : pion ne demande rien au-delà de mingw-w64 déjà requis par Fyne, gocv exige une installation OpenCV double et la livraison de DLL. Le critère secondaire est la maintenance, où les deux bibliothèques sont actives et réputées mais où la richesse fonctionnelle de gocv ne sert ici à rien. Le critère tertiaire est l'empreinte binaire, où pion produit un exécutable autonome de quelques dizaines de Mo (essentiellement Fyne) alors que gocv impose 30 à 100 Mo de DLL en plus.

## Conséquences

Sur le poste Arch Linux, l'unique prérequis est le paquet `mingw-w64-gcc` du dépôt officiel, déjà annoncé au sprint 1 pour Fyne. Aucune installation OpenCV ni autre bibliothèque C n'est nécessaire. La dépendance `github.com/pion/mediadevices` sera ajoutée au `go.mod` du sous-projet PC au moment de la première implémentation de scan, en respectant la règle « pas de dépendance déclarée tant qu'aucun code ne l'importe » pour éviter la régression du sprint 1.

Sur le PC Windows du praticien, aucune installation préalable n'est requise au-delà des pilotes webcam standard de Windows 10 ou 11. Le livrable reste un `logiciel_pc.exe` autonome, conforme à l'objectif de distribution simple posé dans l'ADR-02.

Le script `scripts/build_pc_windows.sh` doit exporter `CC=x86_64-w64-mingw32-gcc`, `CXX=x86_64-w64-mingw32-g++` et `CGO_ENABLED=1` avant `go build`. Cet ajustement était de toute façon requis par Fyne. La cible reste `GOOS=windows GOARCH=amd64`. Un test concret de la cross-compilation est prévu en deuxième tâche du sprint 2 pour valider que l'ensemble Fyne plus pion traverse proprement la chaîne mingw.

La règle CGO-free nuancée par cet ADR sera répercutée dans le `CLAUDE.md` du sous-projet `logiciel_pc_go` par une mise à jour du paragraphe correspondant, action de clôture qui ne fait pas partie du présent fichier.
