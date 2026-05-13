package main

import (
	"errors"
	"fmt"
	"image"

	"github.com/makiuchi-d/gozxing"
	"github.com/makiuchi-d/gozxing/qrcode"
)

var ErrQRIntrouvable = errors.New("scan: aucun QR detecte dans l'image")

func decoderImageQR(img image.Image) (string, error) {
	bitmap, err := gozxing.NewBinaryBitmapFromImage(img)
	if err != nil {
		return "", fmt.Errorf("scan: bitmap: %w", err)
	}
	lecteur := qrcode.NewQRCodeReader()
	resultat, err := lecteur.DecodeWithoutHints(bitmap)
	if err != nil {
		return "", fmt.Errorf("%w: %v", ErrQRIntrouvable, err)
	}
	return resultat.GetText(), nil
}
