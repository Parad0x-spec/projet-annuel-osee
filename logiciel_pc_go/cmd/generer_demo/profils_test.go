package main

import (
	"reflect"
	"testing"

	"projet_annuel/logiciel_pc_go/internal/sessions"
)

var tousLesProfils = []Profil{
	ProfilProgression,
	ProfilDifficultePeur,
	ProfilLenteIrreguliere,
	ProfilNonEvaluees,
}

func TestGenererPlanchesSeance_DonneesCoherentes(t *testing.T) {
	for _, profil := range tousLesProfils {
		for i := 0; i < nbSeancesDemo; i++ {
			planches := genererPlanchesSeance(profil, i)
			if len(planches) == 0 {
				t.Fatalf("profil %d seance %d : aucune planche", profil, i)
			}
			for _, planche := range planches {
				if planche.ScoreGlobal < 0 || planche.ScoreGlobal > 100 {
					t.Errorf("profil %d seance %d : score_global %d hors bornes", profil, i, planche.ScoreGlobal)
				}
				for _, r := range planche.ResultatsParEmotion {
					if r.NbCiblesTrouvees < 0 || r.NbCiblesTrouvees > r.NbCiblesTotal {
						t.Errorf("profil %d seance %d %s : trouvees %d / total %d incoherent", profil, i, r.Emotion, r.NbCiblesTrouvees, r.NbCiblesTotal)
					}
					if r.NbFauxPositifs < 0 {
						t.Errorf("profil %d seance %d %s : faux positifs negatifs", profil, i, r.Emotion)
					}
					if r.Score < 0 || r.Score > 100 {
						t.Errorf("profil %d seance %d %s : score %d hors bornes", profil, i, r.Emotion, r.Score)
					}
					if !r.Evaluee && r.Score != 0 {
						t.Errorf("profil %d seance %d %s : non evaluee mais score %d", profil, i, r.Emotion, r.Score)
					}
				}
			}
		}
	}
}

func TestGenererPlanchesSeance_Deterministe(t *testing.T) {
	for _, profil := range tousLesProfils {
		for i := 0; i < nbSeancesDemo; i++ {
			premier := genererPlanchesSeance(profil, i)
			second := genererPlanchesSeance(profil, i)
			if !reflect.DeepEqual(premier, second) {
				t.Errorf("profil %d seance %d : generation non deterministe", profil, i)
			}
		}
	}
}

func TestProfilProgression_ScoreMonteEntrePremiereEtDerniere(t *testing.T) {
	premiere := sessions.AgregerResumeSeance(genererPlanchesSeance(ProfilProgression, 0))
	derniere := sessions.AgregerResumeSeance(genererPlanchesSeance(ProfilProgression, nbSeancesDemo-1))
	if derniere.ScoreGlobal <= premiere.ScoreGlobal {
		t.Errorf("progression attendue : premiere %d, derniere %d", premiere.ScoreGlobal, derniere.ScoreGlobal)
	}
}

func TestProfilDifficultePeur_PeurResteSousLesAutres(t *testing.T) {
	resume := sessions.AgregerResumeSeance(genererPlanchesSeance(ProfilDifficultePeur, nbSeancesDemo-1))
	var peur, joie sessions.ScoreEmotionSeance
	for _, e := range resume.ParEmotion {
		switch e.Emotion {
		case "peur":
			peur = e
		case "joie":
			joie = e
		}
	}
	if !peur.Evaluee || !joie.Evaluee {
		t.Fatal("peur et joie doivent etre evaluees dans ce profil")
	}
	if peur.Score >= joie.Score {
		t.Errorf("peur %d devrait rester sous joie %d", peur.Score, joie.Score)
	}
}

func TestProfilNonEvaluees_ProduitDesTrous(t *testing.T) {
	trouTrouve := false
	for i := 0; i < nbSeancesDemo; i++ {
		resume := sessions.AgregerResumeSeance(genererPlanchesSeance(ProfilNonEvaluees, i))
		for _, e := range resume.ParEmotion {
			if !e.Evaluee {
				if e.Score != 0 {
					t.Errorf("seance %d %s : non evaluee mais score %d (piege evaluee=false != 0)", i, e.Emotion, e.Score)
				}
				trouTrouve = true
			}
		}
	}
	if !trouTrouve {
		t.Error("le profil non evaluees doit produire au moins une emotion non evaluee (trou dans la courbe)")
	}
}
