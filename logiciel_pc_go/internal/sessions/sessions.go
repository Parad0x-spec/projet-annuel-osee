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
CREATE TABLE IF NOT EXISTS planches_jouees (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    session_id INTEGER NOT NULL REFERENCES sessions(id) ON DELETE CASCADE,
    numero_planche INTEGER NOT NULL,
    score_global INTEGER NOT NULL
);
CREATE TABLE IF NOT EXISTS resultats_emotion (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    planche_jouee_id INTEGER NOT NULL REFERENCES planches_jouees(id) ON DELETE CASCADE,
    emotion TEXT NOT NULL,
    nb_cibles_total INTEGER NOT NULL,
    nb_cibles_trouvees INTEGER NOT NULL,
    nb_faux_positifs INTEGER NOT NULL,
    score INTEGER NOT NULL,
    evaluee INTEGER NOT NULL
);
CREATE INDEX IF NOT EXISTS idx_planches_jouees_session ON planches_jouees(session_id);
CREATE INDEX IF NOT EXISTS idx_resultats_emotion_planche ON resultats_emotion(planche_jouee_id);
`

type ResultatEmotion struct {
	Emotion          string
	NbCiblesTotal    int
	NbCiblesTrouvees int
	NbFauxPositifs   int
	Score            int
	Evaluee          bool
}

type PlancheJouee struct {
	NumeroPlanche       int
	ScoreGlobal         int
	ResultatsParEmotion []ResultatEmotion
}

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

func (d *DepotSessions) EnregistrerSession(ctx context.Context, patientID string, sessionDate time.Time, jeuType string, niveau int, planches []PlancheJouee, payloadJSON []byte) (Session, error) {
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

	tx, err := d.bdd.BeginTx(ctx, nil)
	if err != nil {
		return Session{}, fmt.Errorf("sessions: ouvrir transaction: %w", err)
	}
	committed := false
	defer func() {
		if !committed {
			_ = tx.Rollback()
		}
	}()

	resultat, err := tx.ExecContext(ctx,
		`INSERT INTO sessions (patient_id, session_date, jeu_type, niveau, payload_complet, date_reception)
		 VALUES (?, ?, ?, ?, ?, ?)`,
		patientID, sessionDateStr, jeuType, niveau, string(payloadJSON), dateReception)
	if err != nil {
		return Session{}, fmt.Errorf("sessions: inserer session: %w", err)
	}
	sessionID, err := resultat.LastInsertId()
	if err != nil {
		return Session{}, fmt.Errorf("sessions: lastinsertid session: %w", err)
	}

	for _, planche := range planches {
		resPlanche, err := tx.ExecContext(ctx,
			`INSERT INTO planches_jouees (session_id, numero_planche, score_global)
			 VALUES (?, ?, ?)`,
			sessionID, planche.NumeroPlanche, planche.ScoreGlobal)
		if err != nil {
			return Session{}, fmt.Errorf("sessions: inserer planche %d: %w", planche.NumeroPlanche, err)
		}
		plancheID, err := resPlanche.LastInsertId()
		if err != nil {
			return Session{}, fmt.Errorf("sessions: lastinsertid planche: %w", err)
		}
		for _, r := range planche.ResultatsParEmotion {
			if _, err := tx.ExecContext(ctx,
				`INSERT INTO resultats_emotion
				 (planche_jouee_id, emotion, nb_cibles_total, nb_cibles_trouvees, nb_faux_positifs, score, evaluee)
				 VALUES (?, ?, ?, ?, ?, ?, ?)`,
				plancheID, r.Emotion, r.NbCiblesTotal, r.NbCiblesTrouvees, r.NbFauxPositifs, r.Score, booleenVersEntier(r.Evaluee)); err != nil {
				return Session{}, fmt.Errorf("sessions: inserer resultat emotion %q: %w", r.Emotion, err)
			}
		}
	}

	if err := tx.Commit(); err != nil {
		return Session{}, fmt.Errorf("sessions: valider transaction: %w", err)
	}
	committed = true

	return Session{
		ID:             sessionID,
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

func (d *DepotSessions) ListerPlanchesParSession(ctx context.Context, sessionID int64) ([]PlancheJouee, error) {
	lignes, err := d.bdd.QueryContext(ctx,
		`SELECT id, numero_planche, score_global
		 FROM planches_jouees
		 WHERE session_id = ?
		 ORDER BY numero_planche ASC, id ASC`, sessionID)
	if err != nil {
		return nil, fmt.Errorf("sessions: lister planches: %w", err)
	}
	defer lignes.Close()

	var planches []PlancheJouee
	idsPlanches := make(map[int64]int)
	for lignes.Next() {
		var plancheID int64
		var planche PlancheJouee
		if err := lignes.Scan(&plancheID, &planche.NumeroPlanche, &planche.ScoreGlobal); err != nil {
			return nil, fmt.Errorf("sessions: scanner planche: %w", err)
		}
		idsPlanches[plancheID] = len(planches)
		planches = append(planches, planche)
	}
	if err := lignes.Err(); err != nil {
		return nil, fmt.Errorf("sessions: iteration planches: %w", err)
	}

	for plancheID, indice := range idsPlanches {
		resultats, err := d.lireResultatsEmotion(ctx, plancheID)
		if err != nil {
			return nil, err
		}
		planches[indice].ResultatsParEmotion = resultats
	}
	return planches, nil
}

func (d *DepotSessions) lireResultatsEmotion(ctx context.Context, plancheID int64) ([]ResultatEmotion, error) {
	lignes, err := d.bdd.QueryContext(ctx,
		`SELECT emotion, nb_cibles_total, nb_cibles_trouvees, nb_faux_positifs, score, evaluee
		 FROM resultats_emotion
		 WHERE planche_jouee_id = ?
		 ORDER BY id ASC`, plancheID)
	if err != nil {
		return nil, fmt.Errorf("sessions: lister resultats emotion: %w", err)
	}
	defer lignes.Close()

	var resultats []ResultatEmotion
	for lignes.Next() {
		var r ResultatEmotion
		var evaluee int
		if err := lignes.Scan(&r.Emotion, &r.NbCiblesTotal, &r.NbCiblesTrouvees, &r.NbFauxPositifs, &r.Score, &evaluee); err != nil {
			return nil, fmt.Errorf("sessions: scanner resultat emotion: %w", err)
		}
		r.Evaluee = evaluee != 0
		resultats = append(resultats, r)
	}
	if err := lignes.Err(); err != nil {
		return nil, fmt.Errorf("sessions: iteration resultats emotion: %w", err)
	}
	return resultats, nil
}

func booleenVersEntier(valeur bool) int {
	if valeur {
		return 1
	}
	return 0
}
