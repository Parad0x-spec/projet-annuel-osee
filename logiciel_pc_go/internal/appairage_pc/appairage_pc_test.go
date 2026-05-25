package appairage_pc

import (
	"bytes"
	"context"
	"errors"
	"path/filepath"
	"testing"
)

func ouvrirDepotDeTest(t *testing.T) *DepotAppairage {
	t.Helper()
	chemin := filepath.Join(t.TempDir(), "patients.db")
	depot, err := OuvrirDepot(chemin)
	if err != nil {
		t.Fatalf("OuvrirDepot: %v", err)
	}
	t.Cleanup(func() { _ = depot.Fermer() })
	return depot
}

func TestEnregistrerEtLireAppairage_Nominal(t *testing.T) {
	depot := ouvrirDepotDeTest(t)
	ctx := context.Background()
	tabPub := bytes.Repeat([]byte{0x42}, 32)

	enregistre, err := depot.EnregistrerAppairage(ctx, "paire-001", tabPub)
	if err != nil {
		t.Fatalf("EnregistrerAppairage: %v", err)
	}
	if enregistre.PairingID != "paire-001" {
		t.Errorf("pairing_id = %q", enregistre.PairingID)
	}
	if !bytes.Equal(enregistre.TabPub, tabPub) {
		t.Errorf("tab_pub retourne != tab_pub fourni")
	}
	if enregistre.DateAppairage == "" {
		t.Error("date_appairage vide")
	}

	relu, err := depot.LireAppairageActuel(ctx)
	if err != nil {
		t.Fatalf("LireAppairageActuel: %v", err)
	}
	if relu.PairingID != "paire-001" {
		t.Errorf("pairing_id relu = %q", relu.PairingID)
	}
	if !bytes.Equal(relu.TabPub, tabPub) {
		t.Errorf("tab_pub relu != tab_pub fourni")
	}
	if relu.DateDernierUsage != "" {
		t.Errorf("date_dernier_usage attendue vide a la creation, obtenu %q", relu.DateDernierUsage)
	}
}

func TestLireAppairageActuel_BaseVide(t *testing.T) {
	depot := ouvrirDepotDeTest(t)
	if _, err := depot.LireAppairageActuel(context.Background()); !errors.Is(err, ErrAucunAppairage) {
		t.Errorf("erreur = %v, attendu ErrAucunAppairage", err)
	}
}

func TestEnregistrerAppairage_RemplaceLAncien(t *testing.T) {
	depot := ouvrirDepotDeTest(t)
	ctx := context.Background()

	if _, err := depot.EnregistrerAppairage(ctx, "paire-001", []byte("cle-ancienne-aaaa")); err != nil {
		t.Fatalf("premier enregistrement: %v", err)
	}
	nouvelle := bytes.Repeat([]byte{0x07}, 32)
	if _, err := depot.EnregistrerAppairage(ctx, "paire-002", nouvelle); err != nil {
		t.Fatalf("second enregistrement: %v", err)
	}

	relu, err := depot.LireAppairageActuel(ctx)
	if err != nil {
		t.Fatalf("LireAppairageActuel: %v", err)
	}
	if relu.PairingID != "paire-002" {
		t.Errorf("pairing_id = %q, attendu paire-002 (mono-tablette)", relu.PairingID)
	}
	if !bytes.Equal(relu.TabPub, nouvelle) {
		t.Error("tab_pub != nouvelle cle")
	}

	var total int
	if err := depot.bdd.QueryRowContext(ctx, `SELECT COUNT(*) FROM appairage`).Scan(&total); err != nil {
		t.Fatalf("count: %v", err)
	}
	if total != 1 {
		t.Errorf("nombre de lignes = %d, attendu 1", total)
	}
}

func TestEnregistrerAppairage_ChampsInvalides(t *testing.T) {
	depot := ouvrirDepotDeTest(t)
	ctx := context.Background()

	if _, err := depot.EnregistrerAppairage(ctx, "", []byte("cle")); !errors.Is(err, ErrAppairageInvalide) {
		t.Errorf("pairing_id vide: erreur = %v, attendu ErrAppairageInvalide", err)
	}
	if _, err := depot.EnregistrerAppairage(ctx, "paire-001", nil); !errors.Is(err, ErrAppairageInvalide) {
		t.Errorf("tab_pub vide: erreur = %v, attendu ErrAppairageInvalide", err)
	}
}

func TestMarquerUtilise(t *testing.T) {
	depot := ouvrirDepotDeTest(t)
	ctx := context.Background()

	if _, err := depot.EnregistrerAppairage(ctx, "paire-001", []byte("cle-publique-tab")); err != nil {
		t.Fatalf("EnregistrerAppairage: %v", err)
	}
	if err := depot.MarquerUtilise(ctx, "paire-001"); err != nil {
		t.Fatalf("MarquerUtilise: %v", err)
	}
	relu, err := depot.LireAppairageActuel(ctx)
	if err != nil {
		t.Fatalf("LireAppairageActuel: %v", err)
	}
	if relu.DateDernierUsage == "" {
		t.Error("date_dernier_usage non mise a jour")
	}

	if err := depot.MarquerUtilise(ctx, "paire-inexistante"); !errors.Is(err, ErrAucunAppairage) {
		t.Errorf("erreur = %v, attendu ErrAucunAppairage", err)
	}
}
