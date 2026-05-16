package patients

import (
	"context"
	"database/sql"
	"errors"
	"fmt"
	"strings"
	"time"
	"unicode"

	"github.com/google/uuid"
	_ "modernc.org/sqlite"
)

var (
	ErrPatientDejaExistant = errors.New("patients: patient deja existant")
	ErrPatientIntrouvable  = errors.New("patients: patient introuvable")
	ErrPatientInvalide     = errors.New("patients: patient invalide")
)

const schemaPatients = `
CREATE TABLE IF NOT EXISTS patients (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    patient_id TEXT UNIQUE NOT NULL,
    nom TEXT NOT NULL,
    prenom TEXT NOT NULL,
    initiales TEXT NOT NULL,
    date_naissance TEXT,
    notes TEXT,
    date_creation TEXT NOT NULL
);
`

type Patient struct {
	ID            int64  `json:"id"`
	PatientID     string `json:"patient_id"`
	Nom           string `json:"nom"`
	Prenom        string `json:"prenom"`
	Initiales     string `json:"initiales"`
	DateNaissance string `json:"date_naissance"`
	Notes         string `json:"notes"`
	DateCreation  string `json:"date_creation"`
}

type DepotPatients struct {
	bdd *sql.DB
}

func OuvrirDepot(cheminBase string) (*DepotPatients, error) {
	bdd, err := sql.Open("sqlite", cheminBase)
	if err != nil {
		return nil, fmt.Errorf("patients: ouvrir base: %w", err)
	}
	bdd.SetMaxOpenConns(1)
	if _, err := bdd.Exec(schemaPatients); err != nil {
		bdd.Close()
		return nil, fmt.Errorf("patients: migration: %w", err)
	}
	return &DepotPatients{bdd: bdd}, nil
}

func (d *DepotPatients) Fermer() error {
	return d.bdd.Close()
}

func (d *DepotPatients) CreerPatient(ctx context.Context, nom, prenom string, dateNaissance, notes string) (Patient, error) {
	nomNet := strings.TrimSpace(nom)
	prenomNet := strings.TrimSpace(prenom)
	if nomNet == "" || prenomNet == "" {
		return Patient{}, fmt.Errorf("%w: nom et prenom obligatoires", ErrPatientInvalide)
	}

	tx, err := d.bdd.BeginTx(ctx, nil)
	if err != nil {
		return Patient{}, fmt.Errorf("patients: begin tx: %w", err)
	}
	defer tx.Rollback()

	var nbExistants int
	if err := tx.QueryRowContext(ctx,
		`SELECT COUNT(*) FROM patients WHERE nom = ? AND prenom = ?`,
		nomNet, prenomNet).Scan(&nbExistants); err != nil {
		return Patient{}, fmt.Errorf("patients: verifier doublon: %w", err)
	}
	if nbExistants > 0 {
		return Patient{}, fmt.Errorf("%w: %s %s", ErrPatientDejaExistant, prenomNet, nomNet)
	}

	patientID := uuid.NewString()
	initiales := calculerInitiales(prenomNet, nomNet)
	dateCreation := time.Now().UTC().Format(time.RFC3339)

	resultat, err := tx.ExecContext(ctx,
		`INSERT INTO patients (patient_id, nom, prenom, initiales, date_naissance, notes, date_creation)
		 VALUES (?, ?, ?, ?, ?, ?, ?)`,
		patientID, nomNet, prenomNet, initiales, dateNaissance, notes, dateCreation)
	if err != nil {
		return Patient{}, fmt.Errorf("patients: inserer: %w", err)
	}
	id, err := resultat.LastInsertId()
	if err != nil {
		return Patient{}, fmt.Errorf("patients: lastinsertid: %w", err)
	}

	if err := tx.Commit(); err != nil {
		return Patient{}, fmt.Errorf("patients: commit: %w", err)
	}

	return Patient{
		ID:            id,
		PatientID:     patientID,
		Nom:           nomNet,
		Prenom:        prenomNet,
		Initiales:     initiales,
		DateNaissance: dateNaissance,
		Notes:         notes,
		DateCreation:  dateCreation,
	}, nil
}

func (d *DepotPatients) ListerPatients(ctx context.Context) ([]Patient, error) {
	lignes, err := d.bdd.QueryContext(ctx,
		`SELECT id, patient_id, nom, prenom, initiales, date_naissance, notes, date_creation
		 FROM patients
		 ORDER BY nom COLLATE NOCASE, prenom COLLATE NOCASE`)
	if err != nil {
		return nil, fmt.Errorf("patients: lister: %w", err)
	}
	defer lignes.Close()
	return scannerPatients(lignes)
}

func (d *DepotPatients) RechercherPatients(ctx context.Context, recherche string) ([]Patient, error) {
	motif := "%" + strings.ToLower(strings.TrimSpace(recherche)) + "%"
	lignes, err := d.bdd.QueryContext(ctx,
		`SELECT id, patient_id, nom, prenom, initiales, date_naissance, notes, date_creation
		 FROM patients
		 WHERE LOWER(nom) LIKE ? OR LOWER(prenom) LIKE ?
		 ORDER BY nom COLLATE NOCASE, prenom COLLATE NOCASE`,
		motif, motif)
	if err != nil {
		return nil, fmt.Errorf("patients: rechercher: %w", err)
	}
	defer lignes.Close()
	return scannerPatients(lignes)
}

func (d *DepotPatients) LirePatientParID(ctx context.Context, patientID string) (Patient, error) {
	var p Patient
	err := d.bdd.QueryRowContext(ctx,
		`SELECT id, patient_id, nom, prenom, initiales, date_naissance, notes, date_creation
		 FROM patients WHERE patient_id = ?`, patientID).Scan(
		&p.ID, &p.PatientID, &p.Nom, &p.Prenom, &p.Initiales,
		&p.DateNaissance, &p.Notes, &p.DateCreation)
	if errors.Is(err, sql.ErrNoRows) {
		return Patient{}, fmt.Errorf("%w: %s", ErrPatientIntrouvable, patientID)
	}
	if err != nil {
		return Patient{}, fmt.Errorf("patients: lire par id: %w", err)
	}
	return p, nil
}

func (d *DepotPatients) SupprimerPatient(ctx context.Context, patientID string) error {
	resultat, err := d.bdd.ExecContext(ctx,
		`DELETE FROM patients WHERE patient_id = ?`, patientID)
	if err != nil {
		return fmt.Errorf("patients: supprimer: %w", err)
	}
	nb, err := resultat.RowsAffected()
	if err != nil {
		return fmt.Errorf("patients: rowsaffected: %w", err)
	}
	if nb == 0 {
		return fmt.Errorf("%w: %s", ErrPatientIntrouvable, patientID)
	}
	return nil
}

func scannerPatients(lignes *sql.Rows) ([]Patient, error) {
	var resultats []Patient
	for lignes.Next() {
		var p Patient
		if err := lignes.Scan(&p.ID, &p.PatientID, &p.Nom, &p.Prenom, &p.Initiales,
			&p.DateNaissance, &p.Notes, &p.DateCreation); err != nil {
			return nil, fmt.Errorf("patients: scanner: %w", err)
		}
		resultats = append(resultats, p)
	}
	if err := lignes.Err(); err != nil {
		return nil, fmt.Errorf("patients: iteration: %w", err)
	}
	return resultats, nil
}

func calculerInitiales(prenom, nom string) string {
	combinees := []rune(premieresLettres(prenom) + premieresLettres(nom))
	if len(combinees) > 3 {
		combinees = combinees[:3]
	}
	return string(combinees)
}

func premieresLettres(texte string) string {
	var b strings.Builder
	for _, partie := range strings.Split(texte, "-") {
		partie = strings.TrimSpace(partie)
		if partie == "" {
			continue
		}
		runes := []rune(partie)
		b.WriteRune(unicode.ToUpper(runes[0]))
	}
	return b.String()
}
