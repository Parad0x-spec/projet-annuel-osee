package sessions

import (
	"context"
	"testing"
	"time"
)

func emotionDuResume(resume ResumeSeance, emotion string) ScoreEmotionSeance {
	for _, e := range resume.ParEmotion {
		if e.Emotion == emotion {
			return e
		}
	}
	return ScoreEmotionSeance{}
}

func TestAgregerResumeSeance_PlancheUniqueComplete(t *testing.T) {
	planches := []PlancheJouee{
		{
			NumeroPlanche: 1,
			ScoreGlobal:   82,
			ResultatsParEmotion: []ResultatEmotion{
				{Emotion: "joie", NbCiblesTotal: 3, NbCiblesTrouvees: 3, NbFauxPositifs: 0, Score: 100, Evaluee: true},
				{Emotion: "colere", NbCiblesTotal: 2, NbCiblesTrouvees: 1, NbFauxPositifs: 1, Score: 45, Evaluee: true},
				{Emotion: "tristesse", NbCiblesTotal: 1, NbCiblesTrouvees: 1, NbFauxPositifs: 0, Score: 100, Evaluee: true},
				{Emotion: "peur", NbCiblesTotal: 1, NbCiblesTrouvees: 1, NbFauxPositifs: 0, Score: 100, Evaluee: true},
			},
		},
	}

	resume := AgregerResumeSeance(planches)

	if resume.ScoreGlobal != 82 {
		t.Errorf("score global = %d, attendu 82", resume.ScoreGlobal)
	}
	if len(resume.ParEmotion) != 4 {
		t.Fatalf("nombre d'emotions = %d, attendu 4", len(resume.ParEmotion))
	}
	for i, attendu := range EmotionsOrdonnees {
		if resume.ParEmotion[i].Emotion != attendu {
			t.Errorf("ordre emotion %d = %q, attendu %q", i, resume.ParEmotion[i].Emotion, attendu)
		}
	}
	colere := emotionDuResume(resume, "colere")
	if !colere.Evaluee || colere.Score != 45 || colere.CiblesTrouvees != 1 || colere.CiblesTotal != 2 || colere.FauxPositifs != 1 {
		t.Errorf("colere = %+v", colere)
	}
}

func TestAgregerResumeSeance_MultiPlanchesEmotionEvalueeSurUneSeule(t *testing.T) {
	planches := []PlancheJouee{
		{
			NumeroPlanche: 1,
			ScoreGlobal:   80,
			ResultatsParEmotion: []ResultatEmotion{
				{Emotion: "joie", NbCiblesTotal: 2, NbCiblesTrouvees: 2, NbFauxPositifs: 0, Score: 80, Evaluee: true},
				{Emotion: "colere", NbCiblesTotal: 2, NbCiblesTrouvees: 1, NbFauxPositifs: 0, Score: 50, Evaluee: true},
			},
		},
		{
			NumeroPlanche: 2,
			ScoreGlobal:   60,
			ResultatsParEmotion: []ResultatEmotion{
				{Emotion: "joie", NbCiblesTotal: 5, NbCiblesTrouvees: 5, NbFauxPositifs: 9, Score: 0, Evaluee: false},
				{Emotion: "colere", NbCiblesTotal: 4, NbCiblesTrouvees: 3, NbFauxPositifs: 1, Score: 70, Evaluee: true},
			},
		},
	}

	resume := AgregerResumeSeance(planches)

	if resume.ScoreGlobal != 70 {
		t.Errorf("score global = %d, attendu 70 (moyenne de 80 et 60)", resume.ScoreGlobal)
	}

	joie := emotionDuResume(resume, "joie")
	if !joie.Evaluee {
		t.Fatal("joie devrait etre evaluee (planche 1 seulement)")
	}
	if joie.Score != 80 {
		t.Errorf("joie.Score = %d, attendu 80 (planche 1 seule, planche 2 non evaluee ignoree)", joie.Score)
	}
	if joie.CiblesTotal != 2 || joie.CiblesTrouvees != 2 || joie.FauxPositifs != 0 {
		t.Errorf("joie compteurs = %+v, attendu uniquement la planche evaluee", joie)
	}

	colere := emotionDuResume(resume, "colere")
	if !colere.Evaluee || colere.Score != 60 {
		t.Errorf("colere.Score = %d, attendu 60 (moyenne de 50 et 70)", colere.Score)
	}
	if colere.CiblesTotal != 6 || colere.CiblesTrouvees != 4 || colere.FauxPositifs != 1 {
		t.Errorf("colere compteurs = %+v, attendu sommes des deux planches", colere)
	}
}

func TestAgregerResumeSeance_EmotionJamaisEvalueePasDePoint(t *testing.T) {
	planches := []PlancheJouee{
		{
			NumeroPlanche: 1,
			ScoreGlobal:   90,
			ResultatsParEmotion: []ResultatEmotion{
				{Emotion: "joie", NbCiblesTotal: 2, NbCiblesTrouvees: 2, NbFauxPositifs: 0, Score: 90, Evaluee: true},
				{Emotion: "peur", NbCiblesTotal: 3, NbCiblesTrouvees: 0, NbFauxPositifs: 0, Score: 0, Evaluee: false},
			},
		},
	}

	resume := AgregerResumeSeance(planches)

	peur := emotionDuResume(resume, "peur")
	if peur.Evaluee {
		t.Error("peur ne devrait pas etre evaluee")
	}
	if peur.Score != 0 || peur.CiblesTotal != 0 || peur.CiblesTrouvees != 0 || peur.FauxPositifs != 0 {
		t.Errorf("peur = %+v, attendu agregat vide (non evaluee != score 0 trace)", peur)
	}
}

func TestAgregerResumeSeance_ArrondiMoyenne(t *testing.T) {
	planches := []PlancheJouee{
		{NumeroPlanche: 1, ScoreGlobal: 80, ResultatsParEmotion: []ResultatEmotion{
			{Emotion: "joie", NbCiblesTotal: 1, NbCiblesTrouvees: 1, Score: 80, Evaluee: true},
		}},
		{NumeroPlanche: 2, ScoreGlobal: 45, ResultatsParEmotion: []ResultatEmotion{
			{Emotion: "joie", NbCiblesTotal: 1, NbCiblesTrouvees: 1, Score: 45, Evaluee: true},
		}},
	}

	resume := AgregerResumeSeance(planches)

	joie := emotionDuResume(resume, "joie")
	if joie.Score != 63 {
		t.Errorf("joie.Score = %d, attendu 63 (arrondi de 62,5)", joie.Score)
	}
	if resume.ScoreGlobal != 63 {
		t.Errorf("score global = %d, attendu 63 (arrondi de 62,5)", resume.ScoreGlobal)
	}
}

func TestAgregerResumeSeance_SansPlanche(t *testing.T) {
	resume := AgregerResumeSeance(nil)
	if resume.ScoreGlobal != 0 {
		t.Errorf("score global = %d, attendu 0", resume.ScoreGlobal)
	}
	if len(resume.ParEmotion) != 4 {
		t.Fatalf("nombre d'emotions = %d, attendu 4", len(resume.ParEmotion))
	}
	for _, e := range resume.ParEmotion {
		if e.Evaluee {
			t.Errorf("emotion %q ne devrait pas etre evaluee sans planche", e.Emotion)
		}
	}
}

func TestResumeSeancesParPatient_OrdreChronologiqueEtAgregation(t *testing.T) {
	depot, patient := preparerBasePartagee(t)
	ctx := context.Background()

	planchesAncienne := []PlancheJouee{
		{NumeroPlanche: 1, ScoreGlobal: 40, ResultatsParEmotion: []ResultatEmotion{
			{Emotion: "joie", NbCiblesTotal: 2, NbCiblesTrouvees: 1, NbFauxPositifs: 0, Score: 40, Evaluee: true},
		}},
	}
	planchesRecente := []PlancheJouee{
		{NumeroPlanche: 1, ScoreGlobal: 90, ResultatsParEmotion: []ResultatEmotion{
			{Emotion: "joie", NbCiblesTotal: 2, NbCiblesTrouvees: 2, NbFauxPositifs: 0, Score: 90, Evaluee: true},
		}},
	}
	payload := []byte(`{"planches":[]}`)

	if _, err := depot.EnregistrerSession(ctx, patient.PatientID, time.Date(2026, 5, 25, 10, 0, 0, 0, time.UTC), "emotions", 2, planchesRecente, payload); err != nil {
		t.Fatalf("EnregistrerSession recente: %v", err)
	}
	if _, err := depot.EnregistrerSession(ctx, patient.PatientID, time.Date(2026, 5, 20, 10, 0, 0, 0, time.UTC), "emotions", 1, planchesAncienne, payload); err != nil {
		t.Fatalf("EnregistrerSession ancienne: %v", err)
	}

	resumees, err := depot.ResumeSeancesParPatient(ctx, patient.PatientID)
	if err != nil {
		t.Fatalf("ResumeSeancesParPatient: %v", err)
	}
	if len(resumees) != 2 {
		t.Fatalf("nombre de seances = %d, attendu 2", len(resumees))
	}
	if resumees[0].Session.SessionDate >= resumees[1].Session.SessionDate {
		t.Errorf("ordre non chronologique ascendant : %q puis %q", resumees[0].Session.SessionDate, resumees[1].Session.SessionDate)
	}
	if resumees[0].Resume.ScoreGlobal != 40 {
		t.Errorf("score global seance ancienne = %d, attendu 40", resumees[0].Resume.ScoreGlobal)
	}
	if resumees[1].Resume.ScoreGlobal != 90 {
		t.Errorf("score global seance recente = %d, attendu 90", resumees[1].Resume.ScoreGlobal)
	}
	joieRecente := emotionDuResume(resumees[1].Resume, "joie")
	if !joieRecente.Evaluee || joieRecente.Score != 90 {
		t.Errorf("joie seance recente = %+v, attendu evaluee score 90", joieRecente)
	}
}
