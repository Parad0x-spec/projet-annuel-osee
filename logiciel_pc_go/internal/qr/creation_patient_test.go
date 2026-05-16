package qr

import (
	"bytes"
	"encoding/base64"
	"encoding/json"
	"errors"
	"testing"

	"github.com/google/uuid"

	"projet_annuel/logiciel_pc_go/internal/crypto"
)

func genererClesPCPourTest(t *testing.T) (clePrivee, clePublique []byte) {
	t.Helper()
	priv, pub, err := crypto.GenererPaireDeCles()
	if err != nil {
		t.Fatalf("generation cles: %v", err)
	}
	return priv, pub
}

func TestGenererQRCreationPatient_StructureEnveloppe(t *testing.T) {
	clePrivee, _ := genererClesPCPourTest(t)
	patientID := uuid.NewString()

	enveloppeJSON, pngQR, err := GenererQRCreationPatient(clePrivee, patientID, "MD", 3)
	if err != nil {
		t.Fatalf("GenererQRCreationPatient: %v", err)
	}
	if len(enveloppeJSON) == 0 {
		t.Error("enveloppe JSON vide")
	}
	if len(pngQR) == 0 {
		t.Error("PNG vide")
	}

	var enveloppe Enveloppe
	if err := json.Unmarshal(enveloppeJSON, &enveloppe); err != nil {
		t.Fatalf("unmarshal enveloppe: %v", err)
	}
	if enveloppe.Type != TypeCreationPatient {
		t.Errorf("type = %q, attendu %q", enveloppe.Type, TypeCreationPatient)
	}
	if enveloppe.Version != VersionProtocole {
		t.Errorf("version = %d, attendu %d", enveloppe.Version, VersionProtocole)
	}
	if enveloppe.Timestamp == "" {
		t.Error("timestamp vide")
	}
	if enveloppe.Signature == "" {
		t.Error("signature vide")
	}

	var payload PayloadCreationPatient
	if err := json.Unmarshal(enveloppe.Payload, &payload); err != nil {
		t.Fatalf("unmarshal payload: %v", err)
	}
	if payload.PatientID != patientID {
		t.Errorf("patient_id = %q, attendu %q", payload.PatientID, patientID)
	}
	if payload.PatientInitiales != "MD" {
		t.Errorf("patient_initiales = %q, attendu %q", payload.PatientInitiales, "MD")
	}
	if payload.NiveauDemande != 3 {
		t.Errorf("niveau_demande = %d, attendu 3", payload.NiveauDemande)
	}
}

func TestGenererQRCreationPatient_RoundTripLireChargeUtileQR(t *testing.T) {
	clePrivee, _ := genererClesPCPourTest(t)
	patientID := uuid.NewString()

	enveloppeJSON, _, err := GenererQRCreationPatient(clePrivee, patientID, "JPM", 4)
	if err != nil {
		t.Fatalf("generation: %v", err)
	}

	chargeUtile, err := compresserEtEncoder(enveloppeJSON)
	if err != nil {
		t.Fatalf("compresser pour test: %v", err)
	}

	enveloppe, err := LireChargeUtileQR(chargeUtile)
	if err != nil {
		t.Fatalf("LireChargeUtileQR: %v", err)
	}
	if enveloppe.Type != TypeCreationPatient {
		t.Errorf("type round-trip = %q, attendu %q", enveloppe.Type, TypeCreationPatient)
	}
	if enveloppe.Version != VersionProtocole {
		t.Errorf("version round-trip = %d, attendu %d", enveloppe.Version, VersionProtocole)
	}

	var payload PayloadCreationPatient
	if err := json.Unmarshal(enveloppe.Payload, &payload); err != nil {
		t.Fatalf("unmarshal payload round-trip: %v", err)
	}
	if payload.PatientID != patientID || payload.PatientInitiales != "JPM" || payload.NiveauDemande != 4 {
		t.Errorf("round-trip payload divergent: %+v", payload)
	}
}

func TestGenererQRCreationPatient_SignatureVerifiableAvecClePublique(t *testing.T) {
	clePrivee, clePublique := genererClesPCPourTest(t)

	enveloppeJSON, _, err := GenererQRCreationPatient(clePrivee, "patient-uuid-1", "MD", 2)
	if err != nil {
		t.Fatalf("generation: %v", err)
	}

	var enveloppe Enveloppe
	if err := json.Unmarshal(enveloppeJSON, &enveloppe); err != nil {
		t.Fatalf("unmarshal: %v", err)
	}

	signature, err := base64.StdEncoding.DecodeString(enveloppe.Signature)
	if err != nil {
		t.Fatalf("decoder signature: %v", err)
	}

	messageSigne, err := SerialiserPourSignature(enveloppe)
	if err != nil {
		t.Fatalf("SerialiserPourSignature: %v", err)
	}

	if !crypto.Verifier(clePublique, messageSigne, signature) {
		t.Error("signature non verifiable avec la cle publique attendue")
	}
}

func TestGenererQRCreationPatient_RejetNiveauHorsPlage(t *testing.T) {
	clePrivee, _ := genererClesPCPourTest(t)
	niveauxInvalides := []int{0, -1, 6, 100}
	for _, n := range niveauxInvalides {
		_, _, err := GenererQRCreationPatient(clePrivee, "patient-1", "MD", n)
		if !errors.Is(err, ErrNiveauHorsPlage) {
			t.Errorf("niveau %d: erreur = %v, attendu ErrNiveauHorsPlage", n, err)
		}
	}
	for _, n := range []int{1, 5} {
		if _, _, err := GenererQRCreationPatient(clePrivee, "patient-1", "MD", n); err != nil {
			t.Errorf("niveau limite %d: erreur inattendue %v", n, err)
		}
	}
}

func TestGenererQRCreationPatient_RejetPatientIDVide(t *testing.T) {
	clePrivee, _ := genererClesPCPourTest(t)
	_, _, err := GenererQRCreationPatient(clePrivee, "", "MD", 3)
	if !errors.Is(err, ErrPatientIDInvalide) {
		t.Errorf("erreur = %v, attendu ErrPatientIDInvalide", err)
	}
}

func TestGenererQRCreationPatient_RejetInitialesVides(t *testing.T) {
	clePrivee, _ := genererClesPCPourTest(t)
	_, _, err := GenererQRCreationPatient(clePrivee, "patient-1", "", 3)
	if !errors.Is(err, ErrInitialesInvalides) {
		t.Errorf("erreur = %v, attendu ErrInitialesInvalides", err)
	}
}

func TestGenererQRCreationPatient_PNGValide(t *testing.T) {
	clePrivee, _ := genererClesPCPourTest(t)

	_, pngQR, err := GenererQRCreationPatient(clePrivee, "patient-1", "MD", 3)
	if err != nil {
		t.Fatalf("generation: %v", err)
	}
	enTetePNG := []byte{0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A}
	if len(pngQR) < len(enTetePNG) {
		t.Fatalf("PNG trop court: %d octets", len(pngQR))
	}
	if !bytes.Equal(pngQR[:len(enTetePNG)], enTetePNG) {
		t.Errorf("en-tete PNG invalide: got %x want %x", pngQR[:len(enTetePNG)], enTetePNG)
	}
}
