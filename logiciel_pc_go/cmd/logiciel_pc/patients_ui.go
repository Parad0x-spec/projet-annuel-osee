package main

import (
	"bytes"
	"context"
	"errors"
	"fmt"
	"image/color"
	"image/png"

	"fyne.io/fyne/v2"
	"fyne.io/fyne/v2/canvas"
	"fyne.io/fyne/v2/container"
	"fyne.io/fyne/v2/dialog"
	"fyne.io/fyne/v2/layout"
	"fyne.io/fyne/v2/widget"

	"projet_annuel/logiciel_pc_go/internal/patients"
	"projet_annuel/logiciel_pc_go/internal/qr"
	"projet_annuel/logiciel_pc_go/internal/sessions"
)

const tailleQRSeance = float32(500)

var optionsNiveau = []string{
	"1 - Tres facile",
	"2 - Facile",
	"3 - Moyen",
	"4 - Difficile",
	"5 - Tres difficile",
}

var mappingNiveau = map[string]int{
	"1 - Tres facile":    1,
	"2 - Facile":         2,
	"3 - Moyen":          3,
	"4 - Difficile":      4,
	"5 - Tres difficile": 5,
}

func construirePanneauPatients(logiciel fyne.App, fenetre fyne.Window, session *sessionAppairage, depot *patients.DepotPatients, depotSessions *sessions.DepotSessions) fyne.CanvasObject {
	var fichesAffichees []patients.Patient
	rechercheActuelle := ""

	liste := widget.NewList(
		func() int { return len(fichesAffichees) },
		func() fyne.CanvasObject {
			return container.NewHBox(
				widget.NewLabel(""),
				layout.NewSpacer(),
				widget.NewButton("Demarrer une seance", nil),
			)
		},
		func(id widget.ListItemID, item fyne.CanvasObject) {
			hbox := item.(*fyne.Container)
			label := hbox.Objects[0].(*widget.Label)
			bouton := hbox.Objects[2].(*widget.Button)
			fiche := fichesAffichees[id]
			label.SetText(fmt.Sprintf("%s %s (%s)", fiche.Nom, fiche.Prenom, fiche.Initiales))
			bouton.OnTapped = func() {
				ouvrirFormulaireNiveau(fenetre, fiche, func(niveau int) {
					demarrerSeance(logiciel, fenetre, session, fiche, niveau)
				})
			}
		},
	)
	liste.OnSelected = func(id widget.ListItemID) {
		if id < 0 || id >= len(fichesAffichees) {
			return
		}
		fiche := fichesAffichees[id]
		liste.UnselectAll()
		if err := ouvrirFichePatient(logiciel, depotSessions, fiche); err != nil {
			dialog.ShowError(err, fenetre)
		}
	}

	rafraichir := func() {
		ctx := context.Background()
		var resultats []patients.Patient
		var err error
		if rechercheActuelle == "" {
			resultats, err = depot.ListerPatients(ctx)
		} else {
			resultats, err = depot.RechercherPatients(ctx, rechercheActuelle)
		}
		if err != nil {
			dialog.ShowError(err, fenetre)
			return
		}
		fichesAffichees = resultats
		liste.Refresh()
	}

	recherche := widget.NewEntry()
	recherche.SetPlaceHolder("Rechercher par nom ou prenom")
	recherche.OnChanged = func(saisie string) {
		rechercheActuelle = saisie
		rafraichir()
	}

	boutonNouveau := widget.NewButton("Nouveau patient", func() {
		ouvrirFormulaireNouveauPatient(fenetre, depot, rafraichir)
	})

	barreHaute := container.NewBorder(nil, nil, nil, boutonNouveau, recherche)

	rafraichir()

	return container.NewBorder(barreHaute, nil, nil, nil, liste)
}

func ouvrirFormulaireNouveauPatient(fenetre fyne.Window, depot *patients.DepotPatients, apresCreation func()) {
	champNom := widget.NewEntry()
	champPrenom := widget.NewEntry()
	champDateNaissance := widget.NewEntry()
	champDateNaissance.SetPlaceHolder("AAAA-MM-JJ (optionnel)")
	champNotes := widget.NewMultiLineEntry()
	champNotes.SetPlaceHolder("Notes praticien (optionnel)")

	items := []*widget.FormItem{
		{Text: "Nom", Widget: champNom},
		{Text: "Prenom", Widget: champPrenom},
		{Text: "Date de naissance", Widget: champDateNaissance},
		{Text: "Notes", Widget: champNotes},
	}

	dialog.ShowForm("Nouveau patient", "Creer", "Annuler", items, func(valide bool) {
		if !valide {
			return
		}
		ctx := context.Background()
		_, err := depot.CreerPatient(ctx, champNom.Text, champPrenom.Text, champDateNaissance.Text, champNotes.Text)
		if err != nil {
			switch {
			case errors.Is(err, patients.ErrPatientDejaExistant):
				dialog.ShowError(errors.New("Un patient avec ces nom et prenom existe deja"), fenetre)
			case errors.Is(err, patients.ErrPatientInvalide):
				dialog.ShowError(errors.New("Nom et prenom sont obligatoires"), fenetre)
			default:
				dialog.ShowError(err, fenetre)
			}
			return
		}
		apresCreation()
	}, fenetre)
}

func ouvrirFormulaireNiveau(fenetre fyne.Window, fiche patients.Patient, apresValidation func(niveau int)) {
	radio := widget.NewRadioGroup(optionsNiveau, nil)
	radio.SetSelected("3 - Moyen")

	contenu := container.NewVBox(
		widget.NewLabel(fmt.Sprintf("Patient : %s %s (%s)", fiche.Nom, fiche.Prenom, fiche.Initiales)),
		widget.NewLabel("Choisissez le niveau de difficulte :"),
		radio,
	)

	dialog.ShowCustomConfirm("Demarrer une seance", "Valider", "Annuler", contenu, func(valide bool) {
		if !valide {
			return
		}
		niveau := mappingNiveau[radio.Selected]
		if niveau == 0 {
			dialog.ShowError(errors.New("Choisissez un niveau de difficulte"), fenetre)
			return
		}
		apresValidation(niveau)
	}, fenetre)
}

func demarrerSeance(logiciel fyne.App, fenetre fyne.Window, session *sessionAppairage, fiche patients.Patient, niveau int) {
	_, pngQR, err := qr.GenererQRCreationPatient(session.clePriveePC, fiche.PatientID, fiche.Initiales, niveau)
	if err != nil {
		dialog.ShowError(fmt.Errorf("Generation QR seance : %w", err), fenetre)
		return
	}
	if err := ouvrirFenetreSeance(logiciel, fiche, niveau, pngQR); err != nil {
		dialog.ShowError(err, fenetre)
	}
}

func ouvrirFenetreSeance(logiciel fyne.App, fiche patients.Patient, niveau int, pngQR []byte) error {
	imageQR, err := png.Decode(bytes.NewReader(pngQR))
	if err != nil {
		return fmt.Errorf("decodage png seance : %w", err)
	}

	canvasQR := canvas.NewImageFromImage(imageQR)
	canvasQR.FillMode = canvas.ImageFillContain
	canvasQR.SetMinSize(fyne.NewSize(tailleQRSeance, tailleQRSeance))

	titre := fmt.Sprintf("Seance pour %s - Niveau %d", fiche.Initiales, niveau)
	fenetreQR := logiciel.NewWindow(titre)

	entete := canvas.NewText(titre, color.NRGBA{R: 0x1e, G: 0x4d, B: 0xaa, A: 0xff})
	entete.TextStyle.Bold = true
	entete.TextSize = 20
	entete.Alignment = fyne.TextAlignCenter

	boutonFermer := widget.NewButton("Fermer", func() {
		fenetreQR.Close()
	})

	fenetreQR.SetContent(container.NewVBox(
		entete,
		canvasQR,
		widget.NewLabel("Scannez ce QR depuis la tablette pour demarrer la seance"),
		boutonFermer,
	))
	fenetreQR.Resize(fyne.NewSize(tailleQRSeance+40, tailleQRSeance+160))
	fenetreQR.Show()
	return nil
}
