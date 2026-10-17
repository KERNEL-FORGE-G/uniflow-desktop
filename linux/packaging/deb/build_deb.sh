#!/usr/bin/env bash
set -euo pipefail

# ==============================================================================
# Script de construction du package Debian / Ubuntu (.DEB) pour UniFlow Desktop
# Génère : uniflow_1.0.0_amd64.deb
# ==============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
BUNDLE_DIR="$PROJECT_ROOT/build/linux/x64/release/bundle"
OUTPUT_DIR="$PROJECT_ROOT/build/linux/dist"
PKG_VERSION="1.0.0"
STAGE_DIR="/tmp/uniflow-deb-stage"

echo "=== CRÉATION DU PACKAGE DEBIAN (.DEB) UNIFLOW V$PKG_VERSION ==="

if [ ! -d "$BUNDLE_DIR" ]; then
  echo "Erreur : Bundle Linux introuvable dans $BUNDLE_DIR"
  echo "Veuillez exécuter : flutter build linux --release"
  exit 1
fi

mkdir -p "$OUTPUT_DIR"
rm -rf "$STAGE_DIR"
mkdir -p "$STAGE_DIR/DEBIAN"
mkdir -p "$STAGE_DIR/opt/uniflow"
mkdir -p "$STAGE_DIR/usr/bin"
mkdir -p "$STAGE_DIR/usr/share/applications"
mkdir -p "$STAGE_DIR/usr/share/icons/hicolor/512x512/apps"
mkdir -p "$STAGE_DIR/usr/share/icons/hicolor/256x256/apps"

# 1. Copie des fichiers compilés de l'application
cp -r "$BUNDLE_DIR"/* "$STAGE_DIR/opt/uniflow/"

# 2. Création du lanceur dans /usr/bin
cat << 'EOF' > "$STAGE_DIR/usr/bin/uniflow"
#!/usr/bin/env bash
exec /opt/uniflow/uniflow_desktop "$@"
EOF
chmod +x "$STAGE_DIR/usr/bin/uniflow"

# 3. Création du fichier .desktop pour GNOME, KDE, XFCE
cat << EOF > "$STAGE_DIR/usr/share/applications/uniflow.desktop"
[Desktop Entry]
Name=UniFlow
GenericName=Suite Académique Universitaire
Comment=Campus Connecté, Cours, Emplois du temps, Z-Library, Visio et Messagerie
Exec=/usr/bin/uniflow %U
Icon=uniflow
Terminal=false
Type=Application
Categories=Education;Science;Office;Network;
MimeType=x-scheme-handler/uniflow;
Keywords=Education;University;Courses;Schedule;ZLibrary;Campus;
StartupWMClass=uniflow_desktop
EOF
chmod 644 "$STAGE_DIR/usr/share/applications/uniflow.desktop"

# 4. Copie des icônes
if [ -f "$PROJECT_ROOT/assets/brand/icon_512.png" ]; then
  cp "$PROJECT_ROOT/assets/brand/icon_512.png" "$STAGE_DIR/usr/share/icons/hicolor/512x512/apps/uniflow.png"
fi
if [ -f "$PROJECT_ROOT/assets/brand/icon_256.png" ]; then
  cp "$PROJECT_ROOT/assets/brand/icon_256.png" "$STAGE_DIR/usr/share/icons/hicolor/256x256/apps/uniflow.png"
fi

# 5. Fichier de contrôle DEBIAN
cat << EOF > "$STAGE_DIR/DEBIAN/control"
Package: uniflow
Version: $PKG_VERSION
Section: education
Priority: optional
Architecture: amd64
Depends: libc6 (>= 2.31), libgtk-3-0 (>= 3.24), libglib2.0-0, libsecret-1-0, libjsoncpp25 | libjsoncpp1
Maintainer: KERNEL FORGE <support@kernelforge.codes>
Homepage: https://uniflow.kernelforge.codes
Description: UniFlow Desktop — Suite Académique et Campus Connecté
 Plateforme universitaire complète pour étudiants, enseignants et administration.
 Inclut l'affichage officiel des emplois du temps UY1, la bibliothèque certifiée
 Z-Library, la messagerie officielle @uniflow.kernelforge.codes, la visio-conférence
 et l'évaluation académique en ligne et hors-ligne.
EOF

# 6. Scripts postinst / postrm pour mise à jour du cache d'icônes
cat << 'EOF' > "$STAGE_DIR/DEBIAN/postinst"
#!/bin/sh
set -e
if [ -x /usr/bin/update-desktop-database ]; then
  update-desktop-database -q || true
fi
if [ -x /usr/bin/gtk-update-icon-cache ]; then
  gtk-update-icon-cache -q -t -f /usr/share/icons/hicolor || true
fi
exit 0
EOF
chmod 755 "$STAGE_DIR/DEBIAN/postinst"

cat << 'EOF' > "$STAGE_DIR/DEBIAN/postrm"
#!/bin/sh
set -e
if [ -x /usr/bin/update-desktop-database ]; then
  update-desktop-database -q || true
fi
if [ -x /usr/bin/gtk-update-icon-cache ]; then
  gtk-update-icon-cache -q -t -f /usr/share/icons/hicolor || true
fi
exit 0
EOF
chmod 755 "$STAGE_DIR/DEBIAN/postrm"

# 7. Génération de l'archive .deb
DEB_NAME="uniflow_${PKG_VERSION}_amd64.deb"
dpkg-deb --build --root-owner-group "$STAGE_DIR" "$OUTPUT_DIR/$DEB_NAME"
rm -rf "$STAGE_DIR"

echo "✓ Package Debian créé avec succès : $OUTPUT_DIR/$DEB_NAME"
ls -lh "$OUTPUT_DIR/$DEB_NAME"
