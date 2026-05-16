package main

import (
	"bytes"
	"context"
	"errors"
	"fmt"
	"image/png"
	"time"

	"fyne.io/fyne/v2"
	"fyne.io/fyne/v2/canvas"
	"fyne.io/fyne/v2/container"
	"fyne.io/fyne/v2/widget"

	"projet_annuel/logiciel_pc_go/internal/qr"
)

const (
	titreFenetreQR   = "QR d'appairage PC"
	tailleQRAffichee = float32(500)
	delaiCaptureMax  = 10 * time.Second
)

func ouvrirFenetreQR(logiciel fyne.App, session *sessionAppairage) error {
	_, pngQR, pairingId, err := qr.GenererQRAppairage(session.clePubliquePC)
	if err != nil {
		return err
	}
	session.memoriserPairingId(pairingId)

	imageQR, err := png.Decode(bytes.NewReader(pngQR))
	if err != nil {
		return fmt.Errorf("decodage png QR : %w", err)
	}

	canvasQR := canvas.NewImageFromImage(imageQR)
	canvasQR.FillMode = canvas.ImageFillContain
	canvasQR.SetMinSize(fyne.NewSize(tailleQRAffichee, tailleQRAffichee))

	fenetreQR := logiciel.NewWindow(titreFenetreQR)
	fenetreQR.SetContent(container.NewVBox(
		widget.NewLabel(fmt.Sprintf("pairing_id : %s", pairingId)),
		canvasQR,
		widget.NewLabel("Scannez ce QR depuis la tablette."),
	))
	fenetreQR.Resize(fyne.NewSize(tailleQRAffichee+40, tailleQRAffichee+120))
	fenetreQR.Show()
	return nil
}

func scannerEtVerifier(session *sessionAppairage) string {
	pairingIdAttendu := session.lirePairingId()
	if pairingIdAttendu == "" {
		return "Generez d'abord un QR PC."
	}

	ctx, annuler := context.WithTimeout(context.Background(), delaiCaptureMax)
	defer annuler()

	frame, err := qr.CapturerFrame(ctx)
	if err != nil {
		return messageErreurCapture(err)
	}

	chargeUtile, err := decoderImageQR(frame)
	if err != nil {
		return "QR illisible. Reessayez."
	}

	enveloppe, err := qr.LireChargeUtileQR(chargeUtile)
	if err != nil {
		return messageErreurVerification(err)
	}

	if _, err := qr.VerifierAppairageTablette(enveloppe, pairingIdAttendu); err != nil {
		return messageErreurVerification(err)
	}

	return "Appairage confirme et signature verifiee."
}

func messageErreurCapture(err error) string {
	switch {
	case errors.Is(err, qr.ErrCameraIndisponible):
		return "Aucune camera detectee. Verifiez le branchement et reessayez."
	case errors.Is(err, qr.ErrCaptureEchouee):
		return "La capture a echoue. Reessayez."
	default:
		return "La capture a echoue. Reessayez."
	}
}

func messageErreurVerification(err error) string {
	switch {
	case errors.Is(err, qr.ErrSignatureInvalide):
		return "Signature invalide. L'appairage a peut-etre ete perdu."
	case errors.Is(err, qr.ErrTypeInattendu), errors.Is(err, qr.ErrVersionIncompatible):
		return "QR non reconnu. Versions incompatibles."
	case errors.Is(err, qr.ErrPairingIdNonReconnu):
		return "Appairage non reconnu. Generez un nouveau QR PC et reessayez."
	case errors.Is(err, qr.ErrChargeUtileIllisible), errors.Is(err, qr.ErrPayloadInvalide):
		return "QR illisible. Reessayez."
	default:
		return "QR illisible. Reessayez."
	}
}
