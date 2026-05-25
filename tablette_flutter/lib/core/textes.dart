class Textes {
  Textes._();

  static const String titreApplication = 'Atelier d\'entraînement';
  static const String titreAccueil = 'Atelier d\'entraînement';
  static const String boutonNouveauPatient = 'Nouveau patient';
  static const String boutonPatientExistant = 'Patient existant';
  static const String boutonParametres = 'Paramètres';

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

  static const String titreJeuPlaceholder = 'Jeu';
  static const String messageJeuPlaceholder =
      'Le jeu sera implémenté au sprint 3.';

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
}
