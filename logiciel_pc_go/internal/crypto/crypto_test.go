package crypto

import (
	"crypto/ed25519"
	"errors"
	"testing"
)

func TestGenererPaireDeCles_TaillesAttendues(t *testing.T) {
	clePrivee, clePublique, err := GenererPaireDeCles()
	if err != nil {
		t.Fatalf("erreur inattendue: %v", err)
	}
	if len(clePrivee) != ed25519.PrivateKeySize {
		t.Errorf("taille cle privee = %d, attendu %d", len(clePrivee), ed25519.PrivateKeySize)
	}
	if len(clePublique) != ed25519.PublicKeySize {
		t.Errorf("taille cle publique = %d, attendu %d", len(clePublique), ed25519.PublicKeySize)
	}
}

func TestSignerEtVerifier_Succes(t *testing.T) {
	clePrivee, clePublique, err := GenererPaireDeCles()
	if err != nil {
		t.Fatalf("generation cles: %v", err)
	}
	message := []byte("message de test")

	signature, err := Signer(clePrivee, message)
	if err != nil {
		t.Fatalf("signature: %v", err)
	}
	if len(signature) != ed25519.SignatureSize {
		t.Errorf("taille signature = %d, attendu %d", len(signature), ed25519.SignatureSize)
	}
	if !Verifier(clePublique, message, signature) {
		t.Error("la signature valide a ete rejetee")
	}
}

func TestVerifier_RejetSignatureCorrompue(t *testing.T) {
	clePrivee, clePublique, err := GenererPaireDeCles()
	if err != nil {
		t.Fatalf("generation cles: %v", err)
	}
	message := []byte("message de test")

	signature, err := Signer(clePrivee, message)
	if err != nil {
		t.Fatalf("signature: %v", err)
	}
	signature[0] ^= 0xFF
	if Verifier(clePublique, message, signature) {
		t.Error("une signature corrompue a ete acceptee")
	}
}

func TestVerifier_RejetClePubliqueDifferente(t *testing.T) {
	clePrivee, _, err := GenererPaireDeCles()
	if err != nil {
		t.Fatalf("generation premiere paire: %v", err)
	}
	_, autreClePublique, err := GenererPaireDeCles()
	if err != nil {
		t.Fatalf("generation deuxieme paire: %v", err)
	}
	message := []byte("message de test")

	signature, err := Signer(clePrivee, message)
	if err != nil {
		t.Fatalf("signature: %v", err)
	}
	if Verifier(autreClePublique, message, signature) {
		t.Error("une signature a ete validee avec la mauvaise cle publique")
	}
}

func TestVerifier_RejetMessageDifferent(t *testing.T) {
	clePrivee, clePublique, err := GenererPaireDeCles()
	if err != nil {
		t.Fatalf("generation cles: %v", err)
	}
	messageOriginal := []byte("message original")
	messageDifferent := []byte("message different")

	signature, err := Signer(clePrivee, messageOriginal)
	if err != nil {
		t.Fatalf("signature: %v", err)
	}
	if Verifier(clePublique, messageDifferent, signature) {
		t.Error("une signature a ete validee avec un message different")
	}
}

func TestSigner_RejetClePriveeMalformee(t *testing.T) {
	cleTropPetite := make([]byte, 16)
	_, err := Signer(cleTropPetite, []byte("test"))
	if err == nil {
		t.Fatal("Signer aurait du echouer sur une cle malformee")
	}
	if !errors.Is(err, ErrCleInvalide) {
		t.Errorf("erreur attendue ErrCleInvalide, obtenue %v", err)
	}
}

func TestVerifier_RejetClePubliqueMalformee(t *testing.T) {
	clePrivee, _, err := GenererPaireDeCles()
	if err != nil {
		t.Fatalf("generation cles: %v", err)
	}
	signature, err := Signer(clePrivee, []byte("test"))
	if err != nil {
		t.Fatalf("signature: %v", err)
	}
	cleTropPetite := make([]byte, 16)
	if Verifier(cleTropPetite, []byte("test"), signature) {
		t.Error("Verifier aurait du rejeter une cle publique malformee")
	}
}
