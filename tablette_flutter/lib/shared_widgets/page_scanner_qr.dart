import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../core/textes.dart';

class PageScannerQr extends StatefulWidget {
  const PageScannerQr({super.key});

  @override
  State<PageScannerQr> createState() => _PageScannerQrState();
}

class _PageScannerQrState extends State<PageScannerQr> {
  bool _detectionEffectuee = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(Textes.titreScanner)),
      body: MobileScanner(
        onDetect: (capture) {
          if (_detectionEffectuee) return;
          if (capture.barcodes.isEmpty) return;
          final valeur = capture.barcodes.first.rawValue;
          if (valeur == null) return;
          _detectionEffectuee = true;
          Navigator.of(context).pop(valeur);
        },
      ),
    );
  }
}
