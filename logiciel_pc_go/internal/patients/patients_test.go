package patients

import (
	"context"
	"errors"
	"path/filepath"
	"strings"
	"testing"

	"github.com/google/uuid"
)

func ouvrirDepotDeTest(t *testing.T) *DepotPatients {
	t.Helper()
	chemin := filepath.Join(t.TempDir(), "patients.db")
	depot, err := OuvrirDepot(chemin)
	if err != nil {
		t.Fatalf("OuvrirDepot: %v", err)
	}
	t.Cleanup(func() { _ = depot.Fermer() })
	return depot
}

func TestCreerPatient_Nominal(t *testing.T) {
	depot := ouvrirDepotDeTest(t)
	ctx := context.Background()

	patient, err := depot.CreerPatient(ctx, "Dupont", "Marie", "1980-05-12", "premiere seance")
	if err != nil {
		t.Fatalf("CreerPatient: %v", err)
	}
	identifiant, err := uuid.Parse(patient.PatientID)
	if err != nil {
		t.Fatalf("patient_id non parsable: %v", err)
	}
	if identifiant.Version() != 4 {
		t.Errorf("version UUID = %d, attendu 4", identifiant.Version())
	}
	if patient.Initiales != "MD" {
		t.Errorf("initiales = %q, attendu %q", patient.Initiales, "MD")
	}
	if patient.DateCreation == "" {
		t.Error("date_creation vide")
	}
	if patient.Nom != "Dupont" || patient.Prenom != "Marie" {
		t.Errorf("nom/prenom = %q/%q, attendu Dupont/Marie", patient.Nom, patient.Prenom)
	}
	if patient.DateNaissance != "1980-05-12" {
		t.Errorf("date_naissance = %q", patient.DateNaissance)
	}

	relu, err := depot.LirePatientParID(ctx, patient.PatientID)
	if err != nil {
		t.Fatalf("LirePatientParID: %v", err)
	}
	if relu.PatientID != patient.PatientID {
		t.Errorf("relecture: patient_id = %q, attendu %q", relu.PatientID, patient.PatientID)
	}
	if relu.Notes != "premiere seance" {
		t.Errorf("notes = %q", relu.Notes)
	}
	if relu.Initiales != patient.Initiales {
		t.Errorf("relecture initiales = %q, attendu %q", relu.Initiales, patient.Initiales)
	}
}

func TestCalculerInitiales_Cas(t *testing.T) {
	cas := []struct {
		prenom, nom, attendu string
	}{
		{"Marie", "Dupont", "MD"},
		{"Jean-Paul", "Martin", "JPM"},
		{"Marie-Claire", "Bernard", "MCB"},
	}
	for _, c := range cas {
		obtenu := calculerInitiales(c.prenom, c.nom)
		if obtenu != c.attendu {
			t.Errorf("calculerInitiales(%q, %q) = %q, attendu %q",
				c.prenom, c.nom, obtenu, c.attendu)
		}
	}
}

func TestCalculerInitiales_TruncatureA3(t *testing.T) {
	obtenu := calculerInitiales("Jean-Paul-Pierre", "Martin")
	if len([]rune(obtenu)) > 3 {
		t.Errorf("initiales = %q, devrait faire au plus 3 caracteres", obtenu)
	}
	if obtenu != "JPP" {
		t.Errorf("initiales = %q, attendu %q", obtenu, "JPP")
	}
}

func TestCreerPatient_RejetDoublonStrict(t *testing.T) {
	depot := ouvrirDepotDeTest(t)
	ctx := context.Background()

	_, err := depot.CreerPatient(ctx, "Dupont", "Marie", "", "")
	if err != nil {
		t.Fatalf("premiere creation: %v", err)
	}
	_, err = depot.CreerPatient(ctx, "Dupont", "Marie", "", "")
	if !errors.Is(err, ErrPatientDejaExistant) {
		t.Errorf("erreur = %v, attendu ErrPatientDejaExistant", err)
	}
}

func TestCreerPatient_NomVideRejete(t *testing.T) {
	depot := ouvrirDepotDeTest(t)
	ctx := context.Background()

	_, err := depot.CreerPatient(ctx, "   ", "Marie", "", "")
	if !errors.Is(err, ErrPatientInvalide) {
		t.Errorf("erreur nom vide = %v, attendu ErrPatientInvalide", err)
	}
	_, err = depot.CreerPatient(ctx, "Dupont", "", "", "")
	if !errors.Is(err, ErrPatientInvalide) {
		t.Errorf("erreur prenom vide = %v, attendu ErrPatientInvalide", err)
	}
}

func TestRechercherPatients_SousChaineInsensible(t *testing.T) {
	depot := ouvrirDepotDeTest(t)
	ctx := context.Background()

	if _, err := depot.CreerPatient(ctx, "Martin", "Pierre", "", ""); err != nil {
		t.Fatalf("creation Martin Pierre: %v", err)
	}
	if _, err := depot.CreerPatient(ctx, "Bernard", "Marie", "", ""); err != nil {
		t.Fatalf("creation Bernard Marie: %v", err)
	}
	if _, err := depot.CreerPatient(ctx, "Lefebvre", "Sophie", "", ""); err != nil {
		t.Fatalf("creation Lefebvre Sophie: %v", err)
	}

	resultats, err := depot.RechercherPatients(ctx, "mar")
	if err != nil {
		t.Fatalf("RechercherPatients: %v", err)
	}
	if len(resultats) != 2 {
		t.Fatalf("nb resultats = %d, attendu 2", len(resultats))
	}
	for _, p := range resultats {
		nomBas := strings.ToLower(p.Nom)
		prenomBas := strings.ToLower(p.Prenom)
		if !strings.Contains(nomBas, "mar") && !strings.Contains(prenomBas, "mar") {
			t.Errorf("patient %q %q ne devrait pas etre dans les resultats de 'mar'", p.Nom, p.Prenom)
		}
	}
}

func TestListerPatients_TriAlphabetique(t *testing.T) {
	depot := ouvrirDepotDeTest(t)
	ctx := context.Background()

	if _, err := depot.CreerPatient(ctx, "Zola", "Emile", "", ""); err != nil {
		t.Fatalf("creation Zola: %v", err)
	}
	if _, err := depot.CreerPatient(ctx, "Albert", "Camus", "", ""); err != nil {
		t.Fatalf("creation Albert: %v", err)
	}
	if _, err := depot.CreerPatient(ctx, "Martin", "Pierre", "", ""); err != nil {
		t.Fatalf("creation Martin: %v", err)
	}

	patients, err := depot.ListerPatients(ctx)
	if err != nil {
		t.Fatalf("ListerPatients: %v", err)
	}
	if len(patients) != 3 {
		t.Fatalf("nb patients = %d, attendu 3", len(patients))
	}
	attendus := []string{"Albert", "Martin", "Zola"}
	for i, p := range patients {
		if p.Nom != attendus[i] {
			t.Errorf("position %d: nom = %q, attendu %q", i, p.Nom, attendus[i])
		}
	}
}

func TestLirePatientParID_InconnuRetourneErrPatientIntrouvable(t *testing.T) {
	depot := ouvrirDepotDeTest(t)
	ctx := context.Background()

	_, err := depot.LirePatientParID(ctx, "00000000-0000-0000-0000-000000000000")
	if !errors.Is(err, ErrPatientIntrouvable) {
		t.Errorf("erreur = %v, attendu ErrPatientIntrouvable", err)
	}
}

func TestSupprimerPatient_ExistantPuisIntrouvable(t *testing.T) {
	depot := ouvrirDepotDeTest(t)
	ctx := context.Background()

	patient, err := depot.CreerPatient(ctx, "Dupont", "Marie", "", "")
	if err != nil {
		t.Fatalf("creation: %v", err)
	}
	if err := depot.SupprimerPatient(ctx, patient.PatientID); err != nil {
		t.Fatalf("suppression: %v", err)
	}
	_, err = depot.LirePatientParID(ctx, patient.PatientID)
	if !errors.Is(err, ErrPatientIntrouvable) {
		t.Errorf("relecture apres suppression: erreur = %v, attendu ErrPatientIntrouvable", err)
	}
}

func TestSupprimerPatient_InconnuRetourneErrPatientIntrouvable(t *testing.T) {
	depot := ouvrirDepotDeTest(t)
	ctx := context.Background()

	err := depot.SupprimerPatient(ctx, "id-inexistant-pour-test")
	if !errors.Is(err, ErrPatientIntrouvable) {
		t.Errorf("erreur = %v, attendu ErrPatientIntrouvable", err)
	}
}
