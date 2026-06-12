# ADR-12 - Bibliotheque excelize pour l'export Excel du suivi patient

## Statut

Accepte. Complete l'ADR-05 (politique d'evaluation des bibliotheques tierces) en
y ajoutant excelize cote PC, et s'appuie sur l'ADR-06 (souverainete des donnees)
pour l'attestation d'absence de communication reseau.

## Contexte

Le lot 2 du sprint 4 produit, pour chaque patient, un fichier Excel de suivi
genere ou mis a jour automatiquement a chaque session recue. Ce classeur comporte
trois feuilles : une synthese avec quatre cartes par emotion et un tableau
seances par emotions en mise en forme conditionnelle, un detail clinique par
seance, et une feuille d'evolution avec un graphique en courbes par emotion.
Cela exige une bibliotheque Go capable d'ecrire des fichiers xlsx avec plusieurs
feuilles, des styles de cellule incluant la couleur de fond, de la mise en forme
conditionnelle et des graphiques.

Les contraintes structurantes du projet sont la compilation croisee vers Windows
depuis Linux, la regle pur Go sans CGO pour les modules metier actee par les
ADR-02 et ADR-04, et la souverainete des donnees de l'ADR-06 qui interdit tout
appel reseau. Conformement a l'ADR-05, aucune dependance n'est ajoutee a go.mod
sans un ADR justifiant les quatre criteres d'evaluation.

## Options envisagees

La premiere option etait de produire un simple fichier CSV avec la bibliotheque
standard encoding/csv. Elle a l'avantage de zero dependance mais ne sait ni gerer
plusieurs feuilles, ni colorer des cellules, ni faire de mise en forme
conditionnelle, ni inserer un graphique. Elle est donc incompatible avec
l'objectif clinique du lot, ou la mise en forme conditionnelle revele les
emotions en difficulte et le graphique montre la progression. Elle n'est conservee
que comme repli ultime degrade.

La deuxieme option etait tealeg/xlsx. Elle ecrit du xlsx mais sa couverture est
plus limitee, le support des graphiques et de la mise en forme conditionnelle
etant partiel ou absent selon les versions, et sa maintenance est moins soutenue.
Ecartee.

La troisieme option, retenue, est xuri/excelize en version 2. Elle couvre
l'integralite des besoins, est ecrite en pur Go et est tres activement maintenue.

## Option retenue : github.com/xuri/excelize/v2

### Verification des quatre criteres de l'ADR-05

Premier critere, licence. excelize est sous licence BSD-3-Clause, qui figure dans
la liste des licences permissives acceptees par l'ADR-05.

Deuxieme critere, pur Go sans CGO. La bibliotheque est ecrite en pur Go et ne
requiert pas CGO. Ses dependances directes (mscfb, efp, nfp, go-deepcopy,
golang.org/x/crypto, golang.org/x/image, golang.org/x/net, golang.org/x/text)
sont elles-memes pures Go. La compilation croisee vers Windows n'est pas affectee :
excelize se compile en pur Go independamment du toolchain C deja requis par Fyne
et la capture webcam, et la regle pur Go des modules metier reste donc respectee.

Troisieme critere, maintenance active. La version 2.10.1 a ete publiee le 24
fevrier 2026, le depot compte plus de mille quatre cents commits et enchaine des
cycles de release reguliers sur les series 2.8, 2.9 et 2.10. Le critere d'une mise
a jour dans les douze mois est largement satisfait.

Quatrieme critere, absence de communication reseau. excelize n'importe ni
net/http ni aucun mecanisme d'ouverture de connexion. La presence de
golang.org/x/net dans ses dependances, que l'ADR-05 signale explicitement, est ici
documentee et justifiee : excelize n'en utilise que le sous-paquet
golang.org/x/net/html/charset, employe comme CharsetReader du decodeur
encoding/xml pour convertir en UTF-8 les contenus XML internes des fichiers xlsx
encodes dans d'autres jeux de caracteres. Il s'agit de decodage de caracteres
strictement local, sans aucune communication reseau.

### Couverture fonctionnelle verifiee

L'ecriture de plusieurs feuilles est assuree par NewSheet et la gestion des
feuilles associee. La couleur de fond des cellules passe par NewStyle avec un Fill
applique via SetCellStyle. La mise en forme conditionnelle est fournie par
SetConditionalFormat et NewConditionalStyle. Le graphique est natif via AddChart,
avec un type Line et des series, axes et legende configurables. Le graphique
d'evolution sera donc un graphique Excel natif lisant une plage de cellules, et
non une image inseree.

### Traitement des emotions non evaluees dans le graphique

Le graphique en courbes lit une plage de cellules. Une emotion non evaluee sur une
seance laisse la cellule correspondante vide et non a zero. Excel rend les cellules
vides comme des trous dans la courbe, ce qui reproduit nativement le comportement
voulu, un trou et non une chute a zero, coherent avec le traitement applique
partout ailleurs dans le projet. Si le rendu des trous par Excel s'averait
insatisfaisant a l'implementation, le repli serait d'inserer une image du graphique
deja produit par le logiciel ; le graphique natif reste neanmoins privilegie.

## Consequences

Le fichier go.mod du sous-projet PC gagne github.com/xuri/excelize/v2 comme
dependance directe. La regle pur Go sans CGO des modules metier demeure respectee
puisque excelize est pur Go.

excelize requiert Go 1.25.0 au minimum ; le sous-projet PC est en Go 1.26.2, aucun
changement de toolchain n'est necessaire.

L'attestation reseau de l'ADR-06 est etendue a excelize : la bibliotheque est
strictement locale et sa dependance a golang.org/x/net se limite au decodage de
charset via html/charset, sans appel reseau.

Le code de generation Excel vivra dans un module metier dedie cote PC, par exemple
internal/export, testable sans interface graphique, et sera declenche a la
reception et l'enregistrement d'une session.

## Reserve

La verification ci-dessus s'appuie sur la documentation publique et le go.mod de la
version 2.10.1. Au moment d'ajouter la dependance, l'absence effective d'usage
reseau sera reconfirmee localement par go list -deps et recherche des paquets
reseau dans le graphe de dependances, comme l'exige la politique de l'ADR-05.
