package sessions

import (
	"context"
	"database/sql"
	"errors"
	"fmt"
	"time"

	_ "modernc.org/sqlite"
)

var (
	ErrPatientInconnu  = errors.New("sessions: patient inconnu")
	ErrSessionInvalide = errors.New("sessions: session invalide")
)

const schemaSessions = `
CREATE TABLE IF NOT EXISTS sessions (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    patient_id TEXT NOT NULL REFERENCES patients(patient_id),
    session_date TEXT NOT NULL,
    jeu_type TEXT NOT NULL,
    niveau INTEGER NOT NULL,
    payload_complet TEXT NOT NULL,
    date_reception TEXT NOT NULL
);
`

type Session struct {
	ID             int64
	PatientID      string
	SessionDate    string
	JeuType        string
	Niveau         int
	PayloadComplet string
	DateReception  string
}

type DepotSessions struct {
	bdd *sql.DB
}

func OuvrirDepot(cheminBase string) (*DepotSessions, error) {
	bdd, err := sql.Open("sqlite", cheminBase)
	if err != nil {
		return nil, fmt.Errorf("sessions: ouvrir base: %w", err)
	}
	bdd.SetMaxOpenConns(1)
	if _, err := bdd.Exec(schemaSessions); err != nil {
		bdd.Close()
		return nil, fmt.Errorf("sessions: migration: %w", err)
	}
	return &DepotSessions{bdd: bdd}, nil
}

func (d *DepotSessions) Fermer() error {
	return d.bdd.Close()
}

func (d *DepotSessions) EnregistrerSession(ctx context.Context, patientID string, sessionDate time.Time, jeuType string, niveau int, payloadJSON []byte) (Session, error) {
	if patientID == "" {
		return Session{}, fmt.Errorf("%w: patient_id vide", ErrSessionInvalide)
	}
	if jeuType == "" {
		return Session{}, fmt.Errorf("%w: jeu_type vide", ErrSessionInvalide)
	}
	if len(payloadJSON) == 0 {
		return Session{}, fmt.Errorf("%w: payload vide", ErrSessionInvalide)
	}

	var nbPatients int
	if err := d.bdd.QueryRowContext(ctx,
		`SELECT COUNT(*) FROM patients WHERE patient_id = ?`, patientID).Scan(&nbPatients); err != nil {
		return Session{}, fmt.Errorf("sessions: verifier patient: %w", err)
	}
	if nbPatients == 0 {
		return Session{}, fmt.Errorf("%w: %s", ErrPatientInconnu, patientID)
	}

	sessionDateStr := sessionDate.UTC().Format(time.RFC3339)
	dateReception := time.Now().UTC().Format(time.RFC3339)
	resultat, err := d.bdd.ExecContext(ctx,
		`INSERT INTO sessions (patient_id, session_date, jeu_type, niveau, payload_complet, date_reception)
		 VALUES (?, ?, ?, ?, ?, ?)`,
		patientID, sessionDateStr, jeuType, niveau, string(payloadJSON), dateReception)
	if err != nil {
		return Session{}, fmt.Errorf("sessions: inserer: %w", err)
	}
	id, err := resultat.LastInsertId()
	if err != nil {
		return Session{}, fmt.Errorf("sessions: lastinsertid: %w", err)
	}

	return Session{
		ID:             id,
		PatientID:      patientID,
		SessionDate:    sessionDateStr,
		JeuType:        jeuType,
		Niveau:         niveau,
		PayloadComplet: string(payloadJSON),
		DateReception:  dateReception,
	}, nil
}

func (d *DepotSessions) ListerSessionsParPatient(ctx context.Context, patientID string) ([]Session, error) {
	lignes, err := d.bdd.QueryContext(ctx,
		`SELECT id, patient_id, session_date, jeu_type, niveau, payload_complet, date_reception
		 FROM sessions
		 WHERE patient_id = ?
		 ORDER BY session_date DESC, id DESC`, patientID)
	if err != nil {
		return nil, fmt.Errorf("sessions: lister par patient: %w", err)
	}
	defer lignes.Close()

	var resultats []Session
	for lignes.Next() {
		var s Session
		if err := lignes.Scan(&s.ID, &s.PatientID, &s.SessionDate, &s.JeuType,
			&s.Niveau, &s.PayloadComplet, &s.DateReception); err != nil {
			return nil, fmt.Errorf("sessions: scanner: %w", err)
		}
		resultats = append(resultats, s)
	}
	if err := lignes.Err(); err != nil {
		return nil, fmt.Errorf("sessions: iteration: %w", err)
	}
	return resultats, nil
}
