package qr

import (
	"bytes"
	"compress/zlib"
	"encoding/base64"
	"encoding/json"
	"fmt"
	"time"

	"github.com/google/uuid"
	qrcode "github.com/skip2/go-qrcode"

	"projet_annuel/logiciel_pc_go/internal/crypto"
)

const (
	TypeAppairagePC       = "appairage_pc"
	TypeAppairageTablette = "appairage_tablette"
	TypeCreationPatient   = "creation_patient"
	TypeSession           = "session"
	VersionProtocole      = 3
	tailleQRPixels        = 512
)

type Enveloppe struct {
	Type      string          `json:"type"`
	Version   int             `json:"version"`
	Timestamp string          `json:"timestamp"`
	Payload   json.RawMessage `json:"payload"`
	Signature string          `json:"signature"`
}

type PayloadAppairagePC struct {
	PairingId string `json:"pairing_id"`
	PcPub     string `json:"pc_pub"`
}

type PayloadCreationPatient struct {
	PatientID        string `json:"patient_id"`
	PatientInitiales string `json:"patient_initiales"`
	NiveauDemande    int    `json:"niveau_demande"`
}

func SerialiserCanonique(enveloppe Enveloppe) ([]byte, error) {
	var tampon bytes.Buffer
	encodeur := json.NewEncoder(&tampon)
	encodeur.SetEscapeHTML(false)
	if err := encodeur.Encode(enveloppe); err != nil {
		return nil, fmt.Errorf("qr: serialiser enveloppe: %w", err)
	}
	return bytes.TrimRight(tampon.Bytes(), "\n"), nil
}

func DeserialiserEnveloppe(donnees []byte) (Enveloppe, error) {
	var enveloppe Enveloppe
	if err := json.Unmarshal(donnees, &enveloppe); err != nil {
		return Enveloppe{}, fmt.Errorf("qr: deserialiser enveloppe: %w", err)
	}
	return enveloppe, nil
}

func GenererQRAppairage(clePubliquePC []byte) ([]byte, []byte, string, error) {
	return GenererQRAppairageAvecPairingId(clePubliquePC, uuid.NewString())
}

func GenererQRAppairageAvecPairingId(clePubliquePC []byte, pairingId string) ([]byte, []byte, string, error) {
	payload := PayloadAppairagePC{
		PairingId: pairingId,
		PcPub:     base64.StdEncoding.EncodeToString(clePubliquePC),
	}
	payloadJSON, err := json.Marshal(payload)
	if err != nil {
		return nil, nil, "", fmt.Errorf("qr: serialiser payload: %w", err)
	}

	enveloppe := Enveloppe{
		Type:      TypeAppairagePC,
		Version:   VersionProtocole,
		Timestamp: time.Now().UTC().Format(time.RFC3339),
		Payload:   payloadJSON,
		Signature: "",
	}

	enveloppeJSON, err := SerialiserCanonique(enveloppe)
	if err != nil {
		return nil, nil, "", err
	}

	chargeUtileQR, err := compresserEtEncoder(enveloppeJSON)
	if err != nil {
		return nil, nil, "", err
	}

	pngQR, err := qrcode.Encode(chargeUtileQR, qrcode.Medium, tailleQRPixels)
	if err != nil {
		return nil, nil, "", fmt.Errorf("qr: encoder png: %w", err)
	}

	return enveloppeJSON, pngQR, pairingId, nil
}

func GenererQRCreationPatient(clePriveePC []byte, patientID string, patientInitiales string, niveauDemande int) ([]byte, []byte, error) {
	if niveauDemande < 1 || niveauDemande > 5 {
		return nil, nil, fmt.Errorf("%w: %d", ErrNiveauHorsPlage, niveauDemande)
	}
	if patientID == "" {
		return nil, nil, fmt.Errorf("%w: vide", ErrPatientIDInvalide)
	}
	if patientInitiales == "" {
		return nil, nil, fmt.Errorf("%w: vide", ErrInitialesInvalides)
	}

	payload := PayloadCreationPatient{
		PatientID:        patientID,
		PatientInitiales: patientInitiales,
		NiveauDemande:    niveauDemande,
	}
	payloadJSON, err := json.Marshal(payload)
	if err != nil {
		return nil, nil, fmt.Errorf("qr: serialiser payload creation_patient: %w", err)
	}

	enveloppe := Enveloppe{
		Type:      TypeCreationPatient,
		Version:   VersionProtocole,
		Timestamp: time.Now().UTC().Format(time.RFC3339),
		Payload:   payloadJSON,
		Signature: "",
	}

	messageSigne, err := SerialiserPourSignature(enveloppe)
	if err != nil {
		return nil, nil, err
	}
	signature, err := crypto.Signer(clePriveePC, messageSigne)
	if err != nil {
		return nil, nil, fmt.Errorf("qr: signer creation_patient: %w", err)
	}
	enveloppe.Signature = base64.StdEncoding.EncodeToString(signature)

	enveloppeJSON, err := SerialiserCanonique(enveloppe)
	if err != nil {
		return nil, nil, err
	}

	chargeUtileQR, err := compresserEtEncoder(enveloppeJSON)
	if err != nil {
		return nil, nil, err
	}

	pngQR, err := qrcode.Encode(chargeUtileQR, qrcode.Medium, tailleQRPixels)
	if err != nil {
		return nil, nil, fmt.Errorf("qr: encoder png: %w", err)
	}

	return enveloppeJSON, pngQR, nil
}

func compresserEtEncoder(donnees []byte) (string, error) {
	var compresse bytes.Buffer
	zlibWriter := zlib.NewWriter(&compresse)
	if _, err := zlibWriter.Write(donnees); err != nil {
		return "", fmt.Errorf("qr: compresser zlib: %w", err)
	}
	if err := zlibWriter.Close(); err != nil {
		return "", fmt.Errorf("qr: fermer zlib: %w", err)
	}
	return base64.StdEncoding.EncodeToString(compresse.Bytes()), nil
}
