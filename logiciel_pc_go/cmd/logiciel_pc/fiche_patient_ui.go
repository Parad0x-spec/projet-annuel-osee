package main

import (
	"context"
	"fmt"
	"time"

	"fyne.io/fyne/v2"
	"fyne.io/fyne/v2/container"
	"fyne.io/fyne/v2/widget"

	"projet_annuel/logiciel_pc_go/internal/patients"
	"projet_annuel/logiciel_pc_go/internal/sessions"
)

func ouvrirFichePatient(logiciel fyne.App, depotSessions *sessions.DepotSessions, fiche patients.Patient) error {
	resumees, err := depotSessions.ResumeSeancesParPatient(context.Background(), fiche.PatientID)
	if err != nil {
		return fmt.Errorf("Lecture des seances : %w", err)
	}

	fenetre := logiciel.NewWindow(fmt.Sprintf("Fiche patient - %s %s", fiche.Nom, fiche.Prenom))

	ongletDetail := container.NewTabItem("Detail seances", construireOngletDetailSeances(fiche, resumees))
	ongletEvolution := container.NewTabItem("Evolution", construireOngletEvolution(resumees))
	onglets := container.NewAppTabs(ongletDetail, ongletEvolution)

	fenetre.SetContent(onglets)
	fenetre.Resize(fyne.NewSize(820, 600))
	fenetre.Show()
	return nil
}

func construireOngletDetailSeances(fiche patients.Patient, resumees []sessions.SeanceResumee) fyne.CanvasObject {
	infosPatient := construireBlocInfosPatient(fiche)

	if len(resumees) == 0 {
		message := widget.NewLabel("Aucune seance recue pour ce patient.")
		return container.NewBorder(infosPatient, nil, nil, nil, message)
	}

	seancesAffichees := inverserSeances(resumees)

	detail := container.NewVBox(widget.NewLabel("Selectionnez une seance pour voir le detail par emotion."))
	detailDefilant := container.NewVScroll(detail)

	liste := widget.NewList(
		func() int { return len(seancesAffichees) },
		func() fyne.CanvasObject { return widget.NewLabel("") },
		func(id widget.ListItemID, item fyne.CanvasObject) {
			seance := seancesAffichees[id]
			item.(*widget.Label).SetText(fmt.Sprintf("%s  -  score %d/100",
				formaterDateSeance(seance.Session.SessionDate), seance.Resume.ScoreGlobal))
		},
	)
	liste.OnSelected = func(id widget.ListItemID) {
		if id < 0 || id >= len(seancesAffichees) {
			return
		}
		detail.Objects = objetsDetailSeance(seancesAffichees[id])
		detail.Refresh()
	}

	separation := container.NewHSplit(liste, detailDefilant)
	separation.SetOffset(0.4)

	return container.NewBorder(infosPatient, nil, nil, nil, separation)
}

func construireBlocInfosPatient(fiche patients.Patient) fyne.CanvasObject {
	dateNaissance := fiche.DateNaissance
	if dateNaissance == "" {
		dateNaissance = "non renseignee"
	}
	notes := fiche.Notes
	if notes == "" {
		notes = "aucune"
	}

	return container.NewVBox(
		widget.NewLabelWithStyle(
			fmt.Sprintf("%s %s (%s)", fiche.Nom, fiche.Prenom, fiche.Initiales),
			fyne.TextAlignLeading, fyne.TextStyle{Bold: true}),
		widget.NewLabel(fmt.Sprintf("Date de naissance : %s", dateNaissance)),
		widget.NewLabel(fmt.Sprintf("Notes : %s", notes)),
		widget.NewSeparator(),
	)
}

func objetsDetailSeance(seance sessions.SeanceResumee) []fyne.CanvasObject {
	objets := []fyne.CanvasObject{
		widget.NewLabelWithStyle(
			fmt.Sprintf("Seance du %s", formaterDateSeance(seance.Session.SessionDate)),
			fyne.TextAlignLeading, fyne.TextStyle{Bold: true}),
		widget.NewLabel(fmt.Sprintf("Niveau %d  -  score global %d/100", seance.Session.Niveau, seance.Resume.ScoreGlobal)),
		widget.NewSeparator(),
	}
	for _, emotion := range seance.Resume.ParEmotion {
		objets = append(objets, widget.NewLabel(formaterLigneEmotion(emotion)))
	}
	return objets
}

func formaterLigneEmotion(emotion sessions.ScoreEmotionSeance) string {
	titre := majusculeInitiale(emotion.Emotion)
	if !emotion.Evaluee {
		return fmt.Sprintf("%s : non evaluee", titre)
	}
	return fmt.Sprintf("%s : %d/%d trouvees, %d faux positifs, score %d/100",
		titre, emotion.CiblesTrouvees, emotion.CiblesTotal, emotion.FauxPositifs, emotion.Score)
}

func inverserSeances(resumees []sessions.SeanceResumee) []sessions.SeanceResumee {
	inverse := make([]sessions.SeanceResumee, len(resumees))
	for i, seance := range resumees {
		inverse[len(resumees)-1-i] = seance
	}
	return inverse
}

func formaterDateSeance(brut string) string {
	instant, err := time.Parse(time.RFC3339, brut)
	if err != nil {
		return brut
	}
	return instant.Local().Format("02/01/2006 15:04")
}

func majusculeInitiale(texte string) string {
	if texte == "" {
		return texte
	}
	runes := []rune(texte)
	if runes[0] >= 'a' && runes[0] <= 'z' {
		runes[0] -= 'a' - 'A'
	}
	return string(runes)
}
