package qr

import (
	"context"
	"errors"
	"image"
	"os"
	"testing"
	"time"
)

func TestSessionCapture_Implemente_SourceFrames(t *testing.T) {
	var _ SourceFrames = (*SessionCapture)(nil)
}

func TestOuvrirSessionCapture_SignatureExportee(t *testing.T) {
	var _ func(context.Context) (*SessionCapture, error) = OuvrirSessionCapture
	var _ func() (image.Image, error) = (&SessionCapture{}).LireFrame
	var _ func() error = (&SessionCapture{}).Fermer
}

func TestOuvrirSessionCapture_ContexteAnnuleAvantAppel(t *testing.T) {
	ctx, annuler := context.WithCancel(context.Background())
	annuler()

	_, err := OuvrirSessionCapture(ctx)
	if err == nil {
		t.Fatal("attendu une erreur sur contexte deja annule")
	}
	if !errors.Is(err, ErrCaptureEchouee) {
		t.Errorf("erreur = %v, attendu ErrCaptureEchouee", err)
	}
}

func TestSessionCapture_AvecMaterielReel(t *testing.T) {
	if os.Getenv("WEBCAM_AVAILABLE") == "" {
		t.Skip("WEBCAM_AVAILABLE non defini, test materiel ignore")
	}

	ctx, annuler := context.WithTimeout(context.Background(), 10*time.Second)
	defer annuler()

	session, err := OuvrirSessionCapture(ctx)
	if err != nil {
		t.Fatalf("OuvrirSessionCapture: %v", err)
	}
	defer session.Fermer()

	for i := 0; i < 5; i++ {
		img, err := session.LireFrame()
		if err != nil {
			t.Fatalf("LireFrame %d: %v", i, err)
		}
		if img == nil {
			t.Fatalf("LireFrame %d : image nil", i)
		}
		bornes := img.Bounds()
		if bornes.Dx() == 0 || bornes.Dy() == 0 {
			t.Errorf("LireFrame %d : bornes inattendues: %v", i, bornes)
		}
	}
}
