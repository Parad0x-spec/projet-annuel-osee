package main

import (
	"context"
	"errors"
	"fmt"

	"fyne.io/fyne/v2"
	"fyne.io/fyne/v2/container"
	"fyne.io/fyne/v2/dialog"
	"fyne.io/fyne/v2/layout"
	"fyne.io/fyne/v2/widget"

	"projet_annuel/logiciel_pc_go/internal/patients"
)

func construirePanneauPatients(fenetre fyne.Window, depot *patients.DepotPatients) fyne.CanvasObject {
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
				dialog.ShowInformation(
					"Demarrage de seance",
					fmt.Sprintf("Demarrage de seance pour %s - sera implemente a la tache 4", fiche.Initiales),
					fenetre,
				)
			}
		},
	)

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
