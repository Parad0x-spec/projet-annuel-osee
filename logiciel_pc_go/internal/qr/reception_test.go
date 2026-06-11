package qr

import (
	"bytes"
	"crypto/ed25519"
	"crypto/rand"
	"encoding/base64"
	"encoding/json"
	"errors"
	"fmt"
	"testing"

	"github.com/google/uuid"
)

func genererPaireEd25519DeTest(t *testing.T) (clePrivee, clePublique []byte) {
	t.Helper()
	publique, privee, err := ed25519.GenerateKey(rand.Reader)
	if err != nil {
		t.Fatalf("generation cles: %v", err)
	}
	return []byte(privee), []byte(publique)
}

func construireChargeUtileAppairageTablette(t *testing.T, pairingId string, tabPub, tabPriv []byte, timestamp string) string {
	t.Helper()
	payloadJSON := fmt.Sprintf(`{"pairing_id":%q,"tab_pub":%q}`, pairingId, base64.StdEncoding.EncodeToString(tabPub))
	messageSigne := fmt.Sprintf(`{"type":%q,"version":%d,"timestamp":%q,"payload":%s}`,
		TypeAppairageTablette, VersionProtocole, timestamp, payloadJSON)
	signature := ed25519.Sign(ed25519.PrivateKey(tabPriv), []byte(messageSigne))
	enveloppeJSON := fmt.Sprintf(`{"type":%q,"version":%d,"timestamp":%q,"payload":%s,"signature":%q}`,
		TypeAppairageTablette, VersionProtocole, timestamp, payloadJSON, base64.StdEncoding.EncodeToString(signature))
	chargeUtile, err := compresserEtEncoder([]byte(enveloppeJSON))
	if err != nil {
		t.Fatalf("compresser charge utile: %v", err)
	}
	return chargeUtile
}

const planchesValidesJSON = `[{"numero_planche":1,"score_global":82,"resultats_par_emotion":[` +
	`{"emotion":"joie","nb_cibles_total":3,"nb_cibles_trouvees":3,"nb_faux_positifs":0,"score":100,"evaluee":true},` +
	`{"emotion":"colere","nb_cibles_total":2,"nb_cibles_trouvees":1,"nb_faux_positifs":1,"score":45,"evaluee":true},` +
	`{"emotion":"tristesse","nb_cibles_total":0,"nb_cibles_trouvees":0,"nb_faux_positifs":0,"score":0,"evaluee":false},` +
	`{"emotion":"peur","nb_cibles_total":1,"nb_cibles_trouvees":1,"nb_faux_positifs":0,"score":100,"evaluee":true}]}]`

func construireChargeUtileSession(t *testing.T, patientID, initiales, sessionDate, jeuType string, niveau int, tabPriv []byte, timestamp string) string {
	t.Helper()
	payloadJSON := fmt.Sprintf(
		`{"patient_id":%q,"patient_initiales":%q,"session_date":%q,"jeu_type":%q,"niveau":%d,"planches":%s}`,
		patientID, initiales, sessionDate, jeuType, niveau, planchesValidesJSON)
	return signerEtEncoderPayloadSession(t, payloadJSON, tabPriv, timestamp)
}

func signerEtEncoderPayloadSession(t *testing.T, payloadJSON string, tabPriv []byte, timestamp string) string {
	t.Helper()
	messageSigne := fmt.Sprintf(`{"type":%q,"version":%d,"timestamp":%q,"payload":%s}`,
		TypeSession, VersionProtocole, timestamp, payloadJSON)
	signature := ed25519.Sign(ed25519.PrivateKey(tabPriv), []byte(messageSigne))
	enveloppeJSON := fmt.Sprintf(`{"type":%q,"version":%d,"timestamp":%q,"payload":%s,"signature":%q}`,
		TypeSession, VersionProtocole, timestamp, payloadJSON, base64.StdEncoding.EncodeToString(signature))
	chargeUtile, err := compresserEtEncoder([]byte(enveloppeJSON))
	if err != nil {
		t.Fatalf("compresser charge utile: %v", err)
	}
	return chargeUtile
}

func TestVerifierSession_Succes(t *testing.T) {
	tabPriv, tabPub := genererPaireEd25519DeTest(t)
	chargeUtile := construireChargeUtileSession(t, "id-123", "MD", "2026-05-25T10:00:00.000Z", "emotions", 3, tabPriv, "2026-05-25T10:00:05.000Z")
	enveloppe, err := LireChargeUtileQR(chargeUtile)
	if err != nil {
		t.Fatalf("LireChargeUtileQR: %v", err)
	}

	payload, err := VerifierSession(enveloppe, tabPub)
	if err != nil {
		t.Fatalf("VerifierSession: %v", err)
	}
	if payload.PatientID != "id-123" || payload.PatientInitiales != "MD" {
		t.Errorf("payload = %+v", payload)
	}
	if payload.JeuType != "emotions" || payload.Niveau != 3 {
		t.Errorf("jeu_type/niveau = %q/%d", payload.JeuType, payload.Niveau)
	}
	if len(payload.Planches) != 1 {
		t.Fatalf("planches = %d, attendu 1", len(payload.Planches))
	}
	planche := payload.Planches[0]
	if planche.NumeroPlanche != 1 || planche.ScoreGlobal != 82 {
		t.Errorf("planche = %+v", planche)
	}
	if len(planche.ResultatsParEmotion) != 4 {
		t.Fatalf("resultats_par_emotion = %d, attendu 4", len(planche.ResultatsParEmotion))
	}
	joie := planche.ResultatsParEmotion[0]
	if joie.Emotion != "joie" || joie.NbCiblesTotal != 3 || joie.NbCiblesTrouvees != 3 || joie.Score != 100 || !joie.Evaluee {
		t.Errorf("resultat joie = %+v", joie)
	}
	tristesse := planche.ResultatsParEmotion[2]
	if tristesse.Emotion != "tristesse" || tristesse.Evaluee {
		t.Errorf("resultat tristesse = %+v, attendu evaluee=false", tristesse)
	}
}

func TestVerifierSession_AncienFormatManchesRejete(t *testing.T) {
	tabPriv, tabPub := genererPaireEd25519DeTest(t)
	payloadJSON := `{"patient_id":"id-123","patient_initiales":"MD","session_date":"2026-05-25T10:00:00.000Z","jeu_type":"emotions","niveau":3,"manches":[]}`
	chargeUtile := signerEtEncoderPayloadSession(t, payloadJSON, tabPriv, "2026-05-25T10:00:05.000Z")
	enveloppe, err := LireChargeUtileQR(chargeUtile)
	if err != nil {
		t.Fatalf("LireChargeUtileQR: %v", err)
	}
	if _, err := VerifierSession(enveloppe, tabPub); !errors.Is(err, ErrPayloadInvalide) {
		t.Errorf("erreur = %v, attendu ErrPayloadInvalide pour ancien format manches", err)
	}
}

func TestVerifierSession_EmotionInconnueRejetee(t *testing.T) {
	tabPriv, tabPub := genererPaireEd25519DeTest(t)
	payloadJSON := `{"patient_id":"id-123","patient_initiales":"MD","session_date":"2026-05-25T10:00:00.000Z","jeu_type":"emotions","niveau":3,` +
		`"planches":[{"numero_planche":1,"score_global":50,"resultats_par_emotion":[{"emotion":"degout","nb_cibles_total":1,"nb_cibles_trouvees":1,"nb_faux_positifs":0,"score":100,"evaluee":true}]}]}`
	chargeUtile := signerEtEncoderPayloadSession(t, payloadJSON, tabPriv, "2026-05-25T10:00:05.000Z")
	enveloppe, err := LireChargeUtileQR(chargeUtile)
	if err != nil {
		t.Fatalf("LireChargeUtileQR: %v", err)
	}
	if _, err := VerifierSession(enveloppe, tabPub); !errors.Is(err, ErrPayloadInvalide) {
		t.Errorf("erreur = %v, attendu ErrPayloadInvalide pour emotion inconnue", err)
	}
}

func TestVerifierSession_SignatureMauvaiseCle(t *testing.T) {
	_, tabPub := genererPaireEd25519DeTest(t)
	autrePriv, _ := genererPaireEd25519DeTest(t)
	chargeUtile := construireChargeUtileSession(t, "id-123", "MD", "2026-05-25T10:00:00.000Z", "emotions", 3, autrePriv, "2026-05-25T10:00:05.000Z")
	enveloppe, err := LireChargeUtileQR(chargeUtile)
	if err != nil {
		t.Fatalf("LireChargeUtileQR: %v", err)
	}
	if _, err := VerifierSession(enveloppe, tabPub); !errors.Is(err, ErrSignatureInvalide) {
		t.Errorf("erreur = %v, attendu ErrSignatureInvalide", err)
	}
}

func TestVerifierSession_TypeInattendu(t *testing.T) {
	tabPriv, tabPub := genererPaireEd25519DeTest(t)
	chargeUtile := construireChargeUtileSession(t, "id-123", "MD", "2026-05-25T10:00:00.000Z", "emotions", 3, tabPriv, "2026-05-25T10:00:05.000Z")
	enveloppe, err := LireChargeUtileQR(chargeUtile)
	if err != nil {
		t.Fatalf("LireChargeUtileQR: %v", err)
	}
	enveloppe.Type = TypeAppairageTablette
	if _, err := VerifierSession(enveloppe, tabPub); !errors.Is(err, ErrTypeInattendu) {
		t.Errorf("erreur = %v, attendu ErrTypeInattendu", err)
	}
}

func TestVerifierSession_VersionIncompatible(t *testing.T) {
	tabPriv, tabPub := genererPaireEd25519DeTest(t)
	chargeUtile := construireChargeUtileSession(t, "id-123", "MD", "2026-05-25T10:00:00.000Z", "emotions", 3, tabPriv, "2026-05-25T10:00:05.000Z")
	enveloppe, err := LireChargeUtileQR(chargeUtile)
	if err != nil {
		t.Fatalf("LireChargeUtileQR: %v", err)
	}
	enveloppe.Version = 1
	if _, err := VerifierSession(enveloppe, tabPub); !errors.Is(err, ErrVersionIncompatible) {
		t.Errorf("erreur = %v, attendu ErrVersionIncompatible", err)
	}
}

func TestVerifierSession_PayloadSansPatientID(t *testing.T) {
	tabPriv, tabPub := genererPaireEd25519DeTest(t)
	chargeUtile := construireChargeUtileSession(t, "", "MD", "2026-05-25T10:00:00.000Z", "emotions", 3, tabPriv, "2026-05-25T10:00:05.000Z")
	enveloppe, err := LireChargeUtileQR(chargeUtile)
	if err != nil {
		t.Fatalf("LireChargeUtileQR: %v", err)
	}
	if _, err := VerifierSession(enveloppe, tabPub); !errors.Is(err, ErrPayloadInvalide) {
		t.Errorf("erreur = %v, attendu ErrPayloadInvalide", err)
	}
}

func TestLireChargeUtileQR_RoundTrip(t *testing.T) {
	tabPriv, tabPub := genererPaireEd25519DeTest(t)
	pairingId := uuid.NewString()
	chargeUtile := construireChargeUtileAppairageTablette(t, pairingId, tabPub, tabPriv, "2026-05-11T10:00:00.000000Z")

	enveloppe, err := LireChargeUtileQR(chargeUtile)
	if err != nil {
		t.Fatalf("LireChargeUtileQR: %v", err)
	}
	if enveloppe.Type != TypeAppairageTablette {
		t.Errorf("type = %q, attendu %q", enveloppe.Type, TypeAppairageTablette)
	}
	if enveloppe.Version != VersionProtocole {
		t.Errorf("version = %d, attendu %d", enveloppe.Version, VersionProtocole)
	}
	if enveloppe.Timestamp != "2026-05-11T10:00:00.000000Z" {
		t.Errorf("timestamp = %q", enveloppe.Timestamp)
	}
	var payload PayloadAppairageTablette
	if err := json.Unmarshal(enveloppe.Payload, &payload); err != nil {
		t.Fatalf("unmarshal payload: %v", err)
	}
	if payload.PairingId != pairingId {
		t.Errorf("pairing_id = %q, attendu %q", payload.PairingId, pairingId)
	}
	if payload.TabPub == "" {
		t.Error("tab_pub vide")
	}
}

func TestLireChargeUtileQR_Base64Corrompu(t *testing.T) {
	_, err := LireChargeUtileQR("ceci n'est pas du base64 !!!")
	if !errors.Is(err, ErrChargeUtileIllisible) {
		t.Errorf("erreur = %v, attendu ErrChargeUtileIllisible", err)
	}
}

func TestLireChargeUtileQR_ZlibCorrompu(t *testing.T) {
	chargeUtile := base64.StdEncoding.EncodeToString([]byte("contenu qui n'est pas du zlib"))
	_, err := LireChargeUtileQR(chargeUtile)
	if !errors.Is(err, ErrChargeUtileIllisible) {
		t.Errorf("erreur = %v, attendu ErrChargeUtileIllisible", err)
	}
}

func TestLireChargeUtileQR_JSONInvalide(t *testing.T) {
	chargeUtile, err := compresserEtEncoder([]byte("{ ceci n'est pas du json"))
	if err != nil {
		t.Fatalf("compresser: %v", err)
	}
	_, err = LireChargeUtileQR(chargeUtile)
	if !errors.Is(err, ErrChargeUtileIllisible) {
		t.Errorf("erreur = %v, attendu ErrChargeUtileIllisible", err)
	}
}

func TestSerialiserPourSignature_FormatCompactStable(t *testing.T) {
	enveloppe := Enveloppe{
		Type:      TypeAppairageTablette,
		Version:   VersionProtocole,
		Timestamp: "2026-05-11T10:00:00.000000Z",
		Payload:   json.RawMessage(`{"pairing_id":"abc","tab_pub":"ZGVm"}`),
		Signature: "doit-etre-ignoree",
	}
	attendu := `{"type":"appairage_tablette","version":3,"timestamp":"2026-05-11T10:00:00.000000Z","payload":{"pairing_id":"abc","tab_pub":"ZGVm"}}`

	obtenu, err := SerialiserPourSignature(enveloppe)
	if err != nil {
		t.Fatalf("SerialiserPourSignature: %v", err)
	}
	if string(obtenu) != attendu {
		t.Errorf("serialisation:\nobtenu  : %s\nattendu : %s", obtenu, attendu)
	}

	secondeSortie, err := SerialiserPourSignature(enveloppe)
	if err != nil {
		t.Fatal(err)
	}
	if !bytes.Equal(obtenu, secondeSortie) {
		t.Error("serialisation pour signature non stable")
	}
}

func TestVerifierAppairageTablette_Succes(t *testing.T) {
	tabPriv, tabPub := genererPaireEd25519DeTest(t)
	pairingId := uuid.NewString()
	chargeUtile := construireChargeUtileAppairageTablette(t, pairingId, tabPub, tabPriv, "2026-05-11T10:00:00.000000Z")
	enveloppe, err := LireChargeUtileQR(chargeUtile)
	if err != nil {
		t.Fatalf("LireChargeUtileQR: %v", err)
	}

	clePubliqueRecue, err := VerifierAppairageTablette(enveloppe, pairingId)
	if err != nil {
		t.Fatalf("VerifierAppairageTablette: %v", err)
	}
	if !bytes.Equal(clePubliqueRecue, tabPub) {
		t.Errorf("cle publique retournee = %x, attendu %x", clePubliqueRecue, tabPub)
	}
}

func TestVerifierAppairageTablette_SignatureMauvaiseCle(t *testing.T) {
	_, tabPub := genererPaireEd25519DeTest(t)
	autrePriv, _ := genererPaireEd25519DeTest(t)
	pairingId := uuid.NewString()
	chargeUtile := construireChargeUtileAppairageTablette(t, pairingId, tabPub, autrePriv, "2026-05-11T10:00:00.000000Z")
	enveloppe, err := LireChargeUtileQR(chargeUtile)
	if err != nil {
		t.Fatalf("LireChargeUtileQR: %v", err)
	}
	if _, err := VerifierAppairageTablette(enveloppe, pairingId); !errors.Is(err, ErrSignatureInvalide) {
		t.Errorf("erreur = %v, attendu ErrSignatureInvalide", err)
	}
}

func TestVerifierAppairageTablette_TimestampAltere(t *testing.T) {
	tabPriv, tabPub := genererPaireEd25519DeTest(t)
	pairingId := uuid.NewString()
	chargeUtile := construireChargeUtileAppairageTablette(t, pairingId, tabPub, tabPriv, "2026-05-11T10:00:00.000000Z")
	enveloppe, err := LireChargeUtileQR(chargeUtile)
	if err != nil {
		t.Fatalf("LireChargeUtileQR: %v", err)
	}
	enveloppe.Timestamp = "2099-01-01T00:00:00.000000Z"
	if _, err := VerifierAppairageTablette(enveloppe, pairingId); !errors.Is(err, ErrSignatureInvalide) {
		t.Errorf("erreur = %v, attendu ErrSignatureInvalide apres alteration du timestamp", err)
	}
}

func TestVerifierAppairageTablette_PairingIdDifferent(t *testing.T) {
	tabPriv, tabPub := genererPaireEd25519DeTest(t)
	chargeUtile := construireChargeUtileAppairageTablette(t, uuid.NewString(), tabPub, tabPriv, "2026-05-11T10:00:00.000000Z")
	enveloppe, err := LireChargeUtileQR(chargeUtile)
	if err != nil {
		t.Fatalf("LireChargeUtileQR: %v", err)
	}
	if _, err := VerifierAppairageTablette(enveloppe, uuid.NewString()); !errors.Is(err, ErrPairingIdNonReconnu) {
		t.Errorf("erreur = %v, attendu ErrPairingIdNonReconnu", err)
	}
}

func TestVerifierAppairageTablette_TypeInattendu(t *testing.T) {
	tabPriv, tabPub := genererPaireEd25519DeTest(t)
	pairingId := uuid.NewString()
	chargeUtile := construireChargeUtileAppairageTablette(t, pairingId, tabPub, tabPriv, "2026-05-11T10:00:00.000000Z")
	enveloppe, err := LireChargeUtileQR(chargeUtile)
	if err != nil {
		t.Fatalf("LireChargeUtileQR: %v", err)
	}
	enveloppe.Type = TypeSession
	if _, err := VerifierAppairageTablette(enveloppe, pairingId); !errors.Is(err, ErrTypeInattendu) {
		t.Errorf("erreur = %v, attendu ErrTypeInattendu", err)
	}
}

func TestVerifierAppairageTablette_VersionIncompatible(t *testing.T) {
	tabPriv, tabPub := genererPaireEd25519DeTest(t)
	pairingId := uuid.NewString()
	chargeUtile := construireChargeUtileAppairageTablette(t, pairingId, tabPub, tabPriv, "2026-05-11T10:00:00.000000Z")
	enveloppe, err := LireChargeUtileQR(chargeUtile)
	if err != nil {
		t.Fatalf("LireChargeUtileQR: %v", err)
	}
	enveloppe.Version = 99
	if _, err := VerifierAppairageTablette(enveloppe, pairingId); !errors.Is(err, ErrVersionIncompatible) {
		t.Errorf("erreur = %v, attendu ErrVersionIncompatible", err)
	}
}

func TestVerifierAppairageTablette_PayloadSansTabPub(t *testing.T) {
	tabPriv, _ := genererPaireEd25519DeTest(t)
	pairingId := uuid.NewString()
	payloadJSON := fmt.Sprintf(`{"pairing_id":%q}`, pairingId)
	messageSigne := fmt.Sprintf(`{"type":%q,"version":%d,"timestamp":%q,"payload":%s}`,
		TypeAppairageTablette, VersionProtocole, "2026-05-11T10:00:00.000000Z", payloadJSON)
	signature := ed25519.Sign(ed25519.PrivateKey(tabPriv), []byte(messageSigne))
	enveloppeJSON := fmt.Sprintf(`{"type":%q,"version":%d,"timestamp":%q,"payload":%s,"signature":%q}`,
		TypeAppairageTablette, VersionProtocole, "2026-05-11T10:00:00.000000Z", payloadJSON, base64.StdEncoding.EncodeToString(signature))
	chargeUtile, err := compresserEtEncoder([]byte(enveloppeJSON))
	if err != nil {
		t.Fatalf("compresser: %v", err)
	}
	enveloppe, err := LireChargeUtileQR(chargeUtile)
	if err != nil {
		t.Fatalf("LireChargeUtileQR: %v", err)
	}
	if _, err := VerifierAppairageTablette(enveloppe, pairingId); !errors.Is(err, ErrPayloadInvalide) {
		t.Errorf("erreur = %v, attendu ErrPayloadInvalide", err)
	}
}
