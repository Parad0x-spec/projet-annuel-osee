// Temporary tool for sprint 2 task 5 manual testing.
package main

import (
	"fmt"
	"log"
	"os"
	"path/filepath"

	"projet_annuel/logiciel_pc_go/internal/crypto"
	"projet_annuel/logiciel_pc_go/internal/qr"
)

const cheminPNG = "build/qr_test_appairage.png"

func main() {
	_, clePublique, err := crypto.GenererPaireDeCles()
	if err != nil {
		log.Fatalf("generation cles: %v", err)
	}

	_, pngQR, pairingId, err := qr.GenererQRAppairage(clePublique)
	if err != nil {
		log.Fatalf("generation QR: %v", err)
	}

	if err := os.MkdirAll(filepath.Dir(cheminPNG), 0o755); err != nil {
		log.Fatalf("creer dossier build: %v", err)
	}
	if err := os.WriteFile(cheminPNG, pngQR, 0o644); err != nil {
		log.Fatalf("ecrire PNG: %v", err)
	}

	cheminAbsolu, err := filepath.Abs(cheminPNG)
	if err != nil {
		cheminAbsolu = cheminPNG
	}

	fmt.Println("QR d'appairage genere avec succes.")
	fmt.Println()
	fmt.Printf("  pairing_id : %s\n", pairingId)
	fmt.Printf("  fichier    : %s\n", cheminAbsolu)
	fmt.Printf("  taille     : %d octets\n", len(pngQR))
	fmt.Println()
	fmt.Println("Ouvrez le PNG dans n'importe quel visualiseur d'images,")
	fmt.Println("puis scannez le QR depuis la tablette via Nouveau patient.")
}
