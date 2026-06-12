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

func TestResoudreCheminBase_FlagVideEgaleComportementDefaut(t *testing.T) {
	attendu, err := cheminBasePatients()
	if err != nil {
		t.Fatalf("cheminBasePatients: %v", err)
	}
	obtenu, err := resoudreCheminBase("")
	if err != nil {
		t.Fatalf("resoudreCheminBase(\"\"): %v", err)
	}
	if obtenu != attendu {
		t.Errorf("flag vide = %q, attendu chemin par defaut %q", obtenu, attendu)
	}
}

func TestResoudreCheminBase_FlagRempliRetourneTelQuel(t *testing.T) {
	chemin := filepath.Join(t.TempDir(), "demo.db")
	obtenu, err := resoudreCheminBase(chemin)
	if err != nil {
		t.Fatalf("resoudreCheminBase: %v", err)
	}
	if obtenu != chemin {
		t.Errorf("flag rempli = %q, attendu %q", obtenu, chemin)
	}
}
