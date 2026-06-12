package export

import (
	"testing"

	"projet_annuel/logiciel_pc_go/internal/sessions"
)

func TestTendanceDepuisScores(t *testing.T) {
	cas := []struct {
		nom     string
		scores  []int
		attendu Tendance
	}{
		{"vide", nil, TendanceNonEvaluee},
		{"un seul point", []int{50}, TendanceStagnation},
		{"progression nette", []int{40, 60, 85}, TendanceProgression},
		{"regression nette", []int{80, 50, 40}, TendanceRegression},
		{"stagnation faible variation", []int{50, 55, 53}, TendanceStagnation},
		{"juste au seuil progression", []int{40, 50}, TendanceProgression},
		{"sous le seuil", []int{40, 49}, TendanceStagnation},
	}
	for _, c := range cas {
		if got := tendanceDepuisScores(c.scores); got != c.attendu {
			t.Errorf("%s : tendance = %v, attendu %v", c.nom, got, c.attendu)
		}
	}
}

func TestResumeEmotion_NonEvalueeNeRenvoiePasDeTendance(t *testing.T) {
	resumees := []sessions.SeanceResumee{
		{Resume: sessions.ResumeSeance{ParEmotion: []sessions.ScoreEmotionSeance{
			{Emotion: "peur", Evaluee: false},
		}}},
	}
	tendance, dernier, evaluee := resumeEmotion(resumees, "peur")
	if evaluee {
		t.Error("peur ne doit pas etre marquee evaluee")
	}
	if tendance != TendanceNonEvaluee || dernier != 0 {
		t.Errorf("attendu non evaluee/0, obtenu %v/%d", tendance, dernier)
	}
}
