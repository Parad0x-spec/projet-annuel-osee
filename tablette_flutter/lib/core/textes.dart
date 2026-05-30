class Textes {
  Textes._();

  static const String titreApplication = 'Atelier d\'entraînement';
  static const String titreAccueil = 'Atelier d\'entraînement';
  static const String boutonNouveauPatient = 'Nouveau patient';
  static const String boutonPatientExistant = 'Patient existant';
  static const String boutonParametres = 'Paramètres';
  static const String boutonModeDemo = 'Mode démo';

  static const String titreAppairage = 'Appairage avec le PC';
  static const String consigneAppairage =
      'Demandez au praticien d\'afficher le QR d\'appairage sur son PC.';
  static const String boutonScannerQRPC = 'Scanner le QR du PC';
  static const String titreScanner = 'Scan du QR';
  static const String messageAppairageEnCours = 'Appairage en cours…';
  static const String messageAppairageReussi = 'Appairage réussi.';
  static const String messageAppairageEchec = 'QR illisible, réessayez.';
  static const String boutonRetourAccueil = 'Retour à l\'accueil';
  static const String boutonReessayer = 'Réessayer';

  static const String consignePraticienScanner =
      'Faites scanner ce QR au praticien depuis son PC.';
  static const String boutonAppairageTermine = 'J\'ai terminé';

  static const String titreExportSession = 'Export de la séance';
  static const String consigneExportSession =
      'Faites scanner ce QR au praticien.';
  static String sessionPourInitiales(String initiales) =>
      'Session pour $initiales';
  static const String boutonTermineRetourAccueil =
      'Terminé, retourner à l\'accueil';
  static const String erreurExportSession =
      'Export impossible. Vérifiez que la tablette est appairée.';

  static const String titreConfirmationPatient = 'Patient chargé';
  static String confirmationPatientPret(String initiales) =>
      'Patient $initiales chargé. Prêt à jouer.';
  static const String boutonCommencerJeu = 'Commencer le jeu';
  static const String boutonAnnuler = 'Annuler';
  static const String messageAucunPatientCharge = 'Aucun patient chargé.';

  static const String erreurTabletteNonAppairee =
      'Tablette non appairée. Faites d\'abord l\'appairage avec le PC.';
  static const String erreurPatientNonVerifie =
      'Patient non vérifié, l\'appairage a peut-être été perdu.';
  static const String erreurQrIllisible = 'QR illisible, réessayez.';
  static const String erreurDonneesPatientInvalides =
      'Données patient invalides.';

  static const String titreConfigurationPartie = 'Configuration de la partie';
  static const String consignePlanche = 'Choisissez la planche';
  static const String consigneEmotion = 'Choisissez l\'émotion à chercher';
  static String libellePlanche(int numero) => 'Planche $numero';
  static const String emotionJoieLibelle = 'Joie';
  static const String emotionColereLibelle = 'Colère';
  static const String emotionTristesseLibelle = 'Tristesse';
  static const String emotionPeurLibelle = 'Peur';
  static const String boutonLancerPartie = 'Lancer la partie';
  static const String erreurChargementPlanche =
      'Impossible de charger la planche.';

  static const String titreJeu = 'Partie en cours';
  static String consigneTrouverEmotion(String emotionLibelle) =>
      'Trouve tous les enfants ${emotionLibelle.toLowerCase()}';
  static const String boutonJaiFini = 'J\'ai fini';
  static const String boutonArreter = 'Arrêter';
  static const String titreConfirmationArret = 'Arrêter la partie ?';
  static const String messageConfirmationArret =
      'La partie sera comptée comme abandonnée.';
  static const String boutonConfirmerArret = 'Oui, arrêter';
  static const String boutonAnnulerArret = 'Continuer';

  static const String titreTransitionPartie = 'Résultat de la partie';
  static const String messageEncouragementUneEtoile =
      'Bien essayé ! Continue, tu progresses.';
  static const String messageEncouragementDeuxEtoiles =
      'Bon travail, tu y es presque !';
  static const String messageEncouragementTroisEtoiles =
      'Bravo, c\'est excellent !';
  static const String boutonNouvellePartie = 'Nouvelle partie';
  static const String boutonTerminerSeance = 'Terminer la séance';

  static const String titreRecapitulatifSeance = 'Récapitulatif de la séance';
  static const String messageAucunePartieJouee =
      'Aucune partie jouée durant cette séance.';
  static String partieResume({
    required int numero,
    required int numeroPlanche,
    required String emotionLibelle,
    required int score,
  }) =>
      'Partie $numero — Planche $numeroPlanche, ${emotionLibelle.toLowerCase()} — score $score / 100';
  static const String boutonGenererQrSession = 'Générer le QR de séance';
  static const String boutonQuitterSansTransferer = 'Quitter sans transférer';

  static String libelleEmotion(String emotion) {
    switch (emotion) {
      case 'joie':
        return emotionJoieLibelle;
      case 'colere':
        return emotionColereLibelle;
      case 'tristesse':
        return emotionTristesseLibelle;
      case 'peur':
        return emotionPeurLibelle;
      default:
        return emotion;
    }
  }
}
