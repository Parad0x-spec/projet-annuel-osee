package main

import (
	"image/color"
	"strconv"
	"time"

	"fyne.io/fyne/v2"
	"fyne.io/fyne/v2/canvas"
	"fyne.io/fyne/v2/container"
	"fyne.io/fyne/v2/widget"

	"projet_annuel/logiciel_pc_go/internal/sessions"
)

var couleursEmotion = map[string]color.NRGBA{
	"joie":      {R: 0xF5, G: 0xA6, B: 0x23, A: 0xFF},
	"colere":    {R: 0xD3, G: 0x2F, B: 0x2F, A: 0xFF},
	"tristesse": {R: 0x19, G: 0x76, B: 0xD2, A: 0xFF},
	"peur":      {R: 0x7B, G: 0x1F, B: 0xA2, A: 0xFF},
}

var (
	couleurGrille = color.NRGBA{R: 0xE0, G: 0xE0, B: 0xE0, A: 0xFF}
	couleurAxe    = color.NRGBA{R: 0x60, G: 0x60, B: 0x60, A: 0xFF}
	couleurTexte  = color.NRGBA{R: 0x40, G: 0x40, B: 0x40, A: 0xFF}
)

type zoneTrace struct {
	xGauche float32
	xDroite float32
	yHaut   float32
	yBas    float32
}

type pointSeance struct {
	Index   int
	Score   int
	Evaluee bool
}

func construireOngletEvolution(resumees []sessions.SeanceResumee) fyne.CanvasObject {
	if len(resumees) == 0 {
		return container.NewCenter(widget.NewLabel("Aucune seance a afficher pour ce patient."))
	}
	return container.NewBorder(construireLegende(), nil, nil, nil, newGrapheEvolution(resumees))
}

func construireLegende() fyne.CanvasObject {
	elements := make([]fyne.CanvasObject, 0, len(sessions.EmotionsOrdonnees))
	for _, emotion := range sessions.EmotionsOrdonnees {
		pastille := canvas.NewRectangle(couleursEmotion[emotion])
		pastille.SetMinSize(fyne.NewSize(14, 14))
		elements = append(elements, container.NewHBox(pastille, widget.NewLabel(majusculeInitiale(emotion))))
	}
	return container.NewHBox(elements...)
}

func serieEmotion(resumees []sessions.SeanceResumee, emotion string) []pointSeance {
	points := make([]pointSeance, 0, len(resumees))
	for i, seance := range resumees {
		point := pointSeance{Index: i}
		for _, e := range seance.Resume.ParEmotion {
			if e.Emotion == emotion {
				point.Score = e.Score
				point.Evaluee = e.Evaluee
				break
			}
		}
		points = append(points, point)
	}
	return points
}

func projeterY(score float64, zone zoneTrace) float32 {
	ratio := float32(score / 100.0)
	return zone.yBas - ratio*(zone.yBas-zone.yHaut)
}

func projeterX(index, nbSeances int, zone zoneTrace) float32 {
	if nbSeances <= 1 {
		return zone.xGauche
	}
	ratio := float32(index) / float32(nbSeances-1)
	return zone.xGauche + ratio*(zone.xDroite-zone.xGauche)
}

type grapheEvolution struct {
	widget.BaseWidget
	resumees []sessions.SeanceResumee
}

func newGrapheEvolution(resumees []sessions.SeanceResumee) *grapheEvolution {
	g := &grapheEvolution{resumees: resumees}
	g.ExtendBaseWidget(g)
	return g
}

func (g *grapheEvolution) CreateRenderer() fyne.WidgetRenderer {
	renderer := &grapheRenderer{graphe: g}
	renderer.fond = canvas.NewRectangle(color.NRGBA{R: 0xFF, G: 0xFF, B: 0xFF, A: 0xFF})
	return renderer
}

type grapheRenderer struct {
	graphe *grapheEvolution
	fond   *canvas.Rectangle
	objets []fyne.CanvasObject
}

func (r *grapheRenderer) MinSize() fyne.Size { return fyne.NewSize(480, 320) }

func (r *grapheRenderer) Layout(taille fyne.Size) {
	r.fond.Resize(taille)
	r.fond.Move(fyne.NewPos(0, 0))

	zone := zoneTrace{
		xGauche: 40,
		xDroite: taille.Width - 12,
		yHaut:   12,
		yBas:    taille.Height - 28,
	}

	objets := []fyne.CanvasObject{r.fond}
	objets = append(objets, dessinerGrilleEtAxes(zone)...)
	objets = append(objets, dessinerEtiquettesX(r.graphe.resumees, zone)...)
	for _, emotion := range sessions.EmotionsOrdonnees {
		objets = append(objets, dessinerCourbe(serieEmotion(r.graphe.resumees, emotion), len(r.graphe.resumees), couleursEmotion[emotion], zone)...)
	}
	r.objets = objets
}

func (r *grapheRenderer) Refresh() {
	r.Layout(r.graphe.Size())
	canvas.Refresh(r.graphe)
}

func (r *grapheRenderer) Objects() []fyne.CanvasObject { return r.objets }

func (r *grapheRenderer) Destroy() {}

func dessinerGrilleEtAxes(zone zoneTrace) []fyne.CanvasObject {
	var objets []fyne.CanvasObject
	for _, valeur := range []int{0, 25, 50, 75, 100} {
		y := projeterY(float64(valeur), zone)
		ligne := canvas.NewLine(couleurGrille)
		ligne.StrokeWidth = 1
		ligne.Position1 = fyne.NewPos(zone.xGauche, y)
		ligne.Position2 = fyne.NewPos(zone.xDroite, y)
		objets = append(objets, ligne)

		etiquette := canvas.NewText(strconv.Itoa(valeur), couleurTexte)
		etiquette.TextSize = 11
		etiquette.Move(fyne.NewPos(8, y-7))
		objets = append(objets, etiquette)
	}

	axeY := canvas.NewLine(couleurAxe)
	axeY.StrokeWidth = 1.5
	axeY.Position1 = fyne.NewPos(zone.xGauche, zone.yHaut)
	axeY.Position2 = fyne.NewPos(zone.xGauche, zone.yBas)

	axeX := canvas.NewLine(couleurAxe)
	axeX.StrokeWidth = 1.5
	axeX.Position1 = fyne.NewPos(zone.xGauche, zone.yBas)
	axeX.Position2 = fyne.NewPos(zone.xDroite, zone.yBas)

	return append(objets, axeY, axeX)
}

func dessinerEtiquettesX(resumees []sessions.SeanceResumee, zone zoneTrace) []fyne.CanvasObject {
	objets := make([]fyne.CanvasObject, 0, len(resumees))
	for i, seance := range resumees {
		x := projeterX(i, len(resumees), zone)
		etiquette := canvas.NewText(formaterDateCourte(seance.Session.SessionDate), couleurTexte)
		etiquette.TextSize = 10
		etiquette.Alignment = fyne.TextAlignCenter
		etiquette.Move(fyne.NewPos(x-14, zone.yBas+6))
		objets = append(objets, etiquette)
	}
	return objets
}

func dessinerCourbe(serie []pointSeance, nbSeances int, couleur color.NRGBA, zone zoneTrace) []fyne.CanvasObject {
	var objets []fyne.CanvasObject
	for _, point := range serie {
		if !point.Evaluee {
			continue
		}
		x := projeterX(point.Index, nbSeances, zone)
		y := projeterY(float64(point.Score), zone)

		if point.Index+1 < len(serie) && serie[point.Index+1].Evaluee {
			suivant := serie[point.Index+1]
			xSuivant := projeterX(suivant.Index, nbSeances, zone)
			ySuivant := projeterY(float64(suivant.Score), zone)
			segment := canvas.NewLine(couleur)
			segment.StrokeWidth = 2
			segment.Position1 = fyne.NewPos(x, y)
			segment.Position2 = fyne.NewPos(xSuivant, ySuivant)
			objets = append(objets, segment)
		}

		marqueur := canvas.NewCircle(couleur)
		marqueur.Position1 = fyne.NewPos(x-3, y-3)
		marqueur.Position2 = fyne.NewPos(x+3, y+3)
		objets = append(objets, marqueur)
	}
	return objets
}

func formaterDateCourte(brut string) string {
	instant, err := time.Parse(time.RFC3339, brut)
	if err != nil {
		return brut
	}
	return instant.Local().Format("02/01")
}
