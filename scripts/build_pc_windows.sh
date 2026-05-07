#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

if [ ! -d "logiciel_pc_go" ]; then
    echo "Erreur : dossier logiciel_pc_go introuvable. Sprint 1 non initialise ?"
    exit 1
fi

cd logiciel_pc_go

mkdir -p build

echo "Compilation croisee Go vers Windows..."
GOOS=windows GOARCH=amd64 CGO_ENABLED=0 go build \
    -ldflags="-s -w" \
    -o build/logiciel_pc.exe \
    ./cmd/logiciel_pc

echo "Binaire produit : logiciel_pc_go/build/logiciel_pc.exe"
ls -lh build/logiciel_pc.exe
