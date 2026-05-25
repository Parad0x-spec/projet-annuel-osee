package main

import (
	"context"
	"crypto/ed25519"
	"crypto/rand"
	"encoding/base64"
	"encoding/json"
	"fmt"
	"path/filepath"
	"strings"
	"testing"

	"projet_annuel/logiciel_pc_go/internal/appairage_pc"
	"projet_annuel/logiciel_pc_go/internal/patients"
	"projet_annuel/logiciel_pc_go/internal/qr"
	"projet_annuel/logiciel_pc_go/internal/sessions"
)

func enveloppeSessionSignee(t *testing.T, patientID, initiales string, niveau int, tabPriv []byte) qr.Enveloppe {
	t.Helper()
	payloadJSON := fmt.Sprintf(
		`{"patient_id":%q,"patient_initiales":%q,"session_date":"2026-05-25T10:00:00.000Z","jeu_type":"emotions","niveau":%d,"manches":[]}`,
		patientID, initiales, niveau)
	enveloppe := qr.Enveloppe{
		Type:      qr.TypeSession,
		Version:   qr.VersionProtocole,
		Timestamp: "2026-05-25T10:00:05.000Z",
		Payload:   json.RawMessage(payloadJSON),
	}
	messageSigne, err := qr.SerialiserPourSignature(enveloppe)
	if err != nil {
		t.Fatalf("SerialiserPourSignature: %v", err)
	}
	enveloppe.Signature = base64.StdEncoding.EncodeToString(ed25519.Sign(ed25519.PrivateKey(tabPriv), messageSigne))
	return enveloppe
}

func TestTraiterSession_RechargeAppairageEtStocke(t *testing.T) {
	ctx := context.Background()
	chemin := filepath.Join(t.TempDir(), "patients.db")

	depotPatients, err := patients.OuvrirDepot(chemin)
	if err != nil {
		t.Fatalf("OuvrirDepot patients: %v", err)
	}
	defer depotPatients.Fermer()
	patient, err := depotPatients.CreerPatient(ctx, "Dupont", "Marie", "", "")
	if err != nil {
		t.Fatalf("CreerPatient: %v", err)
	}

	depotAppairage, err := appairage_pc.OuvrirDepot(chemin)
	if err != nil {
		t.Fatalf("OuvrirDepot appairage: %v", err)
	}
	defer depotAppairage.Fermer()
	depotSessions, err := sessions.OuvrirDepot(chemin)
	if err != nil {
		t.Fatalf("OuvrirDepot sessions: %v", err)
	}
	defer depotSessions.Fermer()

	tabPub, tabPriv, err := ed25519.GenerateKey(rand.Reader)
	if err != nil {
		t.Fatalf("generation cles tablette: %v", err)
	}
	if _, err := depotAppairage.EnregistrerAppairage(ctx, "paire-001", tabPub); err != nil {
		t.Fatalf("EnregistrerAppairage: %v", err)
	}

	session := &sessionAppairage{}
	enveloppe := enveloppeSessionSignee(t, patient.PatientID, patient.Initiales, 3, tabPriv)

	message := traiterSession(ctx, session, depotAppairage, depotSessions, enveloppe)
	if !strings.Contains(message, "Session recue") {
		t.Fatalf("message = %q, attendu confirmation de reception", message)
	}

	liste, err := depotSessions.ListerSessionsParPatient(ctx, patient.PatientID)
	if err != nil {
		t.Fatalf("ListerSessionsParPatient: %v", err)
	}
	if len(liste) != 1 {
		t.Fatalf("sessions stockees = %d, attendu 1", len(liste))
	}
	if liste[0].Niveau != 3 || liste[0].JeuType != "emotions" {
		t.Errorf("session stockee = %+v", liste[0])
	}
}

func TestTraiterSession_PatientInconnu(t *testing.T) {
	ctx := context.Background()
	chemin := filepath.Join(t.TempDir(), "patients.db")

	depotPatients, err := patients.OuvrirDepot(chemin)
	if err != nil {
		t.Fatalf("OuvrirDepot patients: %v", err)
	}
	defer depotPatients.Fermer()

	depotAppairage, err := appairage_pc.OuvrirDepot(chemin)
	if err != nil {
		t.Fatalf("OuvrirDepot appairage: %v", err)
	}
	defer depotAppairage.Fermer()
	depotSessions, err := sessions.OuvrirDepot(chemin)
	if err != nil {
		t.Fatalf("OuvrirDepot sessions: %v", err)
	}
	defer depotSessions.Fermer()

	tabPub, tabPriv, err := ed25519.GenerateKey(rand.Reader)
	if err != nil {
		t.Fatalf("generation cles: %v", err)
	}
	if _, err := depotAppairage.EnregistrerAppairage(ctx, "paire-001", tabPub); err != nil {
		t.Fatalf("EnregistrerAppairage: %v", err)
	}

	session := &sessionAppairage{}
	enveloppe := enveloppeSessionSignee(t, "id-inexistant", "ZZ", 2, tabPriv)

	message := traiterSession(ctx, session, depotAppairage, depotSessions, enveloppe)
	if !strings.Contains(message, "Patient inconnu") {
		t.Errorf("message = %q, attendu message patient inconnu", message)
	}
}
