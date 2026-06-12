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

	"projet_annuel/logiciel_pc_go/internal/appairage_pc"
	"projet_annuel/logiciel_pc_go/internal/export"
	"projet_annuel/logiciel_pc_go/internal/patients"
	"projet_annuel/logiciel_pc_go/internal/qr"
	"projet_annuel/logiciel_pc_go/internal/sessions"
)

const (
	titreFenetreQR   = "QR d'appairage PC"
	tailleQRAffichee = float32(500)
	delaiTraitement  = 10 * time.Second
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

func verifierChargeUtileScannee(
	session *sessionAppairage,
	depotAppairage *appairage_pc.DepotAppairage,
	depotSessions *sessions.DepotSessions,
	depotPatients *patients.DepotPatients,
	dossierExports string,
	chargeUtile string,
) string {
	enveloppe, err := qr.LireChargeUtileQR(chargeUtile)
	if err != nil {
		return messageErreurVerification(err)
	}

	ctx, annuler := context.WithTimeout(context.Background(), delaiTraitement)
	defer annuler()

	switch enveloppe.Type {
	case qr.TypeAppairageTablette:
		return traiterAppairageTablette(ctx, session, depotAppairage, enveloppe)
	case qr.TypeSession:
		return traiterSession(ctx, session, depotAppairage, depotSessions, depotPatients, dossierExports, enveloppe)
	default:
		return "Type de QR inattendu."
	}
}

func traiterAppairageTablette(ctx context.Context, session *sessionAppairage, depotAppairage *appairage_pc.DepotAppairage, enveloppe qr.Enveloppe) string {
	pairingIdAttendu := session.lirePairingId()
	if pairingIdAttendu == "" {
		return "Generez d'abord un QR PC."
	}

	tabPub, err := qr.VerifierAppairageTablette(enveloppe, pairingIdAttendu)
	if err != nil {
		return messageErreurVerification(err)
	}

	if _, err := depotAppairage.EnregistrerAppairage(ctx, pairingIdAttendu, tabPub); err != nil {
		return fmt.Sprintf("Appairage verifie mais non enregistre : %v", err)
	}
	session.memoriserTabPub(tabPub)

	return "Appairage enregistre."
}

func traiterSession(ctx context.Context, session *sessionAppairage, depotAppairage *appairage_pc.DepotAppairage, depotSessions *sessions.DepotSessions, depotPatients *patients.DepotPatients, dossierExports string, enveloppe qr.Enveloppe) string {
	tabPub := session.lireTabPub()
	if len(tabPub) == 0 {
		appairage, err := depotAppairage.LireAppairageActuel(ctx)
		if err != nil {
			return "Aucun appairage enregistre. Appairez d'abord la tablette."
		}
		tabPub = appairage.TabPub
		session.memoriserTabPub(tabPub)
	}

	payload, err := qr.VerifierSession(enveloppe, tabPub)
	if err != nil {
		return messageErreurVerification(err)
	}

	sessionDate, err := time.Parse(time.RFC3339, payload.SessionDate)
	if err != nil {
		return "QR illisible. Date de session invalide."
	}

	if _, err := depotSessions.EnregistrerSession(ctx, payload.PatientID, sessionDate, payload.JeuType, payload.Niveau, planchesPourStockage(payload.Planches), enveloppe.Payload); err != nil {
		if errors.Is(err, sessions.ErrPatientInconnu) {
			return fmt.Sprintf("Patient inconnu (%s). Session non enregistree.", payload.PatientInitiales)
		}
		return fmt.Sprintf("Session non enregistree : %v", err)
	}

	message := fmt.Sprintf("Session recue pour patient %s - niveau %d", payload.PatientInitiales, payload.Niveau)
	if err := genererExportPatient(ctx, depotPatients, depotSessions, dossierExports, payload.PatientID); err != nil {
		return message + fmt.Sprintf(" (export Excel non genere : %v)", err)
	}
	return message
}

func genererExportPatient(ctx context.Context, depotPatients *patients.DepotPatients, depotSessions *sessions.DepotSessions, dossierExports, patientID string) error {
	patient, err := depotPatients.LirePatientParID(ctx, patientID)
	if err != nil {
		return err
	}
	resumees, err := depotSessions.ResumeSeancesParPatient(ctx, patientID)
	if err != nil {
		return err
	}
	return export.GenererClasseurPatient(patient, resumees, export.CheminExportPatient(dossierExports, patient))
}

func planchesPourStockage(planches []qr.PlancheJouee) []sessions.PlancheJouee {
	converties := make([]sessions.PlancheJouee, 0, len(planches))
	for _, planche := range planches {
		resultats := make([]sessions.ResultatEmotion, 0, len(planche.ResultatsParEmotion))
		for _, r := range planche.ResultatsParEmotion {
			resultats = append(resultats, sessions.ResultatEmotion{
				Emotion:          r.Emotion,
				NbCiblesTotal:    r.NbCiblesTotal,
				NbCiblesTrouvees: r.NbCiblesTrouvees,
				NbFauxPositifs:   r.NbFauxPositifs,
				Score:            r.Score,
				Evaluee:          r.Evaluee,
			})
		}
		converties = append(converties, sessions.PlancheJouee{
			NumeroPlanche:       planche.NumeroPlanche,
			ScoreGlobal:         planche.ScoreGlobal,
			ResultatsParEmotion: resultats,
		})
	}
	return converties
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
