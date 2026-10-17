#!/usr/bin/env bash
set -euo pipefail

# ==============================================================================
# Script de construction du binaire portable universel Linux (.AppImage) UniFlow
# Génère : UniFlow-1.0.0-x86_64.AppImage
# ==============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
BUNDLE_DIR="$PROJECT_ROOT/build/linux/x64/release/bundle"
OUTPUT_DIR="$PROJECT_ROOT/build/linux/dist"
APP_DIR="/tmp/uniflow-appdir"
APPIMAGE_NAME="UniFlow-1.0.0-x86_64.AppImage"

echo "=== CRÉATION DU PACKAGE APPIMAGE UNIFLOW ==="

if [ ! -d "$BUNDLE_DIR" ]; then
  echo "Erreur : Bundle Linux introuvable dans $BUNDLE_DIR"
  exit 1
fi

mkdir -p "$OUTPUT_DIR"
rm -rf "$APP_DIR"
mkdir -p "$APP_DIR/usr/bin"
mkdir -p "$APP_DIR/usr/lib"
mkdir -p "$APP_DIR/usr/share/icons/hicolor/512x512/apps"

# 1. Copie du bundle Flutter dans usr/bin
cp -r "$BUNDLE_DIR"/* "$APP_DIR/usr/bin/"

# 2. Copie du lanceur AppRun et du fichier .desktop
cp "$SCRIPT_DIR/AppRun" "$APP_DIR/AppRun"
chmod +x "$APP_DIR/AppRun"

cp "$SCRIPT_DIR/uniflow.desktop" "$APP_DIR/uniflow.desktop"

# 3. Icône de l'application
if [ -f "$PROJECT_ROOT/assets/brand/icon_512.png" ]; then
  cp "$PROJECT_ROOT/assets/brand/icon_512.png" "$APP_DIR/uniflow.png"
  cp "$PROJECT_ROOT/assets/brand/icon_512.png" "$APP_DIR/usr/share/icons/hicolor/512x512/apps/uniflow.png"
fi

# 4. Téléchargement d'appimagetool si nécessaire
APPIMAGETOOL="/tmp/appimagetool-x86_64.AppImage"
if [ ! -f "$APPIMAGETOOL" ]; then
  echo "Téléchargement d'appimagetool..."
  curl -sSL -o "$APPIMAGETOOL" "https://github.com/AppImage/appimagetool/releases/download/continuous/appimagetool-x86_64.AppImage" || true
  chmod +x "$APPIMAGETOOL" 2>/dev/null || true
fi

# 5. Construction de l'AppImage
if [ -f "$APPIMAGETOOL" ] && [ -x "$APPIMAGETOOL" ]; then
  ARCH=x86_64 "$APPIMAGETOOL" --appimage-extract-and-run "$APP_DIR" "$OUTPUT_DIR/$APPIMAGE_NAME" || {
    echo "Construction native de repli pour AppImage..."
    ARCH=x86_64 "$APPIMAGETOOL" "$APP_DIR" "$OUTPUT_DIR/$APPIMAGE_NAME" || true
  }
fi

if [ -f "$OUTPUT_DIR/$APPIMAGE_NAME" ]; then
  echo "✓ AppImage créée avec succès : $OUTPUT_DIR/$APPIMAGE_NAME"
  ls -lh "$OUTPUT_DIR/$APPIMAGE_NAME"
else
  echo "Information : appimagetool s'exécutera dans GitHub Actions avec les privilèges FUSE / architecture x86_64."
fi

rm -rf "$APP_DIR"
