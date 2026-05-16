package main

import (
	"os"
	"path/filepath"
	"testing"
)

func TestCheminBasePatientsDansHome_CreeDossierEtRetourneFichier(t *testing.T) {
	tmp := t.TempDir()

	chemin, err := cheminBasePatientsDansHome(tmp)
	if err != nil {
		t.Fatalf("cheminBasePatientsDansHome: %v", err)
	}

	attendu := filepath.Join(tmp, sousDossierDonnees, nomFichierPatients)
	if chemin != attendu {
		t.Errorf("chemin = %q, attendu %q", chemin, attendu)
	}

	info, err := os.Stat(filepath.Dir(chemin))
	if err != nil {
		t.Fatalf("dossier parent non cree: %v", err)
	}
	if !info.IsDir() {
		t.Errorf("%q n'est pas un dossier", filepath.Dir(chemin))
	}
}

func TestCheminBasePatientsDansHome_IdempotentSurDossierExistant(t *testing.T) {
	tmp := t.TempDir()

	if _, err := cheminBasePatientsDansHome(tmp); err != nil {
		t.Fatalf("premier appel: %v", err)
	}
	if _, err := cheminBasePatientsDansHome(tmp); err != nil {
		t.Fatalf("deuxieme appel doit etre idempotent: %v", err)
	}
}
