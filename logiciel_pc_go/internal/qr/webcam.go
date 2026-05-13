package qr

import (
	"context"
	"errors"
	"fmt"
	"image"
	"image/draw"

	"github.com/pion/mediadevices"
	"github.com/pion/mediadevices/pkg/prop"

	_ "github.com/pion/mediadevices/pkg/driver/camera"
)

var (
	ErrCameraIndisponible = errors.New("qr: camera indisponible")
	ErrCaptureEchouee     = errors.New("qr: capture webcam echouee")
)

const (
	largeurCapture = 640
	hauteurCapture = 480
)

func CapturerFrame(ctx context.Context) (image.Image, error) {
	if err := ctx.Err(); err != nil {
		return nil, fmt.Errorf("%w: %v", ErrCaptureEchouee, err)
	}

	type resultat struct {
		image image.Image
		err   error
	}
	canal := make(chan resultat, 1)

	go func() {
		stream, err := mediadevices.GetUserMedia(mediadevices.MediaStreamConstraints{
			Video: func(contraintes *mediadevices.MediaTrackConstraints) {
				contraintes.Width = prop.Int(largeurCapture)
				contraintes.Height = prop.Int(hauteurCapture)
			},
		})
		if err != nil {
			canal <- resultat{nil, fmt.Errorf("%w: %v", ErrCameraIndisponible, err)}
			return
		}

		pistes := stream.GetVideoTracks()
		if len(pistes) == 0 {
			canal <- resultat{nil, ErrCameraIndisponible}
			return
		}

		pisteVideo, ok := pistes[0].(*mediadevices.VideoTrack)
		if !ok {
			canal <- resultat{nil, fmt.Errorf("%w: piste non video", ErrCaptureEchouee)}
			return
		}
		defer pisteVideo.Close()

		lecteur := pisteVideo.NewReader(false)
		source, liberer, err := lecteur.Read()
		if err != nil {
			canal <- resultat{nil, fmt.Errorf("%w: %v", ErrCaptureEchouee, err)}
			return
		}
		defer liberer()

		canal <- resultat{copierImage(source), nil}
	}()

	select {
	case <-ctx.Done():
		return nil, fmt.Errorf("%w: %v", ErrCaptureEchouee, ctx.Err())
	case res := <-canal:
		return res.image, res.err
	}
}

func copierImage(source image.Image) image.Image {
	bornes := source.Bounds()
	destination := image.NewRGBA(bornes)
	draw.Draw(destination, bornes, source, bornes.Min, draw.Src)
	return destination
}
