package main

import (
	"math"
	"time"

	"projet_annuel/logiciel_pc_go/internal/sessions"
)

type Profil int

const (
	ProfilProgression Profil = iota
	ProfilDifficultePeur
	ProfilLenteIrreguliere
	ProfilNonEvaluees
)

const nbSeancesDemo = 8

var ancreDemo = time.Date(2026, 4, 6, 10, 0, 0, 0, time.UTC)

type PatientDemo struct {
	Nom           string
	Prenom        string
	DateNaissance string
	Notes         string
	Profil        Profil
}

var patientsDemo = []PatientDemo{
	{"Demo", "Alpha", "2015-03-12", "Profil demo : progression reussie sur les quatre emotions", ProfilProgression},
	{"Demo", "Beta", "2014-09-05", "Profil demo : difficulte ciblee sur la peur", ProfilDifficultePeur},
	{"Demo", "Gamma", "2016-01-20", "Profil demo : progression lente et irreguliere", ProfilLenteIrreguliere},
	{"Demo", "Delta", "2015-11-30", "Profil demo : emotions parfois non evaluees, trous dans les courbes", ProfilNonEvaluees},
}

func dateSeance(indexSeance int) time.Time {
	return ancreDemo.AddDate(0, 0, 7*indexSeance)
}

func niveauSeance(indexSeance int) int {
	return clamp(1+indexSeance/3, 1, 5)
}

func genererPlanchesSeance(profil Profil, indexSeance int) []sessions.PlancheJouee {
	nbPlanches := 1
	if indexSeance%2 == 1 {
		nbPlanches = 2
	}

	planches := make([]sessions.PlancheJouee, 0, nbPlanches)
	for p := 0; p < nbPlanches; p++ {
		resultats := make([]sessions.ResultatEmotion, 0, len(sessions.EmotionsOrdonnees))
		var sommeScores, nbEvaluees int
		for j, emotion := range sessions.EmotionsOrdonnees {
			evaluee, scoreBase := scoreCibleEmotion(profil, indexSeance, j)
			score := 0
			if evaluee {
				score = clamp(scoreBase+variation(indexSeance*100+p*10+j), 0, 100)
			}
			fpBonus := 0
			if profil == ProfilDifficultePeur && j == 3 {
				fpBonus = 1
			}
			resultat := construireResultat(emotion, j, evaluee, score, fpBonus)
			if resultat.Evaluee {
				sommeScores += resultat.Score
				nbEvaluees++
			}
			resultats = append(resultats, resultat)
		}
		scoreGlobal := 0
		if nbEvaluees > 0 {
			scoreGlobal = arrondiDiv(sommeScores, nbEvaluees)
		}
		planches = append(planches, sessions.PlancheJouee{
			NumeroPlanche:       p + 1,
			ScoreGlobal:         scoreGlobal,
			ResultatsParEmotion: resultats,
		})
	}
	return planches
}

func scoreCibleEmotion(profil Profil, indexSeance, emotionIndex int) (bool, int) {
	base := 40 + 7*indexSeance
	switch profil {
	case ProfilProgression:
		return true, base
	case ProfilDifficultePeur:
		if emotionIndex == 3 {
			return true, 20 + 3*indexSeance
		}
		return true, base
	case ProfilLenteIrreguliere:
		score := 35 + 4*indexSeance
		if indexSeance == 4 {
			score -= 15
		}
		return true, score
	case ProfilNonEvaluees:
		evaluees := emotionsEvalueesProfil4(indexSeance)
		if !evaluees[emotionIndex] {
			return false, 0
		}
		return true, base
	}
	return true, base
}

func emotionsEvalueesProfil4(indexSeance int) [4]bool {
	switch indexSeance % 4 {
	case 0:
		return [4]bool{true, true, true, true}
	case 1:
		return [4]bool{true, true, false, false}
	case 2:
		return [4]bool{true, true, true, false}
	default:
		return [4]bool{true, false, true, false}
	}
}

func construireResultat(emotion string, emotionIndex int, evaluee bool, score, fpBonus int) sessions.ResultatEmotion {
	total := 3 + emotionIndex%2
	if !evaluee {
		return sessions.ResultatEmotion{
			Emotion:          emotion,
			NbCiblesTotal:    total,
			NbCiblesTrouvees: 0,
			NbFauxPositifs:   0,
			Score:            0,
			Evaluee:          false,
		}
	}
	s := clamp(score, 0, 100)
	trouvees := clamp(arrondiDiv(total*s, 100), 0, total)
	fauxPositifs := arrondiDiv(100-s, 40) + fpBonus
	if fauxPositifs < 0 {
		fauxPositifs = 0
	}
	return sessions.ResultatEmotion{
		Emotion:          emotion,
		NbCiblesTotal:    total,
		NbCiblesTrouvees: trouvees,
		NbFauxPositifs:   fauxPositifs,
		Score:            s,
		Evaluee:          true,
	}
}

func variation(graine int) int {
	return (graine*37)%11 - 5
}

func clamp(valeur, mini, maxi int) int {
	if valeur < mini {
		return mini
	}
	if valeur > maxi {
		return maxi
	}
	return valeur
}

func arrondiDiv(numerateur, denominateur int) int {
	return int(math.Round(float64(numerateur) / float64(denominateur)))
}
