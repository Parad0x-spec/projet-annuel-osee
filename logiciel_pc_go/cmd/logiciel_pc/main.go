package main

import (
	"context"
	"fmt"
	"log"

	"fyne.io/fyne/v2"
	"fyne.io/fyne/v2/app"
	"fyne.io/fyne/v2/container"
	"fyne.io/fyne/v2/widget"

	"projet_annuel/logiciel_pc_go/internal/appairage_pc"
	"projet_annuel/logiciel_pc_go/internal/crypto"
	"projet_annuel/logiciel_pc_go/internal/patients"
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

	chemin, err := cheminBasePatients()
	if err != nil {
		log.Fatalf("chemin base patients: %v", err)
	}
	depot, err := patients.OuvrirDepot(chemin)
	if err != nil {
		log.Fatalf("ouvrir base patients: %v", err)
	}
	defer depot.Fermer()

	depotAppairage, err := appairage_pc.OuvrirDepot(chemin)
	if err != nil {
		log.Fatalf("ouvrir base appairage: %v", err)
	}
	defer depotAppairage.Fermer()

	if appairage, err := depotAppairage.LireAppairageActuel(context.Background()); err == nil {
		session.memoriserTabPub(appairage.TabPub)
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
			message := scannerEtVerifier(session, depotAppairage)
			fyne.Do(func() {
				statut.SetText(message)
			})
		}()
	})

	entete := widget.NewLabelWithStyle(
		titreFenetrePrincipale,
		fyne.TextAlignCenter,
		fyne.TextStyle{Bold: true},
	)

	panneauPatients := construirePanneauPatients(logiciel, fenetre, session, depot)

	piedDePage := container.NewVBox(
		widget.NewSeparator(),
		widget.NewLabelWithStyle("Appairage du dispositif", fyne.TextAlignLeading, fyne.TextStyle{Italic: true}),
		container.NewHBox(boutonGenerer, boutonScanner),
		statut,
	)

	contenu := container.NewBorder(entete, piedDePage, nil, nil, panneauPatients)
	fenetre.SetContent(contenu)
	fenetre.Resize(fyne.NewSize(800, 600))
	fenetre.ShowAndRun()
}
