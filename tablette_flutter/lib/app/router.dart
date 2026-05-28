import 'package:go_router/go_router.dart';

import '../features/accueil/ui/accueil_screen.dart';
import '../features/appairage/ui/appairage_screen.dart';
import '../features/jeu_emotions/ui/configuration_partie_screen.dart';
import '../features/jeu_emotions/ui/confirmation_patient_screen.dart';
import '../features/jeu_emotions/ui/export_session_screen.dart';
import '../features/jeu_emotions/ui/jeu_screen.dart';
import '../features/jeu_emotions/ui/recapitulatif_seance_screen.dart';
import '../features/jeu_emotions/ui/transition_partie_screen.dart';

GoRouter creerRouteurApplication() => GoRouter(
  initialLocation: '/',
  routes: <GoRoute>[
    GoRoute(
      path: '/',
      name: 'accueil',
      builder: (context, state) => const AccueilScreen(),
    ),
    GoRoute(
      path: '/appairage',
      name: 'appairage',
      builder: (context, state) => const AppairageScreen(),
    ),
    GoRoute(
      path: '/confirmation-patient',
      name: 'confirmation-patient',
      builder: (context, state) => const ConfirmationPatientScreen(),
    ),
    GoRoute(
      path: '/configuration-partie',
      name: 'configuration-partie',
      builder: (context, state) => const ConfigurationPartieScreen(),
    ),
    GoRoute(
      path: '/jeu',
      name: 'jeu',
      builder: (context, state) => const JeuScreen(),
    ),
    GoRoute(
      path: '/transition-partie',
      name: 'transition-partie',
      builder: (context, state) => const TransitionPartieScreen(),
    ),
    GoRoute(
      path: '/recapitulatif-seance',
      name: 'recapitulatif-seance',
      builder: (context, state) => const RecapitulatifSeanceScreen(),
    ),
    GoRoute(
      path: '/export-session',
      name: 'export-session',
      builder: (context, state) => const ExportSessionScreen(),
    ),
  ],
);

final GoRouter routeurApplication = creerRouteurApplication();
