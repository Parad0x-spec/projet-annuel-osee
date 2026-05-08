package crypto

import (
	"crypto/ed25519"
	"crypto/rand"
	"errors"
)

var ErrCleInvalide = errors.New("crypto: cle de taille invalide")

func GenererPaireDeCles() ([]byte, []byte, error) {
	clePublique, clePrivee, err := ed25519.GenerateKey(rand.Reader)
	if err != nil {
		return nil, nil, err
	}
	return []byte(clePrivee), []byte(clePublique), nil
}

func Signer(clePrivee []byte, message []byte) ([]byte, error) {
	if len(clePrivee) != ed25519.PrivateKeySize {
		return nil, ErrCleInvalide
	}
	return ed25519.Sign(ed25519.PrivateKey(clePrivee), message), nil
}

func Verifier(clePublique []byte, message []byte, signature []byte) bool {
	if len(clePublique) != ed25519.PublicKeySize {
		return false
	}
	if len(signature) != ed25519.SignatureSize {
		return false
	}
	return ed25519.Verify(ed25519.PublicKey(clePublique), message, signature)
}
