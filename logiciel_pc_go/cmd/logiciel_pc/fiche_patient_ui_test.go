package main

import (
	"strings"
	"testing"

	"projet_annuel/logiciel_pc_go/internal/sessions"
)

func TestFormaterLigneEmotion_Evaluee(t *testing.T) {
	ligne := formaterLigneEmotion(sessions.ScoreEmotionSeance{
		Emotion: "colere", CiblesTotal: 3, CiblesTrouvees: 2, FauxPositifs: 1, Score: 55, Evaluee: true,
	})
	for _, attendu := range []string{"Colere", "2/3", "1 faux positifs", "score 55/100"} {
		if !strings.Contains(ligne, attendu) {
			t.Errorf("ligne %q ne contient pas %q", ligne, attendu)
		}
	}
}

func TestFormaterLigneEmotion_NonEvalueePasDeScoreZero(t *testing.T) {
	ligne := formaterLigneEmotion(sessions.ScoreEmotionSeance{
		Emotion: "peur", Evaluee: false,
	})
	if !strings.Contains(ligne, "non evaluee") {
		t.Errorf("ligne %q devrait indiquer non evaluee", ligne)
	}
	if strings.Contains(ligne, "score") || strings.Contains(ligne, "0/0") {
		t.Errorf("ligne %q ne doit pas afficher un score pour une emotion non evaluee", ligne)
	}
}

func TestInverserSeances_OrdreInverse(t *testing.T) {
	resumees := []sessions.SeanceResumee{
		{Session: sessions.Session{ID: 1, SessionDate: "2026-05-20T10:00:00Z"}},
		{Session: sessions.Session{ID: 2, SessionDate: "2026-05-25T10:00:00Z"}},
	}
	inverse := inverserSeances(resumees)
	if inverse[0].Session.ID != 2 || inverse[1].Session.ID != 1 {
		t.Errorf("ordre inverse incorrect : %d puis %d", inverse[0].Session.ID, inverse[1].Session.ID)
	}
	if resumees[0].Session.ID != 1 {
		t.Error("la source ne doit pas etre modifiee")
	}
}

func TestFormaterDateSeance_Iso(t *testing.T) {
	if got := formaterDateSeance("pas-une-date"); got != "pas-une-date" {
		t.Errorf("date illisible = %q, attendu le brut inchange", got)
	}
}
