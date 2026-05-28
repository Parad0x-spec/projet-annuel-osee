package qr

import (
	"context"
	"errors"
	"fmt"
	"image"
	"image/draw"

	"github.com/pion/mediadevices"
	"github.com/pion/mediadevices/pkg/io/video"
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

type SourceFrames interface {
	LireFrame() (image.Image, error)
	Fermer() error
}

type SessionCapture struct {
	stream  mediadevices.MediaStream
	piste   *mediadevices.VideoTrack
	lecteur video.Reader
}

func OuvrirSessionCapture(ctx context.Context) (*SessionCapture, error) {
	if err := ctx.Err(); err != nil {
		return nil, fmt.Errorf("%w: %v", ErrCaptureEchouee, err)
	}

	type resultat struct {
		session *SessionCapture
		err     error
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
		piste, ok := pistes[0].(*mediadevices.VideoTrack)
		if !ok {
			canal <- resultat{nil, fmt.Errorf("%w: piste non video", ErrCaptureEchouee)}
			return
		}
		canal <- resultat{
			session: &SessionCapture{
				stream:  stream,
				piste:   piste,
				lecteur: piste.NewReader(false),
			},
		}
	}()

	select {
	case <-ctx.Done():
		return nil, fmt.Errorf("%w: %v", ErrCaptureEchouee, ctx.Err())
	case r := <-canal:
		return r.session, r.err
	}
}

func (s *SessionCapture) LireFrame() (image.Image, error) {
	source, liberer, err := s.lecteur.Read()
	if err != nil {
		return nil, fmt.Errorf("%w: %v", ErrCaptureEchouee, err)
	}
	defer liberer()
	return copierImage(source), nil
}

func (s *SessionCapture) Fermer() error {
	if s.piste != nil {
		return s.piste.Close()
	}
	return nil
}

func copierImage(source image.Image) image.Image {
	bornes := source.Bounds()
	destination := image.NewRGBA(bornes)
	draw.Draw(destination, bornes, source, bornes.Min, draw.Src)
	return destination
}
