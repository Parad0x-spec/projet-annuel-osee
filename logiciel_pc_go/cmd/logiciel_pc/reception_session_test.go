package main

import (
	"context"
	"crypto/ed25519"
	"crypto/rand"
	"encoding/base64"
	"encoding/json"
	"fmt"
	"os"
	"path/filepath"
	"strings"
	"testing"

	"projet_annuel/logiciel_pc_go/internal/appairage_pc"
	"projet_annuel/logiciel_pc_go/internal/export"
	"projet_annuel/logiciel_pc_go/internal/patients"
	"projet_annuel/logiciel_pc_go/internal/qr"
	"projet_annuel/logiciel_pc_go/internal/sessions"
)

func enveloppeSessionSignee(t *testing.T, patientID, initiales string, niveau int, tabPriv []byte) qr.Enveloppe {
	t.Helper()
	payloadJSON := fmt.Sprintf(
		`{"patient_id":%q,"patient_initiales":%q,"session_date":"2026-05-25T10:00:00.000Z","jeu_type":"emotions","niveau":%d,`+
			`"planches":[{"numero_planche":1,"score_global":82,"resultats_par_emotion":[`+
			`{"emotion":"joie","nb_cibles_total":3,"nb_cibles_trouvees":3,"nb_faux_positifs":0,"score":100,"evaluee":true},`+
			`{"emotion":"colere","nb_cibles_total":2,"nb_cibles_trouvees":1,"nb_faux_positifs":1,"score":45,"evaluee":true}]}]}`,
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
	dossierExports := t.TempDir()

	message := traiterSession(ctx, session, depotAppairage, depotSessions, depotPatients, dossierExports, enveloppe)
	if !strings.Contains(message, "Session recue") {
		t.Fatalf("message = %q, attendu confirmation de reception", message)
	}
	if strings.Contains(message, "export Excel non genere") {
		t.Errorf("export Excel attendu reussi, message = %q", message)
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

	planches, err := depotSessions.ListerPlanchesParSession(ctx, liste[0].ID)
	if err != nil {
		t.Fatalf("ListerPlanchesParSession: %v", err)
	}
	if len(planches) != 1 {
		t.Fatalf("planches stockees = %d, attendu 1", len(planches))
	}
	if planches[0].NumeroPlanche != 1 || planches[0].ScoreGlobal != 82 {
		t.Errorf("planche stockee = %+v", planches[0])
	}
	if len(planches[0].ResultatsParEmotion) != 2 {
		t.Fatalf("resultats emotion stockes = %d, attendu 2", len(planches[0].ResultatsParEmotion))
	}
	if planches[0].ResultatsParEmotion[0].Emotion != "joie" || planches[0].ResultatsParEmotion[0].Score != 100 {
		t.Errorf("resultat emotion stocke = %+v", planches[0].ResultatsParEmotion[0])
	}

	cheminExcel := export.CheminExportPatient(dossierExports, patient)
	if _, err := os.Stat(cheminExcel); err != nil {
		t.Errorf("fichier Excel non genere a la reception : %v", err)
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

	message := traiterSession(ctx, session, depotAppairage, depotSessions, depotPatients, t.TempDir(), enveloppe)
	if !strings.Contains(message, "Patient inconnu") {
		t.Errorf("message = %q, attendu message patient inconnu", message)
	}
}
