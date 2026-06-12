package main

import (
	"testing"

	"projet_annuel/logiciel_pc_go/internal/sessions"
)

var zoneTest = zoneTrace{xGauche: 40, xDroite: 440, yHaut: 20, yBas: 220}

func TestProjeterY_BornesEtMilieu(t *testing.T) {
	if got := projeterY(0, zoneTest); got != zoneTest.yBas {
		t.Errorf("score 0 -> %v, attendu yBas %v", got, zoneTest.yBas)
	}
	if got := projeterY(100, zoneTest); got != zoneTest.yHaut {
		t.Errorf("score 100 -> %v, attendu yHaut %v", got, zoneTest.yHaut)
	}
	milieu := (zoneTest.yHaut + zoneTest.yBas) / 2
	if got := projeterY(50, zoneTest); got != milieu {
		t.Errorf("score 50 -> %v, attendu milieu %v", got, milieu)
	}
}

func TestProjeterX_BornesMonotonieEtSeanceUnique(t *testing.T) {
	if got := projeterX(0, 8, zoneTest); got != zoneTest.xGauche {
		t.Errorf("index 0 -> %v, attendu xGauche %v", got, zoneTest.xGauche)
	}
	if got := projeterX(7, 8, zoneTest); got != zoneTest.xDroite {
		t.Errorf("derniere seance -> %v, attendu xDroite %v", got, zoneTest.xDroite)
	}
	if projeterX(3, 8, zoneTest) <= projeterX(2, 8, zoneTest) {
		t.Error("projection X non monotone croissante")
	}
	if got := projeterX(0, 1, zoneTest); got != zoneTest.xGauche {
		t.Errorf("seance unique -> %v, attendu xGauche %v", got, zoneTest.xGauche)
	}
}

func resumeAvecEmotion(emotion string, score int, evaluee bool) sessions.SeanceResumee {
	return sessions.SeanceResumee{
		Resume: sessions.ResumeSeance{
			ParEmotion: []sessions.ScoreEmotionSeance{
				{Emotion: emotion, Score: score, Evaluee: evaluee},
			},
		},
	}
}

func TestSerieEmotion_TrouPreservePasDeChuteAZero(t *testing.T) {
	resumees := []sessions.SeanceResumee{
		resumeAvecEmotion("peur", 80, true),
		resumeAvecEmotion("peur", 0, false),
		resumeAvecEmotion("peur", 70, true),
	}

	serie := serieEmotion(resumees, "peur")
	if len(serie) != 3 {
		t.Fatalf("serie = %d points, attendu 3", len(serie))
	}
	if !serie[0].Evaluee || serie[0].Score != 80 {
		t.Errorf("point 0 = %+v", serie[0])
	}
	if serie[1].Evaluee {
		t.Errorf("point 1 devrait etre un trou (non evalue), pas un point trace : %+v", serie[1])
	}
	if !serie[2].Evaluee || serie[2].Score != 70 {
		t.Errorf("point 2 = %+v", serie[2])
	}
}

func TestSerieEmotion_EmotionAbsenteNonEvaluee(t *testing.T) {
	resumees := []sessions.SeanceResumee{resumeAvecEmotion("joie", 90, true)}
	serie := serieEmotion(resumees, "peur")
	if len(serie) != 1 || serie[0].Evaluee {
		t.Errorf("emotion absente du resume doit donner un point non evalue : %+v", serie)
	}
}
