package main

import (
	"fmt"
	"os"
	"path/filepath"
)

const (
	sousDossierDonnees = ".projet_annuel"
	nomFichierPatients = "patients.db"
)

func cheminBasePatients() (string, error) {
	home, err := os.UserHomeDir()
	if err != nil {
		return "", fmt.Errorf("chemin: home dir: %w", err)
	}
	return cheminBasePatientsDansHome(home)
}

func cheminBasePatientsDansHome(home string) (string, error) {
	dossier := filepath.Join(home, sousDossierDonnees)
	if err := os.MkdirAll(dossier, 0o700); err != nil {
		return "", fmt.Errorf("chemin: creer dossier %q: %w", dossier, err)
	}
	return filepath.Join(dossier, nomFichierPatients), nil
}
