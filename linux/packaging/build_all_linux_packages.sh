#!/usr/bin/env bash
set -euo pipefail

# ==============================================================================
# Script global de construction de tous les packages Linux UniFlow
# Génère :
#   - uniflow_1.0.0_amd64.deb   (Debian, Ubuntu, Mint)
#   - uniflow-1.0.0-1.x86_64.rpm (Fedora, RedHat, openSUSE)
#   - UniFlow-1.0.0-x86_64.AppImage (Universel portable Linux)
#   - uniflow-linux-x64-bundle.tar.gz (Archive universelle)
# ==============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
DIST_DIR="$PROJECT_ROOT/build/linux/dist"
BUNDLE_DIR="$PROJECT_ROOT/build/linux/x64/release/bundle"

echo "======================================================================="
echo "  PACKAGING COMPLET DES BINAIRES LINUX UNIFLOW (DEB, RPM, APPIMAGE)    "
echo "======================================================================="

mkdir -p "$DIST_DIR"

# 1. Compilation du bundle Flutter Linux Release si absent
if [ ! -d "$BUNDLE_DIR" ]; then
  echo "Compilation Flutter Linux Release..."
  cd "$PROJECT_ROOT"
  flutter build linux --release
fi

# 2. Construction du paquet Debian (.deb)
chmod +x "$SCRIPT_DIR/deb/build_deb.sh"
"$SCRIPT_DIR/deb/build_deb.sh"

# 3. Construction du paquet RPM (.rpm)
chmod +x "$SCRIPT_DIR/rpm/build_rpm.sh"
"$SCRIPT_DIR/rpm/build_rpm.sh" || true

# 4. Construction de l'AppImage (.AppImage)
chmod +x "$SCRIPT_DIR/appimage/build_appimage.sh"
"$SCRIPT_DIR/appimage/build_appimage.sh" || true

# 5. Création de l'archive tar.gz universelle
echo ""
echo "[5/5] Création de l'archive tarball universelle..."
TARBALL="$DIST_DIR/uniflow-linux-x64-bundle-1.0.0.tar.gz"
tar -czf "$TARBALL" -C "$BUNDLE_DIR" .
echo "✓ Archive tarball générée : $TARBALL"

echo ""
echo "======================================================================="
echo "  RÉSUMÉ DES PACKAGES LINUX PRODUITS DANS build/linux/dist :           "
echo "======================================================================="
ls -lh "$DIST_DIR"
