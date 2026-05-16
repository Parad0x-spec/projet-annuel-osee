package main

import (
	"fmt"
	"log"

	"fyne.io/fyne/v2"
	"fyne.io/fyne/v2/app"
	"fyne.io/fyne/v2/container"
	"fyne.io/fyne/v2/widget"

	"projet_annuel/logiciel_pc_go/internal/crypto"
)

const titreFenetrePrincipale = "Suivi patients"

func main() {
	clePrivee, clePublique, err := crypto.GenererPaireDeCles()
	if err != nil {
		log.Fatalf("generation cles PC: %v", err)
	}
	session := &sessionAppairage{
		clePriveePC:   clePrivee,
		clePubliquePC: clePublique,
	}

	logiciel := app.New()
	fenetre := logiciel.NewWindow(titreFenetrePrincipale)

	statut := widget.NewLabel("")

	boutonGenerer := widget.NewButton("Generer QR appairage", func() {
		if err := ouvrirFenetreQR(logiciel, session); err != nil {
			statut.SetText(fmt.Sprintf("Echec generation QR : %v", err))
		}
	})

	boutonScanner := widget.NewButton("Scanner QR tablette", func() {
		statut.SetText("Capture en cours...")
		go func() {
			message := scannerEtVerifier(session)
			fyne.Do(func() {
				statut.SetText(message)
			})
		}()
	})

	contenu := container.NewVBox(
		widget.NewLabel("Logiciel praticien"),
		boutonGenerer,
		boutonScanner,
		widget.NewSeparator(),
		statut,
	)
	fenetre.SetContent(contenu)
	fenetre.Resize(fyne.NewSize(520, 320))
	fenetre.ShowAndRun()
}
