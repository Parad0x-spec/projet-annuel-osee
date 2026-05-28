package main

import (
	"context"
	"errors"
	"image"
	"image/color"

	"fyne.io/fyne/v2"
	"fyne.io/fyne/v2/canvas"
	"fyne.io/fyne/v2/container"
	"fyne.io/fyne/v2/widget"

	"projet_annuel/logiciel_pc_go/internal/qr"
)

const (
	titreFenetreScan      = "Scan du QR tablette"
	largeurFenetreScan    = float32(720)
	hauteurFenetreScan    = float32(620)
	largeurApercuScan     = float32(640)
	hauteurApercuScan     = float32(480)
	consigneApercuScan    = "Présentez le QR de la tablette devant la webcam."
	messageAucuneCamera   = "Aucune caméra détectée. Vérifiez le branchement."
	messageCaptureEchouee = "Capture échouée. Réessayez."
	messageContexteAnnule = "Scan annulé."
)

func ouvrirFenetreScan(logiciel fyne.App, surChargeUtile func(string)) {
	fenetre := logiciel.NewWindow(titreFenetreScan)

	frameInitiale := image.NewRGBA(image.Rect(0, 0, int(largeurApercuScan), int(hauteurApercuScan)))
	gris := color.RGBA{R: 32, G: 32, B: 32, A: 255}
	for y := 0; y < frameInitiale.Rect.Dy(); y++ {
		for x := 0; x < frameInitiale.Rect.Dx(); x++ {
			frameInitiale.SetRGBA(x, y, gris)
		}
	}
	canvasApercu := canvas.NewImageFromImage(frameInitiale)
	canvasApercu.FillMode = canvas.ImageFillContain
	canvasApercu.SetMinSize(fyne.NewSize(largeurApercuScan, hauteurApercuScan))

	statut := widget.NewLabel(consigneApercuScan)
	statut.Alignment = fyne.TextAlignCenter

	ctx, annuler := context.WithCancel(context.Background())

	fermerProprement := func() {
		annuler()
		fenetre.Close()
	}

	boutonAnnuler := widget.NewButton("Annuler", fermerProprement)

	fenetre.SetCloseIntercept(fermerProprement)
	fenetre.SetContent(container.NewBorder(
		statut,
		container.NewCenter(boutonAnnuler),
		nil,
		nil,
		container.NewCenter(canvasApercu),
	))
	fenetre.Resize(fyne.NewSize(largeurFenetreScan, hauteurFenetreScan))
	fenetre.Show()

	go func() {
		session, err := qr.OuvrirSessionCapture(ctx)
		if err != nil {
			fyne.Do(func() {
				statut.SetText(messageAucuneCamera)
			})
			return
		}
		chargeUtile, err := scannerAvecApercu(ctx, session, func(img image.Image) {
			fyne.Do(func() {
				canvasApercu.Image = img
				canvasApercu.Refresh()
			})
		})
		switch {
		case err == nil:
			fyne.Do(func() {
				fenetre.Close()
			})
			surChargeUtile(chargeUtile)
		case errors.Is(err, context.Canceled), errors.Is(err, context.DeadlineExceeded):
			fyne.Do(func() {
				statut.SetText(messageContexteAnnule)
			})
		default:
			fyne.Do(func() {
				statut.SetText(messageCaptureEchouee)
			})
		}
	}()
}
