package sessions

import (
	"context"
	"fmt"
	"math"
	"sort"
)

var EmotionsOrdonnees = []string{"joie", "colere", "tristesse", "peur"}

type ScoreEmotionSeance struct {
	Emotion        string
	CiblesTotal    int
	CiblesTrouvees int
	FauxPositifs   int
	Score          int
	Evaluee        bool
}

type ResumeSeance struct {
	ScoreGlobal int
	ParEmotion  []ScoreEmotionSeance
}

type SeanceResumee struct {
	Session Session
	Resume  ResumeSeance
}

func AgregerResumeSeance(planches []PlancheJouee) ResumeSeance {
	parEmotion := make([]ScoreEmotionSeance, 0, len(EmotionsOrdonnees))
	for _, emotion := range EmotionsOrdonnees {
		var sommeScores, nbEvaluees int
		agregat := ScoreEmotionSeance{Emotion: emotion}
		for _, planche := range planches {
			for _, resultat := range planche.ResultatsParEmotion {
				if resultat.Emotion != emotion || !resultat.Evaluee {
					continue
				}
				agregat.Evaluee = true
				agregat.CiblesTotal += resultat.NbCiblesTotal
				agregat.CiblesTrouvees += resultat.NbCiblesTrouvees
				agregat.FauxPositifs += resultat.NbFauxPositifs
				sommeScores += resultat.Score
				nbEvaluees++
			}
		}
		if nbEvaluees > 0 {
			agregat.Score = arrondiMoyenne(sommeScores, nbEvaluees)
		}
		parEmotion = append(parEmotion, agregat)
	}

	scoreGlobal := 0
	if len(planches) > 0 {
		var sommeGlobales int
		for _, planche := range planches {
			sommeGlobales += planche.ScoreGlobal
		}
		scoreGlobal = arrondiMoyenne(sommeGlobales, len(planches))
	}

	return ResumeSeance{ScoreGlobal: scoreGlobal, ParEmotion: parEmotion}
}

func (d *DepotSessions) ResumeSeancesParPatient(ctx context.Context, patientID string) ([]SeanceResumee, error) {
	seances, err := d.ListerSessionsParPatient(ctx, patientID)
	if err != nil {
		return nil, err
	}
	sort.SliceStable(seances, func(i, j int) bool {
		if seances[i].SessionDate != seances[j].SessionDate {
			return seances[i].SessionDate < seances[j].SessionDate
		}
		return seances[i].ID < seances[j].ID
	})

	resumees := make([]SeanceResumee, 0, len(seances))
	for _, seance := range seances {
		planches, err := d.ListerPlanchesParSession(ctx, seance.ID)
		if err != nil {
			return nil, fmt.Errorf("sessions: resume seance %d: %w", seance.ID, err)
		}
		resumees = append(resumees, SeanceResumee{
			Session: seance,
			Resume:  AgregerResumeSeance(planches),
		})
	}
	return resumees, nil
}

func arrondiMoyenne(somme, nombre int) int {
	return int(math.Round(float64(somme) / float64(nombre)))
}
