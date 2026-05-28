package main

import (
	"bytes"
	"context"
	"errors"
	"image"
	"image/png"
	"sync"
	"sync/atomic"
	"testing"
	"time"

	"projet_annuel/logiciel_pc_go/internal/qr"
)

type sourceMock struct {
	mu       sync.Mutex
	frames   []image.Image
	indice   int
	delai    time.Duration
	apresFin image.Image
	erreur   error
	ferme    atomic.Bool
}

func (s *sourceMock) LireFrame() (image.Image, error) {
	if s.delai > 0 {
		time.Sleep(s.delai)
	}
	if s.ferme.Load() {
		return nil, errors.New("source fermee")
	}
	s.mu.Lock()
	defer s.mu.Unlock()
	if s.erreur != nil {
		return nil, s.erreur
	}
	if s.indice < len(s.frames) {
		f := s.frames[s.indice]
		s.indice++
		return f, nil
	}
	return s.apresFin, nil
}

func (s *sourceMock) Fermer() error {
	s.ferme.Store(true)
	return nil
}

func imageVide() image.Image {
	return image.NewRGBA(image.Rect(0, 0, 320, 240))
}

func imageQRDepuisQRAppairage(t *testing.T) (image.Image, string) {
	t.Helper()
	clePubliquePC := bytes.Repeat([]byte{0x42}, 32)
	const pairingId = "11111111-2222-4333-8444-555555555555"
	_, pngQR, _, err := qr.GenererQRAppairageAvecPairingId(clePubliquePC, pairingId)
	if err != nil {
		t.Fatalf("GenererQRAppairageAvecPairingId: %v", err)
	}
	img, err := png.Decode(bytes.NewReader(pngQR))
	if err != nil {
		t.Fatalf("decodage png: %v", err)
	}
	return img, pairingId
}

func TestScannerAvecApercu_DecodageReussiAuBoutDeQuelquesFrames(t *testing.T) {
	imgQR, pairingIdAttendu := imageQRDepuisQRAppairage(t)
	source := &sourceMock{
		frames:   []image.Image{imageVide(), imageVide(), imageVide(), imgQR},
		apresFin: imgQR,
		delai:    20 * time.Millisecond,
	}

	var framesRecues atomic.Int32
	ctx, annuler := context.WithTimeout(context.Background(), 5*time.Second)
	defer annuler()

	chargeUtile, err := scannerAvecApercu(ctx, source, func(_ image.Image) {
		framesRecues.Add(1)
	})

	if err != nil {
		t.Fatalf("scannerAvecApercu: %v", err)
	}
	enveloppe, err := qr.LireChargeUtileQR(chargeUtile)
	if err != nil {
		t.Fatalf("LireChargeUtileQR: %v", err)
	}
	if enveloppe.Type != qr.TypeAppairagePC {
		t.Errorf("type enveloppe = %q, attendu %q", enveloppe.Type, qr.TypeAppairagePC)
	}
	if !bytes.Contains(enveloppe.Payload, []byte(pairingIdAttendu)) {
		t.Errorf("payload ne contient pas le pairing_id attendu")
	}
	if framesRecues.Load() < 1 {
		t.Errorf("aucune frame n'a ete envoyee au callback surFrame")
	}
	if !source.ferme.Load() {
		t.Error("la source n'a pas ete fermee a la fin")
	}
}

func TestScannerAvecApercu_AnnulationContexte(t *testing.T) {
	source := &sourceMock{
		frames:   []image.Image{imageVide()},
		apresFin: imageVide(),
		delai:    10 * time.Millisecond,
	}

	ctx, annuler := context.WithTimeout(context.Background(), 150*time.Millisecond)
	defer annuler()

	texte, err := scannerAvecApercu(ctx, source, nil)
	if err == nil {
		t.Fatalf("attendu une erreur d'annulation, recu texte=%q nil", texte)
	}
	if !errors.Is(err, context.DeadlineExceeded) && !errors.Is(err, context.Canceled) {
		t.Errorf("erreur = %v, attendu deadline/canceled", err)
	}
	if !source.ferme.Load() {
		t.Error("la source n'a pas ete fermee apres annulation")
	}
}

func TestScannerAvecApercu_ErreurSource(t *testing.T) {
	source := &sourceMock{
		erreur: errors.New("camera deconnectee"),
	}

	ctx, annuler := context.WithTimeout(context.Background(), 2*time.Second)
	defer annuler()

	_, err := scannerAvecApercu(ctx, source, nil)
	if err == nil {
		t.Fatal("attendu une erreur de source")
	}
	if err.Error() != "camera deconnectee" {
		t.Errorf("erreur = %v, attendu camera deconnectee", err)
	}
	if !source.ferme.Load() {
		t.Error("la source n'a pas ete fermee apres erreur")
	}
}
