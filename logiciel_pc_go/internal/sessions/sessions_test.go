package sessions

import (
	"context"
	"errors"
	"path/filepath"
	"testing"
	"time"

	"projet_annuel/logiciel_pc_go/internal/patients"
)

func preparerBasePartagee(t *testing.T) (*DepotSessions, patients.Patient) {
	t.Helper()
	chemin := filepath.Join(t.TempDir(), "patients.db")

	depotPatients, err := patients.OuvrirDepot(chemin)
	if err != nil {
		t.Fatalf("OuvrirDepot patients: %v", err)
	}
	t.Cleanup(func() { _ = depotPatients.Fermer() })

	patient, err := depotPatients.CreerPatient(context.Background(), "Dupont", "Marie", "", "")
	if err != nil {
		t.Fatalf("CreerPatient: %v", err)
	}

	depotSessions, err := OuvrirDepot(chemin)
	if err != nil {
		t.Fatalf("OuvrirDepot sessions: %v", err)
	}
	t.Cleanup(func() { _ = depotSessions.Fermer() })

	return depotSessions, patient
}

func TestEnregistrerSession_Nominal(t *testing.T) {
	depot, patient := preparerBasePartagee(t)
	ctx := context.Background()

	payload := []byte(`{"patient_id":"` + patient.PatientID + `","planches":[]}`)
	sessionDate := time.Date(2026, 5, 25, 10, 0, 0, 0, time.UTC)

	enregistree, err := depot.EnregistrerSession(ctx, patient.PatientID, sessionDate, "emotions", 3, nil, payload)
	if err != nil {
		t.Fatalf("EnregistrerSession: %v", err)
	}
	if enregistree.ID == 0 {
		t.Error("id non attribue")
	}
	if enregistree.Niveau != 3 || enregistree.JeuType != "emotions" {
		t.Errorf("session = %+v", enregistree)
	}
	if enregistree.DateReception == "" {
		t.Error("date_reception vide")
	}

	liste, err := depot.ListerSessionsParPatient(ctx, patient.PatientID)
	if err != nil {
		t.Fatalf("ListerSessionsParPatient: %v", err)
	}
	if len(liste) != 1 {
		t.Fatalf("nombre de sessions = %d, attendu 1", len(liste))
	}
	if liste[0].PayloadComplet != string(payload) {
		t.Errorf("payload_complet = %q", liste[0].PayloadComplet)
	}
}

func TestEnregistrerSession_PatientInconnu(t *testing.T) {
	depot, _ := preparerBasePartagee(t)
	ctx := context.Background()

	_, err := depot.EnregistrerSession(ctx, "id-inexistant", time.Now().UTC(), "emotions", 2, nil, []byte(`{}`))
	if !errors.Is(err, ErrPatientInconnu) {
		t.Errorf("erreur = %v, attendu ErrPatientInconnu", err)
	}
}

func TestEnregistrerSession_ChampsInvalides(t *testing.T) {
	depot, patient := preparerBasePartagee(t)
	ctx := context.Background()

	if _, err := depot.EnregistrerSession(ctx, "", time.Now().UTC(), "emotions", 1, nil, []byte(`{}`)); !errors.Is(err, ErrSessionInvalide) {
		t.Errorf("patient_id vide: erreur = %v, attendu ErrSessionInvalide", err)
	}
	if _, err := depot.EnregistrerSession(ctx, patient.PatientID, time.Now().UTC(), "", 1, nil, []byte(`{}`)); !errors.Is(err, ErrSessionInvalide) {
		t.Errorf("jeu_type vide: erreur = %v, attendu ErrSessionInvalide", err)
	}
	if _, err := depot.EnregistrerSession(ctx, patient.PatientID, time.Now().UTC(), "emotions", 1, nil, nil); !errors.Is(err, ErrSessionInvalide) {
		t.Errorf("payload vide: erreur = %v, attendu ErrSessionInvalide", err)
	}
}

func TestEnregistrerSession_StructureParPlancheEtEmotion(t *testing.T) {
	depot, patient := preparerBasePartagee(t)
	ctx := context.Background()

	planches := []PlancheJouee{
		{
			NumeroPlanche: 1,
			ScoreGlobal:   82,
			ResultatsParEmotion: []ResultatEmotion{
				{Emotion: "joie", NbCiblesTotal: 3, NbCiblesTrouvees: 3, NbFauxPositifs: 0, Score: 100, Evaluee: true},
				{Emotion: "tristesse", NbCiblesTotal: 0, NbCiblesTrouvees: 0, NbFauxPositifs: 0, Score: 0, Evaluee: false},
			},
		},
		{
			NumeroPlanche: 2,
			ScoreGlobal:   60,
			ResultatsParEmotion: []ResultatEmotion{
				{Emotion: "colere", NbCiblesTotal: 2, NbCiblesTrouvees: 1, NbFauxPositifs: 1, Score: 45, Evaluee: true},
			},
		},
	}
	payload := []byte(`{"patient_id":"` + patient.PatientID + `","planches":[]}`)

	enregistree, err := depot.EnregistrerSession(ctx, patient.PatientID, time.Date(2026, 5, 25, 10, 0, 0, 0, time.UTC), "emotions", 3, planches, payload)
	if err != nil {
		t.Fatalf("EnregistrerSession: %v", err)
	}

	relues, err := depot.ListerPlanchesParSession(ctx, enregistree.ID)
	if err != nil {
		t.Fatalf("ListerPlanchesParSession: %v", err)
	}
	if len(relues) != 2 {
		t.Fatalf("planches relues = %d, attendu 2", len(relues))
	}
	if relues[0].NumeroPlanche != 1 || relues[0].ScoreGlobal != 82 {
		t.Errorf("planche 0 = %+v", relues[0])
	}
	if len(relues[0].ResultatsParEmotion) != 2 {
		t.Fatalf("resultats planche 0 = %d, attendu 2", len(relues[0].ResultatsParEmotion))
	}
	joie := relues[0].ResultatsParEmotion[0]
	if joie.Emotion != "joie" || joie.NbCiblesTrouvees != 3 || joie.Score != 100 || !joie.Evaluee {
		t.Errorf("resultat joie = %+v", joie)
	}
	tristesse := relues[0].ResultatsParEmotion[1]
	if tristesse.Emotion != "tristesse" || tristesse.Evaluee {
		t.Errorf("resultat tristesse = %+v, attendu evaluee=false", tristesse)
	}
	if relues[1].NumeroPlanche != 2 || len(relues[1].ResultatsParEmotion) != 1 {
		t.Errorf("planche 1 = %+v", relues[1])
	}
}

func TestListerSessionsParPatient_Vide(t *testing.T) {
	depot, patient := preparerBasePartagee(t)
	liste, err := depot.ListerSessionsParPatient(context.Background(), patient.PatientID)
	if err != nil {
		t.Fatalf("ListerSessionsParPatient: %v", err)
	}
	if len(liste) != 0 {
		t.Errorf("nombre de sessions = %d, attendu 0", len(liste))
	}
}
