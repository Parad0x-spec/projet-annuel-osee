# ADR-02 - Go pour le logiciel PC

## Contexte

Le logiciel PC est destiné à un praticien tournant sous Windows 10 ou 11. Il doit gérer une base locale de fiches patients, recevoir des données de séance par lecture de QR via webcam, afficher des graphiques d'évolution, et générer un QR d'appairage pour la tablette. Le développement se fait depuis un poste Arch Linux.

## Options envisagées

La première option est Go avec une bibliothèque d'interface graphique comme Fyne ou Wails. Go offre une compilation croisée native vers Windows depuis Linux, un binaire unique sans dépendance, une excellente bibliothèque standard, et un écosystème solide pour SQLite, QR et webcam. La seconde option est Python avec Tkinter ou PyQt. Elle est rapide à prototyper mais nécessite un installateur lourd côté praticien et la distribution est plus délicate. La troisième option est Electron avec Node.js. Elle propose une expérience visuelle riche mais consomme beaucoup de ressources et alourdit le livrable.

## Option retenue

Go est retenu avec Fyne pour l'interface graphique. La compilation croisée vers Windows depuis Arch Linux se fait simplement via `GOOS=windows GOARCH=amd64 go build`. Le binaire produit est autonome et s'exécute sans installation préalable côté praticien à l'exception éventuelle d'un pilote webcam standard. La cohérence avec les notes initiales du projet qui mentionnaient déjà Go est conservée.

## Conséquences

Le langage du PC est Go. La stack PC dépend du SDK Go qui doit être installé sur le poste de développement, ainsi que du toolchain de compilation croisée pour Windows. Pour la webcam, la bibliothèque retenue sera évaluée dans un ADR ultérieur, gocv et son binding OpenCV étant l'option la plus probable. Le binaire Windows est livré seul sans installateur dans la première itération, un installeur MSI sera étudié post-soutenance si nécessaire.
