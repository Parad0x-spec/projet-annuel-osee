import 'package:go_router/go_router.dart';

import '../features/accueil/ui/accueil_screen.dart';
import '../features/appairage/ui/appairage_screen.dart';
import '../features/jeu_emotions/ui/confirmation_patient_screen.dart';
import 'jeu_placeholder_screen.dart';

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
      path: '/jeu',
      name: 'jeu',
      builder: (context, state) => const JeuPlaceholderScreen(),
    ),
  ],
);

final GoRouter routeurApplication = creerRouteurApplication();
