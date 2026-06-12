package export

import (
	"archive/zip"
	"path/filepath"
	"strings"
	"testing"

	"github.com/xuri/excelize/v2"

	"projet_annuel/logiciel_pc_go/internal/patients"
	"projet_annuel/logiciel_pc_go/internal/sessions"
)

func TestCouleurFondScore_Seuils(t *testing.T) {
	cas := []struct {
		score   int
		attendu string
	}{
		{0, fondRouge},
		{40, fondRouge},
		{41, fondAmbre},
		{75, fondAmbre},
		{76, fondVert},
		{100, fondVert},
	}
	for _, c := range cas {
		if got := couleurFondScore(c.score); got != c.attendu {
			t.Errorf("score %d : fond %q, attendu %q", c.score, got, c.attendu)
		}
	}
}

func TestCheminExportPatient(t *testing.T) {
	patient := patients.Patient{Initiales: "DA", PatientID: "abc-123"}
	got := CheminExportPatient("/tmp/exports", patient)
	attendu := filepath.Join("/tmp/exports", "suivi_DA_abc-123.xlsx")
	if got != attendu {
		t.Errorf("chemin = %q, attendu %q", got, attendu)
	}
}

func resumeesTest() []sessions.SeanceResumee {
	return []sessions.SeanceResumee{
		{
			Session: sessions.Session{SessionDate: "2026-04-06T10:00:00Z", Niveau: 1},
			Resume: sessions.ResumeSeance{
				ScoreGlobal: 50,
				ParEmotion: []sessions.ScoreEmotionSeance{
					{Emotion: "joie", CiblesTotal: 3, CiblesTrouvees: 2, FauxPositifs: 0, Score: 67, Evaluee: true},
					{Emotion: "colere", CiblesTotal: 2, CiblesTrouvees: 1, FauxPositifs: 1, Score: 33, Evaluee: true},
					{Emotion: "tristesse", Evaluee: false},
					{Emotion: "peur", Evaluee: false},
				},
			},
		},
		{
			Session: sessions.Session{SessionDate: "2026-04-13T10:00:00Z", Niveau: 2},
			Resume: sessions.ResumeSeance{
				ScoreGlobal: 88,
				ParEmotion: []sessions.ScoreEmotionSeance{
					{Emotion: "joie", CiblesTotal: 3, CiblesTrouvees: 3, FauxPositifs: 0, Score: 90, Evaluee: true},
					{Emotion: "colere", CiblesTotal: 2, CiblesTrouvees: 2, FauxPositifs: 0, Score: 85, Evaluee: true},
					{Emotion: "tristesse", CiblesTotal: 2, CiblesTrouvees: 2, FauxPositifs: 0, Score: 88, Evaluee: true},
					{Emotion: "peur", Evaluee: false},
				},
			},
		},
	}
}

func TestGenererClasseurPatient_StructureEtPiegeNonEvaluee(t *testing.T) {
	chemin := filepath.Join(t.TempDir(), "suivi.xlsx")
	patient := patients.Patient{Nom: "Demo", Prenom: "Delta", Initiales: "DD", PatientID: "uuid-delta"}

	if err := GenererClasseurPatient(patient, resumeesTest(), chemin); err != nil {
		t.Fatalf("GenererClasseurPatient: %v", err)
	}

	f, err := excelize.OpenFile(chemin)
	if err != nil {
		t.Fatalf("OpenFile: %v", err)
	}
	defer f.Close()

	feuilles := f.GetSheetList()
	for _, attendue := range []string{feuilleSynthese, feuilleDetail, feuilleEvolution} {
		if !contient(feuilles, attendue) {
			t.Errorf("feuille %q absente, feuilles = %v", attendue, feuilles)
		}
	}

	// Feuille Evolution : la colonne tristesse (D) est vide en seance 1 (non evaluee)
	// et porte 88 en seance 2 (evaluee). Le trou ne doit jamais valoir 0.
	tristesseSeance1, _ := f.GetCellValue(feuilleEvolution, "D2")
	if tristesseSeance1 != "" {
		t.Errorf("tristesse non evaluee en seance 1 doit etre une cellule VIDE, obtenu %q (jamais 0)", tristesseSeance1)
	}
	tristesseSeance2, _ := f.GetCellValue(feuilleEvolution, "D3")
	if tristesseSeance2 != "88" {
		t.Errorf("tristesse evaluee en seance 2 = %q, attendu 88", tristesseSeance2)
	}
	joieSeance1, _ := f.GetCellValue(feuilleEvolution, "B2")
	if joieSeance1 != "67" {
		t.Errorf("joie seance 1 = %q, attendu 67", joieSeance1)
	}

	// Un graphique natif est embarque dans le classeur (entree xl/charts/ du zip).
	if !classeurContientGraphique(t, chemin) {
		t.Error("aucun graphique natif embarque dans le classeur")
	}
}

func classeurContientGraphique(t *testing.T, chemin string) bool {
	t.Helper()
	lecteur, err := zip.OpenReader(chemin)
	if err != nil {
		t.Fatalf("ouverture zip xlsx: %v", err)
	}
	defer lecteur.Close()
	for _, fichier := range lecteur.File {
		if strings.HasPrefix(fichier.Name, "xl/charts/") {
			return true
		}
	}
	return false
}

func TestGenererClasseurPatient_SansSeance(t *testing.T) {
	chemin := filepath.Join(t.TempDir(), "vide.xlsx")
	patient := patients.Patient{Nom: "Demo", Prenom: "Alpha", Initiales: "DA", PatientID: "uuid-alpha"}
	if err := GenererClasseurPatient(patient, nil, chemin); err != nil {
		t.Fatalf("GenererClasseurPatient sans seance: %v", err)
	}
	f, err := excelize.OpenFile(chemin)
	if err != nil {
		t.Fatalf("OpenFile: %v", err)
	}
	defer f.Close()
	if !contient(f.GetSheetList(), feuilleSynthese) {
		t.Error("feuille Synthese absente")
	}
}

func contient(liste []string, valeur string) bool {
	for _, v := range liste {
		if v == valeur {
			return true
		}
	}
	return false
}
