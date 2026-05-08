package qr

import (
	"bytes"
	"crypto/ed25519"
	"crypto/rand"
	"encoding/json"
	"testing"

	"github.com/google/uuid"
)

func TestGenererQRAppairage_StructureEnveloppe(t *testing.T) {
	clePubliquePC := genererClePubliqueDeTest(t)

	enveloppeJSON, pngQR, pairingId, err := GenererQRAppairage(clePubliquePC)
	if err != nil {
		t.Fatalf("erreur inattendue: %v", err)
	}
	if len(enveloppeJSON) == 0 {
		t.Error("enveloppe JSON vide")
	}
	if len(pngQR) == 0 {
		t.Error("PNG vide")
	}
	if pairingId == "" {
		t.Error("pairing_id vide")
	}

	var enveloppe Enveloppe
	if err := json.Unmarshal(enveloppeJSON, &enveloppe); err != nil {
		t.Fatalf("unmarshal enveloppe: %v", err)
	}
	if enveloppe.Type != TypeAppairagePC {
		t.Errorf("type = %q, attendu %q", enveloppe.Type, TypeAppairagePC)
	}
	if enveloppe.Version != VersionProtocole {
		t.Errorf("version = %d, attendu %d", enveloppe.Version, VersionProtocole)
	}
	if enveloppe.Timestamp == "" {
		t.Error("timestamp vide")
	}
	if enveloppe.Signature != "" {
		t.Errorf("signature = %q, attendu chaine vide pour appairage_pc", enveloppe.Signature)
	}

	var payload PayloadAppairagePC
	if err := json.Unmarshal(enveloppe.Payload, &payload); err != nil {
		t.Fatalf("unmarshal payload: %v", err)
	}
	if payload.PairingId != pairingId {
		t.Errorf("pairing_id du payload = %q, attendu %q", payload.PairingId, pairingId)
	}
	if payload.PcPub == "" {
		t.Error("pc_pub vide")
	}
}

func TestGenererQRAppairage_PairingIdEstUUIDv4(t *testing.T) {
	clePubliquePC := genererClePubliqueDeTest(t)

	_, _, pairingId, err := GenererQRAppairage(clePubliquePC)
	if err != nil {
		t.Fatalf("erreur: %v", err)
	}
	identifiant, err := uuid.Parse(pairingId)
	if err != nil {
		t.Fatalf("pairing_id non parsable: %v", err)
	}
	if identifiant.Version() != 4 {
		t.Errorf("version UUID = %d, attendu 4", identifiant.Version())
	}
}

func TestSerialiserDeserialiser_RoundTrip(t *testing.T) {
	original := Enveloppe{
		Type:      TypeAppairagePC,
		Version:   VersionProtocole,
		Timestamp: "2026-05-08T09:00:00Z",
		Payload:   json.RawMessage(`{"pairing_id":"abc","pc_pub":"def"}`),
		Signature: "",
	}

	donnees, err := SerialiserCanonique(original)
	if err != nil {
		t.Fatalf("serialiser: %v", err)
	}

	deserialise, err := DeserialiserEnveloppe(donnees)
	if err != nil {
		t.Fatalf("deserialiser: %v", err)
	}

	if deserialise.Type != original.Type {
		t.Errorf("type: got %q want %q", deserialise.Type, original.Type)
	}
	if deserialise.Version != original.Version {
		t.Errorf("version: got %d want %d", deserialise.Version, original.Version)
	}
	if deserialise.Timestamp != original.Timestamp {
		t.Errorf("timestamp: got %q want %q", deserialise.Timestamp, original.Timestamp)
	}
	if deserialise.Signature != original.Signature {
		t.Errorf("signature: got %q want %q", deserialise.Signature, original.Signature)
	}
	if !bytes.Equal(deserialise.Payload, original.Payload) {
		t.Errorf("payload: got %s want %s", deserialise.Payload, original.Payload)
	}
}

func TestGenererQRAppairage_PNGValide(t *testing.T) {
	clePubliquePC := genererClePubliqueDeTest(t)

	_, pngQR, _, err := GenererQRAppairage(clePubliquePC)
	if err != nil {
		t.Fatalf("erreur: %v", err)
	}
	enTetePNG := []byte{0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A}
	if len(pngQR) < len(enTetePNG) {
		t.Fatalf("PNG trop court: %d octets", len(pngQR))
	}
	if !bytes.Equal(pngQR[:len(enTetePNG)], enTetePNG) {
		t.Errorf("en-tete PNG invalide: got %x want %x", pngQR[:len(enTetePNG)], enTetePNG)
	}
}

func TestSerialiserCanonique_Stable(t *testing.T) {
	enveloppe := Enveloppe{
		Type:      TypeAppairagePC,
		Version:   VersionProtocole,
		Timestamp: "2026-05-08T09:00:00Z",
		Payload:   json.RawMessage(`{"pairing_id":"abc","pc_pub":"def"}`),
		Signature: "",
	}

	premiereSortie, err := SerialiserCanonique(enveloppe)
	if err != nil {
		t.Fatal(err)
	}
	secondeSortie, err := SerialiserCanonique(enveloppe)
	if err != nil {
		t.Fatal(err)
	}
	if !bytes.Equal(premiereSortie, secondeSortie) {
		t.Errorf("serialisation non stable:\npremiere : %s\nseconde : %s", premiereSortie, secondeSortie)
	}
}

func genererClePubliqueDeTest(t *testing.T) []byte {
	t.Helper()
	clePublique, _, err := ed25519.GenerateKey(rand.Reader)
	if err != nil {
		t.Fatalf("generation cles: %v", err)
	}
	return []byte(clePublique)
}
