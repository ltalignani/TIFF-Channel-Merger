#!/usr/bin/env bash

# Script pour créer l'application GUI multilingue de fusion de canaux TIFF
# Version 3.0 - Interface graphique native avec support français/anglais

set -e

echo "🌍 Création de l'application Fusion Canaux TIFF (Multilingue)..."
echo ""

# Nom de l'application
APP_NAME="TIFF Channel Merger"
APP_DIR="${APP_NAME}.app"

# Supprimer l'ancienne version si elle existe
if [ -d "$APP_DIR" ]; then
    echo "Suppression de l'ancienne version..."
    rm -rf "$APP_DIR"
fi

# Compiler le script AppleScript en application
echo "Compilation du script AppleScript multilingue..."
osacompile -o "$APP_DIR" fusion_canaux_gui_multilingual_fixed.applescript

if [ ! -d "$APP_DIR" ]; then
    echo "❌ Erreur lors de la compilation"
    exit 1
fi

echo "✅ Application multilingue créée avec succès !"
echo ""
echo "Emplacement : $(pwd)/$APP_DIR"
echo ""
echo "🌍 Fonctionnalités :"
echo "  - Sélection de langue (Français/English) au démarrage"
echo "  - Interface complètement traduite"
echo "  - Même fonctionnalité de fusion de canaux TIFF"
echo ""
echo "Pour utiliser l'application :"
echo "1. Double-cliquez sur '$APP_DIR' dans le Finder"
echo "2. Ou exécutez : open '$APP_DIR'"
echo ""
echo "L'application vous demandera d'abord votre langue préférée,"
echo "puis vous guidera à travers :"
echo "  - Sélection des fichiers TIFF à fusionner"
echo "  - Choix du nom du fichier de sortie"
echo "  - Sélection du dossier de destination"
echo "  - Options de création d'image pyramidale"
echo ""

# Proposer de lancer l'application
read -p "Voulez-vous lancer l'application maintenant ? (o/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[OoYy]$ ]]; then
    echo "Lancement de l'application multilingue..."
    open "$APP_DIR"
fi