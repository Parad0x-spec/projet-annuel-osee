package main

import (
	"fyne.io/fyne/v2"
	"fyne.io/fyne/v2/container"
	"fyne.io/fyne/v2/widget"

	"projet_annuel/logiciel_pc_go/internal/sessions"
)

func construireOngletEvolution(resumees []sessions.SeanceResumee) fyne.CanvasObject {
	return container.NewCenter(widget.NewLabel("Le graphique d'evolution par emotion sera disponible ici."))
}
