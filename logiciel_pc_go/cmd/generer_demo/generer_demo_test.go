package main

import (
	"context"
	"path/filepath"
	"testing"

	"projet_annuel/logiciel_pc_go/internal/patients"
	"projet_annuel/logiciel_pc_go/internal/sessions"
)

func TestGenererBaseDemo_RefuseSiExisteSansForce(t *testing.T) {
	chemin := filepath.Join(t.TempDir(), "demo.db")

	if err := genererBaseDemo(chemin, false); err != nil {
		t.Fatalf("premiere generation: %v", err)
	}
	if err := genererBaseDemo(chemin, false); err == nil {
		t.Error("seconde generation sans -force : refus attendu")
	}
	if err := genererBaseDemo(chemin, true); err != nil {
		t.Errorf("regeneration avec -force: %v", err)
	}
}

func TestGenererBaseDemo_ContenuReluCoherent(t *testing.T) {
	chemin := filepath.Join(t.TempDir(), "demo.db")
	if err := genererBaseDemo(chemin, false); err != nil {
		t.Fatalf("generation: %v", err)
	}

	depotPatients, err := patients.OuvrirDepot(chemin)
	if err != nil {
		t.Fatalf("ouvrir patients: %v", err)
	}
	defer depotPatients.Fermer()
	depotSessions, err := sessions.OuvrirDepot(chemin)
	if err != nil {
		t.Fatalf("ouvrir sessions: %v", err)
	}
	defer depotSessions.Fermer()

	ctx := context.Background()
	listePatients, err := depotPatients.ListerPatients(ctx)
	if err != nil {
		t.Fatalf("lister patients: %v", err)
	}
	if len(listePatients) != len(patientsDemo) {
		t.Fatalf("patients = %d, attendu %d", len(listePatients), len(patientsDemo))
	}

	var patientDelta patients.Patient
	for _, p := range listePatients {
		if p.PatientID == "" {
			t.Errorf("patient %s %s sans UUID", p.Nom, p.Prenom)
		}
		resumees, err := depotSessions.ResumeSeancesParPatient(ctx, p.PatientID)
		if err != nil {
			t.Fatalf("resume seances de %s: %v", p.Initiales, err)
		}
		if len(resumees) != nbSeancesDemo {
			t.Errorf("patient %s : %d seances, attendu %d", p.Initiales, len(resumees), nbSeancesDemo)
		}
		if p.Prenom == "Delta" {
			patientDelta = p
		}
	}

	if patientDelta.PatientID == "" {
		t.Fatal("patient Delta (profil non evaluees) introuvable")
	}
	resumeesDelta, err := depotSessions.ResumeSeancesParPatient(ctx, patientDelta.PatientID)
	if err != nil {
		t.Fatalf("resume Delta: %v", err)
	}
	trouTrouve := false
	for _, seance := range resumeesDelta {
		for _, e := range seance.Resume.ParEmotion {
			if !e.Evaluee {
				trouTrouve = true
			}
		}
	}
	if !trouTrouve {
		t.Error("le patient Delta doit avoir des emotions non evaluees (trous dans les courbes)")
	}
}
