#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

if [ ! -d "tablette_flutter" ]; then
    echo "Erreur : dossier tablette_flutter introuvable. Sprint 1 non initialise ?"
    exit 1
fi

cd tablette_flutter

echo "Verification que la tablette est connectee via adb..."
DEVICE_COUNT=$(adb devices | grep -c "device$" || true)
if [ "$DEVICE_COUNT" -eq 0 ]; then
    echo "Aucune tablette detectee. Verifie le cable USB et le mode developpeur."
    exit 1
fi

echo "Installation des dependances Flutter..."
flutter pub get

echo "Build APK debug..."
flutter build apk --debug

echo "Installation sur la tablette..."
flutter install

echo "Termine. Lance l'application sur la tablette."
