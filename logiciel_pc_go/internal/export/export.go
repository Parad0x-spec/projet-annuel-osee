package export

import (
	"fmt"
	"os"
	"path/filepath"
	"time"

	"github.com/xuri/excelize/v2"

	"projet_annuel/logiciel_pc_go/internal/patients"
	"projet_annuel/logiciel_pc_go/internal/sessions"
)

const (
	feuilleSynthese  = "Synthese"
	feuilleDetail    = "Detail par seance"
	feuilleEvolution = "Evolution"

	seuilAmbre = 41
	seuilVert  = 76

	fondRouge  = "F8CECC"
	fondAmbre  = "FFE699"
	fondVert   = "C6EFCE"
	fondEntete = "D9D9D9"
)

var couleurEmotion = map[string]string{
	"joie":      "F5A623",
	"colere":    "D32F2F",
	"tristesse": "1976D2",
	"peur":      "7B1FA2",
}

var libelleEmotion = map[string]string{
	"joie":      "Joie",
	"colere":    "Colere",
	"tristesse": "Tristesse",
	"peur":      "Peur",
}

func CheminExportPatient(dossierBase string, patient patients.Patient) string {
	return filepath.Join(dossierBase, fmt.Sprintf("suivi_%s_%s.xlsx", patient.Initiales, patient.PatientID))
}

func GenererClasseurPatient(patient patients.Patient, resumees []sessions.SeanceResumee, chemin string) error {
	f := excelize.NewFile()
	defer f.Close()

	if _, err := f.NewSheet(feuilleDetail); err != nil {
		return fmt.Errorf("export: creer feuille detail: %w", err)
	}
	if _, err := f.NewSheet(feuilleEvolution); err != nil {
		return fmt.Errorf("export: creer feuille evolution: %w", err)
	}
	if err := f.SetSheetName("Sheet1", feuilleSynthese); err != nil {
		return fmt.Errorf("export: renommer feuille synthese: %w", err)
	}

	if err := construireSynthese(f, patient, resumees); err != nil {
		return err
	}
	if err := construireDetail(f, resumees); err != nil {
		return err
	}
	if err := construireEvolution(f, resumees); err != nil {
		return err
	}

	if err := os.MkdirAll(filepath.Dir(chemin), 0o700); err != nil {
		return fmt.Errorf("export: creer dossier %q: %w", filepath.Dir(chemin), err)
	}
	if err := f.SaveAs(chemin); err != nil {
		return fmt.Errorf("export: ecrire %q: %w", chemin, err)
	}
	return nil
}

func couleurFondScore(score int) string {
	switch {
	case score >= seuilVert:
		return fondVert
	case score >= seuilAmbre:
		return fondAmbre
	default:
		return fondRouge
	}
}

func cellule(colonne, ligne int) string {
	nom, _ := excelize.CoordinatesToCellName(colonne, ligne)
	return nom
}

func styleFond(f *excelize.File, hex string, gras bool, couleurTexte string) (int, error) {
	style := &excelize.Style{
		Fill:      excelize.Fill{Type: "pattern", Pattern: 1, Color: []string{hex}},
		Alignment: &excelize.Alignment{Horizontal: "center", Vertical: "center"},
	}
	if gras || couleurTexte != "" {
		style.Font = &excelize.Font{Bold: gras, Color: couleurTexte}
	}
	return f.NewStyle(style)
}

func construireSynthese(f *excelize.File, patient patients.Patient, resumees []sessions.SeanceResumee) error {
	feuille := feuilleSynthese
	f.SetColWidth(feuille, "A", "F", 16)

	if err := f.SetCellValue(feuille, "A1", fmt.Sprintf("Suivi - %s %s (%s)", patient.Nom, patient.Prenom, patient.Initiales)); err != nil {
		return err
	}
	f.SetCellValue(feuille, "A2", fmt.Sprintf("Nombre de seances : %d", len(resumees)))

	styleEntete, err := styleFond(f, fondEntete, true, "")
	if err != nil {
		return err
	}

	ligneCartes := 4
	f.SetCellValue(feuille, cellule(1, ligneCartes), "Emotion")
	f.SetCellValue(feuille, cellule(2, ligneCartes), "Dernier score")
	f.SetCellValue(feuille, cellule(3, ligneCartes), "Tendance")
	f.SetCellStyle(feuille, cellule(1, ligneCartes), cellule(3, ligneCartes), styleEntete)

	for i, emotion := range sessions.EmotionsOrdonnees {
		ligne := ligneCartes + 1 + i
		styleEmotion, err := styleFond(f, couleurEmotion[emotion], true, "FFFFFF")
		if err != nil {
			return err
		}
		f.SetCellValue(feuille, cellule(1, ligne), libelleEmotion[emotion])
		f.SetCellStyle(feuille, cellule(1, ligne), cellule(1, ligne), styleEmotion)

		tendance, dernier, evaluee := resumeEmotion(resumees, emotion)
		if evaluee {
			f.SetCellValue(feuille, cellule(2, ligne), dernier)
		} else {
			f.SetCellValue(feuille, cellule(2, ligne), "n/e")
		}
		f.SetCellValue(feuille, cellule(3, ligne), tendance.Libelle())
	}

	ligneTableau := ligneCartes + len(sessions.EmotionsOrdonnees) + 3
	f.SetCellValue(feuille, cellule(1, ligneTableau), "Seance")
	for j, emotion := range sessions.EmotionsOrdonnees {
		f.SetCellValue(feuille, cellule(2+j, ligneTableau), libelleEmotion[emotion])
	}
	f.SetCellValue(feuille, cellule(2+len(sessions.EmotionsOrdonnees), ligneTableau), "Score global")
	f.SetCellStyle(feuille, cellule(1, ligneTableau), cellule(2+len(sessions.EmotionsOrdonnees), ligneTableau), styleEntete)

	for r, seance := range resumees {
		ligne := ligneTableau + 1 + r
		f.SetCellValue(feuille, cellule(1, ligne), formaterDateCourte(seance.Session.SessionDate))
		for j, emotion := range sessions.EmotionsOrdonnees {
			colonne := 2 + j
			score := emotionDansResume(seance.Resume, emotion)
			if !score.Evaluee {
				f.SetCellValue(feuille, cellule(colonne, ligne), "n/e")
				continue
			}
			if err := f.SetCellValue(feuille, cellule(colonne, ligne), score.Score); err != nil {
				return err
			}
			styleScore, err := styleFond(f, couleurFondScore(score.Score), false, "")
			if err != nil {
				return err
			}
			f.SetCellStyle(feuille, cellule(colonne, ligne), cellule(colonne, ligne), styleScore)
		}
		colGlobal := 2 + len(sessions.EmotionsOrdonnees)
		f.SetCellValue(feuille, cellule(colGlobal, ligne), seance.Resume.ScoreGlobal)
		styleGlobal, err := styleFond(f, couleurFondScore(seance.Resume.ScoreGlobal), true, "")
		if err != nil {
			return err
		}
		f.SetCellStyle(feuille, cellule(colGlobal, ligne), cellule(colGlobal, ligne), styleGlobal)
	}
	return nil
}

func construireDetail(f *excelize.File, resumees []sessions.SeanceResumee) error {
	feuille := feuilleDetail
	f.SetColWidth(feuille, "A", "F", 16)

	entetes := []string{"Emotion", "Trouvees", "Total", "Faux positifs", "Completude", "Score", "Statut"}
	styleEntete, err := styleFond(f, fondEntete, true, "")
	if err != nil {
		return err
	}

	ligne := 1
	for _, seance := range resumees {
		f.SetCellValue(feuille, cellule(1, ligne), fmt.Sprintf("Seance du %s  -  niveau %d  -  score global %d/100",
			formaterDateCourte(seance.Session.SessionDate), seance.Session.Niveau, seance.Resume.ScoreGlobal))
		ligne++

		for c, entete := range entetes {
			f.SetCellValue(feuille, cellule(1+c, ligne), entete)
		}
		f.SetCellStyle(feuille, cellule(1, ligne), cellule(len(entetes), ligne), styleEntete)
		ligne++

		for _, emotion := range sessions.EmotionsOrdonnees {
			score := emotionDansResume(seance.Resume, emotion)
			f.SetCellValue(feuille, cellule(1, ligne), libelleEmotion[emotion])
			if score.Evaluee {
				f.SetCellValue(feuille, cellule(2, ligne), score.CiblesTrouvees)
				f.SetCellValue(feuille, cellule(3, ligne), score.CiblesTotal)
				f.SetCellValue(feuille, cellule(4, ligne), score.FauxPositifs)
				f.SetCellValue(feuille, cellule(5, ligne), formaterCompletude(score))
				f.SetCellValue(feuille, cellule(6, ligne), score.Score)
				f.SetCellValue(feuille, cellule(7, ligne), "evaluee")
			} else {
				f.SetCellValue(feuille, cellule(7, ligne), "non evaluee (n/e)")
			}
			ligne++
		}
		ligne++
	}
	return nil
}

func construireEvolution(f *excelize.File, resumees []sessions.SeanceResumee) error {
	feuille := feuilleEvolution
	f.SetColWidth(feuille, "A", "A", 14)
	f.SetColWidth(feuille, "B", "E", 12)

	f.SetCellValue(feuille, "A1", "Seance")
	for j, emotion := range sessions.EmotionsOrdonnees {
		f.SetCellValue(feuille, cellule(2+j, 1), libelleEmotion[emotion])
	}

	for r, seance := range resumees {
		ligne := 2 + r
		f.SetCellValue(feuille, cellule(1, ligne), formaterDateCourte(seance.Session.SessionDate))
		for j, emotion := range sessions.EmotionsOrdonnees {
			score := emotionDansResume(seance.Resume, emotion)
			if score.Evaluee {
				f.SetCellValue(feuille, cellule(2+j, ligne), score.Score)
			}
		}
	}

	if len(resumees) == 0 {
		return nil
	}

	derniereLigne := 1 + len(resumees)
	series := make([]excelize.ChartSeries, 0, len(sessions.EmotionsOrdonnees))
	for j, emotion := range sessions.EmotionsOrdonnees {
		colonne := 2 + j
		series = append(series, excelize.ChartSeries{
			Name:       fmt.Sprintf("%s!%s", feuille, cellule(colonne, 1)),
			Categories: fmt.Sprintf("%s!$A$2:$A$%d", feuille, derniereLigne),
			Values:     fmt.Sprintf("%s!%s:%s", feuille, cellule(colonne, 2), cellule(colonne, derniereLigne)),
			Fill:       excelize.Fill{Type: "pattern", Pattern: 1, Color: []string{couleurEmotion[emotion]}},
			Line:       excelize.ChartLine{Width: 2},
		})
	}

	minY, maxY := 0.0, 100.0
	chart := &excelize.Chart{
		Type:         excelize.Line,
		Series:       series,
		ShowBlanksAs: "gap",
		Title:        []excelize.RichTextRun{{Text: "Evolution par emotion"}},
		Legend:       excelize.ChartLegend{Position: "bottom"},
		YAxis:        excelize.ChartAxis{Minimum: &minY, Maximum: &maxY},
		Dimension:    excelize.ChartDimension{Width: 640, Height: 360},
	}
	return f.AddChart(feuille, cellule(2+len(sessions.EmotionsOrdonnees)+2, 1), chart)
}

func emotionDansResume(resume sessions.ResumeSeance, emotion string) sessions.ScoreEmotionSeance {
	for _, e := range resume.ParEmotion {
		if e.Emotion == emotion {
			return e
		}
	}
	return sessions.ScoreEmotionSeance{Emotion: emotion}
}

func formaterCompletude(score sessions.ScoreEmotionSeance) string {
	if score.CiblesTotal == 0 {
		return "n/a"
	}
	return fmt.Sprintf("%d%%", int(float64(score.CiblesTrouvees)/float64(score.CiblesTotal)*100.0+0.5))
}

func formaterDateCourte(brut string) string {
	instant, err := time.Parse(time.RFC3339, brut)
	if err != nil {
		return brut
	}
	return instant.Local().Format("02/01/2006")
}
