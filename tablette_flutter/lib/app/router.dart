import 'package:go_router/go_router.dart';

import 'accueil_screen.dart';

final GoRouter routeurApplication = GoRouter(
  initialLocation: '/',
  routes: <GoRoute>[
    GoRoute(
      path: '/',
      name: 'accueil',
      builder: (context, state) => const AccueilScreen(),
    ),
  ],
);
