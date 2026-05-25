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

	payload := []byte(`{"patient_id":"` + patient.PatientID + `","manches":[]}`)
	sessionDate := time.Date(2026, 5, 25, 10, 0, 0, 0, time.UTC)

	enregistree, err := depot.EnregistrerSession(ctx, patient.PatientID, sessionDate, "emotions", 3, payload)
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

	_, err := depot.EnregistrerSession(ctx, "id-inexistant", time.Now().UTC(), "emotions", 2, []byte(`{}`))
	if !errors.Is(err, ErrPatientInconnu) {
		t.Errorf("erreur = %v, attendu ErrPatientInconnu", err)
	}
}

func TestEnregistrerSession_ChampsInvalides(t *testing.T) {
	depot, patient := preparerBasePartagee(t)
	ctx := context.Background()

	if _, err := depot.EnregistrerSession(ctx, "", time.Now().UTC(), "emotions", 1, []byte(`{}`)); !errors.Is(err, ErrSessionInvalide) {
		t.Errorf("patient_id vide: erreur = %v, attendu ErrSessionInvalide", err)
	}
	if _, err := depot.EnregistrerSession(ctx, patient.PatientID, time.Now().UTC(), "", 1, []byte(`{}`)); !errors.Is(err, ErrSessionInvalide) {
		t.Errorf("jeu_type vide: erreur = %v, attendu ErrSessionInvalide", err)
	}
	if _, err := depot.EnregistrerSession(ctx, patient.PatientID, time.Now().UTC(), "emotions", 1, nil); !errors.Is(err, ErrSessionInvalide) {
		t.Errorf("payload vide: erreur = %v, attendu ErrSessionInvalide", err)
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
