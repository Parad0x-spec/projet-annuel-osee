# Projet annuel - Dispositif d'entraînement et de suivi pour patients TDAH et autisme

Ce dépôt contient deux applications complémentaires utilisées par un praticien et par ses patients en cabinet. Une application Flutter sur tablette Android propose des jeux d'entraînement cognitif au patient. Un logiciel Go sur PC Windows permet au praticien de gérer les fiches patients et de suivre leur évolution. Les deux applications n'utilisent jamais internet et échangent leurs données par scan de QR code sur le réseau local du cabinet.

La documentation projet se trouve dans le dossier `docs/`. La note de cadrage et le plan en V sont dans `docs/cadrage/`. Les décisions techniques structurantes sont dans `docs/adr/`. Les spécifications fonctionnelles et techniques sont dans `docs/specs/`. Les comptes rendus de fin de sprint sont dans `docs/comptes_rendus/`.

Le code de la tablette est dans `tablette_flutter/`. Le code du logiciel PC est dans `logiciel_pc_go/`. Le format d'échange entre les deux est documenté dans `shared/protocole_qr/`.

L'environnement de développement cible est Arch Linux avec Flutter SDK et Go toolchain installés. La tablette de référence est une Lenovo Tab P12 sous Android 13. Le PC cible est sous Windows 10 ou 11.
