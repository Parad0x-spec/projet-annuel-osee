package main

import (
	"bytes"
	"errors"
	"image"
	"image/png"
	"strings"
	"testing"

	"projet_annuel/logiciel_pc_go/internal/qr"
)

func TestDecoderImageQR_RoundTripDepuisGenererQRAppairage(t *testing.T) {
	clePubliquePC := bytes.Repeat([]byte{0x42}, 32)
	const pairingIdFixe = "11111111-2222-4333-8444-555555555555"
	_, pngQR, pairingIdAttendu, err := qr.GenererQRAppairageAvecPairingId(clePubliquePC, pairingIdFixe)
	if err != nil {
		t.Fatalf("generation QR: %v", err)
	}

	img, err := png.Decode(bytes.NewReader(pngQR))
	if err != nil {
		t.Fatalf("decodage png: %v", err)
	}

	chargeUtile, err := decoderImageQR(img)
	if err != nil {
		t.Fatalf("decoderImageQR: %v", err)
	}
	if chargeUtile == "" {
		t.Fatal("charge utile retournee vide")
	}

	enveloppe, err := qr.LireChargeUtileQR(chargeUtile)
	if err != nil {
		t.Fatalf("LireChargeUtileQR: %v", err)
	}
	if enveloppe.Type != qr.TypeAppairagePC {
		t.Errorf("type = %q, attendu %q", enveloppe.Type, qr.TypeAppairagePC)
	}
	if !strings.Contains(string(enveloppe.Payload), pairingIdAttendu) {
		t.Errorf("payload %s ne contient pas le pairing_id %q", enveloppe.Payload, pairingIdAttendu)
	}
}

func TestDecoderImageQR_ImageSansQR(t *testing.T) {
	img := image.NewRGBA(image.Rect(0, 0, 100, 100))
	_, err := decoderImageQR(img)
	if err == nil {
		t.Fatal("attendu une erreur sur image sans QR")
	}
	if !errors.Is(err, ErrQRIntrouvable) {
		t.Errorf("erreur = %v, attendu ErrQRIntrouvable", err)
	}
}
