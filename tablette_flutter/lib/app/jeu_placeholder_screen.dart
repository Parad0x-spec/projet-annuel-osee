import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/textes.dart';

class JeuPlaceholderScreen extends StatelessWidget {
  const JeuPlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(Textes.titreJeuPlaceholder)),
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                Textes.messageJeuPlaceholder,
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              SizedBox(
                width: 360,
                height: 96,
                child: ElevatedButton(
                  onPressed: () => context.go('/export-session'),
                  child: const Text(
                    Textes.boutonExporterSessionTest,
                    style: TextStyle(fontSize: 22),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
