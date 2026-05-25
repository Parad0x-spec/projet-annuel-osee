package appairage_pc

import (
	"context"
	"database/sql"
	"encoding/base64"
	"errors"
	"fmt"
	"time"

	_ "modernc.org/sqlite"
)

var (
	ErrAucunAppairage    = errors.New("appairage_pc: aucun appairage enregistre")
	ErrAppairageInvalide = errors.New("appairage_pc: appairage invalide")
)

const schemaAppairage = `
CREATE TABLE IF NOT EXISTS appairage (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    pairing_id TEXT UNIQUE NOT NULL,
    tab_pub TEXT NOT NULL,
    date_appairage TEXT NOT NULL,
    date_dernier_usage TEXT
);
`

type Appairage struct {
	ID               int64
	PairingID        string
	TabPub           []byte
	DateAppairage    string
	DateDernierUsage string
}

type DepotAppairage struct {
	bdd *sql.DB
}

func OuvrirDepot(cheminBase string) (*DepotAppairage, error) {
	bdd, err := sql.Open("sqlite", cheminBase)
	if err != nil {
		return nil, fmt.Errorf("appairage_pc: ouvrir base: %w", err)
	}
	bdd.SetMaxOpenConns(1)
	if _, err := bdd.Exec(schemaAppairage); err != nil {
		bdd.Close()
		return nil, fmt.Errorf("appairage_pc: migration: %w", err)
	}
	return &DepotAppairage{bdd: bdd}, nil
}

func (d *DepotAppairage) Fermer() error {
	return d.bdd.Close()
}

func (d *DepotAppairage) EnregistrerAppairage(ctx context.Context, pairingID string, tabPub []byte) (Appairage, error) {
	if pairingID == "" {
		return Appairage{}, fmt.Errorf("%w: pairing_id vide", ErrAppairageInvalide)
	}
	if len(tabPub) == 0 {
		return Appairage{}, fmt.Errorf("%w: tab_pub vide", ErrAppairageInvalide)
	}

	tx, err := d.bdd.BeginTx(ctx, nil)
	if err != nil {
		return Appairage{}, fmt.Errorf("appairage_pc: begin tx: %w", err)
	}
	defer tx.Rollback()

	if _, err := tx.ExecContext(ctx, `DELETE FROM appairage`); err != nil {
		return Appairage{}, fmt.Errorf("appairage_pc: purge: %w", err)
	}

	tabPubBase64 := base64.StdEncoding.EncodeToString(tabPub)
	dateAppairage := time.Now().UTC().Format(time.RFC3339)
	resultat, err := tx.ExecContext(ctx,
		`INSERT INTO appairage (pairing_id, tab_pub, date_appairage, date_dernier_usage)
		 VALUES (?, ?, ?, NULL)`,
		pairingID, tabPubBase64, dateAppairage)
	if err != nil {
		return Appairage{}, fmt.Errorf("appairage_pc: inserer: %w", err)
	}
	id, err := resultat.LastInsertId()
	if err != nil {
		return Appairage{}, fmt.Errorf("appairage_pc: lastinsertid: %w", err)
	}
	if err := tx.Commit(); err != nil {
		return Appairage{}, fmt.Errorf("appairage_pc: commit: %w", err)
	}

	return Appairage{
		ID:            id,
		PairingID:     pairingID,
		TabPub:        tabPub,
		DateAppairage: dateAppairage,
	}, nil
}

func (d *DepotAppairage) LireAppairageActuel(ctx context.Context) (Appairage, error) {
	var (
		a                Appairage
		tabPubBase64     string
		dateDernierUsage sql.NullString
	)
	err := d.bdd.QueryRowContext(ctx,
		`SELECT id, pairing_id, tab_pub, date_appairage, date_dernier_usage
		 FROM appairage ORDER BY id DESC LIMIT 1`).Scan(
		&a.ID, &a.PairingID, &tabPubBase64, &a.DateAppairage, &dateDernierUsage)
	if errors.Is(err, sql.ErrNoRows) {
		return Appairage{}, ErrAucunAppairage
	}
	if err != nil {
		return Appairage{}, fmt.Errorf("appairage_pc: lire actuel: %w", err)
	}
	tabPub, err := base64.StdEncoding.DecodeString(tabPubBase64)
	if err != nil {
		return Appairage{}, fmt.Errorf("%w: tab_pub illisible: %v", ErrAppairageInvalide, err)
	}
	a.TabPub = tabPub
	if dateDernierUsage.Valid {
		a.DateDernierUsage = dateDernierUsage.String
	}
	return a, nil
}

func (d *DepotAppairage) MarquerUtilise(ctx context.Context, pairingID string) error {
	maintenant := time.Now().UTC().Format(time.RFC3339)
	resultat, err := d.bdd.ExecContext(ctx,
		`UPDATE appairage SET date_dernier_usage = ? WHERE pairing_id = ?`,
		maintenant, pairingID)
	if err != nil {
		return fmt.Errorf("appairage_pc: marquer utilise: %w", err)
	}
	nb, err := resultat.RowsAffected()
	if err != nil {
		return fmt.Errorf("appairage_pc: rowsaffected: %w", err)
	}
	if nb == 0 {
		return ErrAucunAppairage
	}
	return nil
}
