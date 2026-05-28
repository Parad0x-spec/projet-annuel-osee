package main

import (
	"context"
	"image"
	"sync"
	"time"

	"projet_annuel/logiciel_pc_go/internal/qr"
)

const intervalleDecodage = 100 * time.Millisecond

func scannerAvecApercu(
	ctx context.Context,
	source qr.SourceFrames,
	surFrame func(image.Image),
) (string, error) {
	defer source.Fermer()

	ctxBoucle, annuler := context.WithCancel(ctx)
	defer annuler()

	var (
		mutexFrame    sync.Mutex
		derniereFrame image.Image
	)

	canalQR := make(chan string, 1)
	canalErreur := make(chan error, 1)

	go func() {
		for {
			if ctxBoucle.Err() != nil {
				return
			}
			img, err := source.LireFrame()
			if err != nil {
				select {
				case canalErreur <- err:
				default:
				}
				return
			}
			mutexFrame.Lock()
			derniereFrame = img
			mutexFrame.Unlock()
			if surFrame != nil {
				surFrame(img)
			}
		}
	}()

	go func() {
		ticker := time.NewTicker(intervalleDecodage)
		defer ticker.Stop()
		for {
			select {
			case <-ctxBoucle.Done():
				return
			case <-ticker.C:
				mutexFrame.Lock()
				frame := derniereFrame
				mutexFrame.Unlock()
				if frame == nil {
					continue
				}
				texte, err := decoderImageQR(frame)
				if err != nil {
					continue
				}
				select {
				case canalQR <- texte:
				default:
				}
				return
			}
		}
	}()

	select {
	case <-ctx.Done():
		return "", ctx.Err()
	case texte := <-canalQR:
		return texte, nil
	case err := <-canalErreur:
		return "", err
	}
}
