package export

import "projet_annuel/logiciel_pc_go/internal/sessions"

const seuilTendance = 10

type Tendance int

const (
	TendanceNonEvaluee Tendance = iota
	TendanceProgression
	TendanceStagnation
	TendanceRegression
)

func (t Tendance) Libelle() string {
	switch t {
	case TendanceProgression:
		return "Progression"
	case TendanceRegression:
		return "Regression"
	case TendanceStagnation:
		return "Stagnation"
	default:
		return "Non evaluee"
	}
}

func scoresEvalues(resumees []sessions.SeanceResumee, emotion string) []int {
	var scores []int
	for _, seance := range resumees {
		for _, e := range seance.Resume.ParEmotion {
			if e.Emotion == emotion && e.Evaluee {
				scores = append(scores, e.Score)
			}
		}
	}
	return scores
}

func tendanceDepuisScores(scores []int) Tendance {
	if len(scores) == 0 {
		return TendanceNonEvaluee
	}
	if len(scores) == 1 {
		return TendanceStagnation
	}
	delta := scores[len(scores)-1] - scores[0]
	if delta >= seuilTendance {
		return TendanceProgression
	}
	if delta <= -seuilTendance {
		return TendanceRegression
	}
	return TendanceStagnation
}

func resumeEmotion(resumees []sessions.SeanceResumee, emotion string) (tendance Tendance, dernierScore int, evaluee bool) {
	scores := scoresEvalues(resumees, emotion)
	if len(scores) == 0 {
		return TendanceNonEvaluee, 0, false
	}
	return tendanceDepuisScores(scores), scores[len(scores)-1], true
}
