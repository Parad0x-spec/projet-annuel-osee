package qr

import (
	"context"
	"image"
	"os"
	"testing"
	"time"
)

func TestCapturerFrame_SignatureExportee(t *testing.T) {
	var _ func(context.Context) (image.Image, error) = CapturerFrame
}

func TestCapturerFrame_AvecMaterielReel(t *testing.T) {
	if os.Getenv("WEBCAM_AVAILABLE") == "" {
		t.Skip("WEBCAM_AVAILABLE non defini, test materiel ignore")
	}

	ctx, annuler := context.WithTimeout(context.Background(), 10*time.Second)
	defer annuler()

	img, err := CapturerFrame(ctx)
	if err != nil {
		t.Fatalf("CapturerFrame: %v", err)
	}
	if img == nil {
		t.Fatal("image retournee nil")
	}
	bornes := img.Bounds()
	if bornes.Dx() == 0 || bornes.Dy() == 0 {
		t.Errorf("bornes inattendues: %v", bornes)
	}
}

func TestCapturerFrame_ContexteAnnuleAvantAppel(t *testing.T) {
	ctx, annuler := context.WithCancel(context.Background())
	annuler()

	_, err := CapturerFrame(ctx)
	if err == nil {
		t.Fatal("attendu une erreur sur contexte deja annule")
	}
}
