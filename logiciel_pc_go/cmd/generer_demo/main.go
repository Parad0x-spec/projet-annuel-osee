package main

import (
	"context"
	"encoding/json"
	"flag"
	"fmt"
	"log"
	"os"
	"time"

	"projet_annuel/logiciel_pc_go/internal/patients"
	"projet_annuel/logiciel_pc_go/internal/sessions"
)

func main() {
	out := flag.String("out", "demo.db", "chemin du fichier de base de demonstration a generer")
	force := flag.Bool("force", false, "supprime et regenere le fichier s'il existe deja")
	flag.Parse()

	if err := genererBaseDemo(*out, *force); err != nil {
		log.Fatalf("generation base demo: %v", err)
	}
	fmt.Printf("Base de demonstration generee : %s\n", *out)
	fmt.Printf("Lancez le logiciel avec : logiciel_pc --db %s\n", *out)
}

func genererBaseDemo(chemin string, force bool) error {
	if _, err := os.Stat(chemin); err == nil {
		if !force {
			return fmt.Errorf("le fichier %q existe deja, relancez avec -force pour le regenerer", chemin)
		}
		if err := os.Remove(chemin); err != nil {
			return fmt.Errorf("suppression du fichier existant: %w", err)
		}
	} else if !os.IsNotExist(err) {
		return fmt.Errorf("verification du fichier: %w", err)
	}

	depotPatients, err := patients.OuvrirDepot(chemin)
	if err != nil {
		return fmt.Errorf("ouvrir base patients: %w", err)
	}
	defer depotPatients.Fermer()

	depotSessions, err := sessions.OuvrirDepot(chemin)
	if err != nil {
		return fmt.Errorf("ouvrir base sessions: %w", err)
	}
	defer depotSessions.Fermer()

	ctx := context.Background()
	for _, pd := range patientsDemo {
		patient, err := depotPatients.CreerPatient(ctx, pd.Nom, pd.Prenom, pd.DateNaissance, pd.Notes)
		if err != nil {
			return fmt.Errorf("creer patient %s %s: %w", pd.Nom, pd.Prenom, err)
		}
		for i := 0; i < nbSeancesDemo; i++ {
			date := dateSeance(i)
			niveau := niveauSeance(i)
			planches := genererPlanchesSeance(pd.Profil, i)
			payload, err := payloadSessionDemo(patient, date, niveau, planches)
			if err != nil {
				return fmt.Errorf("payload seance %d de %s: %w", i, patient.Initiales, err)
			}
			if _, err := depotSessions.EnregistrerSession(ctx, patient.PatientID, date, "emotions", niveau, planches, payload); err != nil {
				return fmt.Errorf("enregistrer seance %d de %s: %w", i, patient.Initiales, err)
			}
		}
	}
	return nil
}

type resultatEmotionJSON struct {
	Emotion          string `json:"emotion"`
	NbCiblesTotal    int    `json:"nb_cibles_total"`
	NbCiblesTrouvees int    `json:"nb_cibles_trouvees"`
	NbFauxPositifs   int    `json:"nb_faux_positifs"`
	Score            int    `json:"score"`
	Evaluee          bool   `json:"evaluee"`
}

type plancheJSON struct {
	NumeroPlanche       int                   `json:"numero_planche"`
	ScoreGlobal         int                   `json:"score_global"`
	ResultatsParEmotion []resultatEmotionJSON `json:"resultats_par_emotion"`
}

type payloadSessionJSON struct {
	PatientID        string        `json:"patient_id"`
	PatientInitiales string        `json:"patient_initiales"`
	SessionDate      string        `json:"session_date"`
	JeuType          string        `json:"jeu_type"`
	Niveau           int           `json:"niveau"`
	Planches         []plancheJSON `json:"planches"`
}

func payloadSessionDemo(patient patients.Patient, date time.Time, niveau int, planches []sessions.PlancheJouee) ([]byte, error) {
	planchesJSON := make([]plancheJSON, 0, len(planches))
	for _, planche := range planches {
		resultats := make([]resultatEmotionJSON, 0, len(planche.ResultatsParEmotion))
		for _, r := range planche.ResultatsParEmotion {
			resultats = append(resultats, resultatEmotionJSON{
				Emotion:          r.Emotion,
				NbCiblesTotal:    r.NbCiblesTotal,
				NbCiblesTrouvees: r.NbCiblesTrouvees,
				NbFauxPositifs:   r.NbFauxPositifs,
				Score:            r.Score,
				Evaluee:          r.Evaluee,
			})
		}
		planchesJSON = append(planchesJSON, plancheJSON{
			NumeroPlanche:       planche.NumeroPlanche,
			ScoreGlobal:         planche.ScoreGlobal,
			ResultatsParEmotion: resultats,
		})
	}
	return json.Marshal(payloadSessionJSON{
		PatientID:        patient.PatientID,
		PatientInitiales: patient.Initiales,
		SessionDate:      date.UTC().Format(time.RFC3339),
		JeuType:          "emotions",
		Niveau:           niveau,
		Planches:         planchesJSON,
	})
}
