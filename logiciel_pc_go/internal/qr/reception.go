package qr

import (
	"bytes"
	"compress/zlib"
	"encoding/base64"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"strings"

	"projet_annuel/logiciel_pc_go/internal/crypto"
)

var (
	ErrChargeUtileIllisible = errors.New("qr: charge utile illisible")
	ErrTypeInattendu        = errors.New("qr: type de message inattendu")
	ErrVersionIncompatible  = errors.New("qr: version de protocole incompatible")
	ErrPayloadInvalide      = errors.New("qr: payload invalide")
	ErrSignatureInvalide    = errors.New("qr: signature invalide")
	ErrPairingIdNonReconnu  = errors.New("qr: pairing_id non reconnu")
)

type PayloadAppairageTablette struct {
	PairingId string `json:"pairing_id"`
	TabPub    string `json:"tab_pub"`
}

func LireChargeUtileQR(chargeUtileBase64 string) (Enveloppe, error) {
	donnees, err := decoderEtDecompresser(chargeUtileBase64)
	if err != nil {
		return Enveloppe{}, err
	}
	enveloppe, err := DeserialiserEnveloppe(donnees)
	if err != nil {
		return Enveloppe{}, fmt.Errorf("%w: %v", ErrChargeUtileIllisible, err)
	}
	return enveloppe, nil
}

func decoderEtDecompresser(chargeUtileBase64 string) ([]byte, error) {
	compresse, err := base64.StdEncoding.DecodeString(strings.TrimSpace(chargeUtileBase64))
	if err != nil {
		return nil, fmt.Errorf("%w: base64: %v", ErrChargeUtileIllisible, err)
	}
	lecteur, err := zlib.NewReader(bytes.NewReader(compresse))
	if err != nil {
		return nil, fmt.Errorf("%w: zlib: %v", ErrChargeUtileIllisible, err)
	}
	defer lecteur.Close()
	donnees, err := io.ReadAll(lecteur)
	if err != nil {
		return nil, fmt.Errorf("%w: decompression: %v", ErrChargeUtileIllisible, err)
	}
	return donnees, nil
}

func SerialiserPourSignature(enveloppe Enveloppe) ([]byte, error) {
	corps := struct {
		Type      string          `json:"type"`
		Version   int             `json:"version"`
		Timestamp string          `json:"timestamp"`
		Payload   json.RawMessage `json:"payload"`
	}{
		Type:      enveloppe.Type,
		Version:   enveloppe.Version,
		Timestamp: enveloppe.Timestamp,
		Payload:   enveloppe.Payload,
	}
	var tampon bytes.Buffer
	encodeur := json.NewEncoder(&tampon)
	encodeur.SetEscapeHTML(false)
	if err := encodeur.Encode(corps); err != nil {
		return nil, fmt.Errorf("qr: serialiser pour signature: %w", err)
	}
	return bytes.TrimRight(tampon.Bytes(), "\n"), nil
}

func VerifierAppairageTablette(enveloppe Enveloppe, pairingIdAttendu string) ([]byte, error) {
	if enveloppe.Type != TypeAppairageTablette {
		return nil, fmt.Errorf("%w: %q", ErrTypeInattendu, enveloppe.Type)
	}
	if enveloppe.Version != VersionProtocole {
		return nil, fmt.Errorf("%w: %d", ErrVersionIncompatible, enveloppe.Version)
	}
	var payload PayloadAppairageTablette
	if err := json.Unmarshal(enveloppe.Payload, &payload); err != nil {
		return nil, fmt.Errorf("%w: %v", ErrPayloadInvalide, err)
	}
	if payload.PairingId == "" || payload.TabPub == "" {
		return nil, fmt.Errorf("%w: champs obligatoires manquants", ErrPayloadInvalide)
	}
	clePubliqueTablette, err := base64.StdEncoding.DecodeString(payload.TabPub)
	if err != nil {
		return nil, fmt.Errorf("%w: tab_pub: %v", ErrPayloadInvalide, err)
	}
	signature, err := base64.StdEncoding.DecodeString(enveloppe.Signature)
	if err != nil {
		return nil, fmt.Errorf("%w: decodage: %v", ErrSignatureInvalide, err)
	}
	messageSigne, err := SerialiserPourSignature(enveloppe)
	if err != nil {
		return nil, err
	}
	if !crypto.Verifier(clePubliqueTablette, messageSigne, signature) {
		return nil, ErrSignatureInvalide
	}
	if payload.PairingId != pairingIdAttendu {
		return nil, fmt.Errorf("%w: attendu %q, recu %q", ErrPairingIdNonReconnu, pairingIdAttendu, payload.PairingId)
	}
	return clePubliqueTablette, nil
}
