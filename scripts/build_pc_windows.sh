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
export CC=x86_64-w64-mingw32-gcc
export CXX=x86_64-w64-mingw32-g++
export CGO_ENABLED=1
export GOOS=windows
export GOARCH=amd64
go build \
    -ldflags="-s -w -extldflags '-static-libgcc -static-libstdc++'" \
    -o build/logiciel_pc.exe \
    ./cmd/logiciel_pc

echo "Binaire produit : logiciel_pc_go/build/logiciel_pc.exe"
ls -lh build/logiciel_pc.exe
