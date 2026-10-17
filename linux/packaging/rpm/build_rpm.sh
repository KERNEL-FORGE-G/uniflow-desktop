#!/usr/bin/env bash
set -euo pipefail

# ==============================================================================
# Script de construction du package RPM (Fedora / RHEL / openSUSE) pour UniFlow
# Génère : uniflow-1.0.0-1.x86_64.rpm
# ==============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
BUNDLE_DIR="$PROJECT_ROOT/build/linux/x64/release/bundle"
OUTPUT_DIR="$PROJECT_ROOT/build/linux/dist"
RPM_ROOT="/tmp/rpmbuild-uniflow"

echo "=== CRÉATION DU PACKAGE RPM (.RPM) UNIFLOW ==="

if [ ! -d "$BUNDLE_DIR" ]; then
  echo "Erreur : Bundle Linux introuvable dans $BUNDLE_DIR"
  exit 1
fi

if ! command -v rpmbuild &> /dev/null; then
  echo "Installation de rpmbuild / rpm..."
  apt-get update -qq && apt-get install -y -qq rpm || true
fi

if ! command -v rpmbuild &> /dev/null; then
  echo "Avertissement : rpmbuild non disponible dans cet environnement. Le build RPM s'exécutera dans GitHub Actions."
  exit 0
fi

mkdir -p "$OUTPUT_DIR"
rm -rf "$RPM_ROOT"
mkdir -p "$RPM_ROOT"/{BUILD,RPMS,SOURCES,SPECS,SRPMS}

# Copie des sources
cp -r "$BUNDLE_DIR" "$RPM_ROOT/SOURCES/bundle"
if [ -f "$PROJECT_ROOT/assets/brand/icon_512.png" ]; then
  cp "$PROJECT_ROOT/assets/brand/icon_512.png" "$RPM_ROOT/SOURCES/icon_512.png"
fi
cp "$SCRIPT_DIR/uniflow.spec" "$RPM_ROOT/SPECS/"

# Exécution de rpmbuild
rpmbuild --define "_topdir $RPM_ROOT" -bb "$RPM_ROOT/SPECS/uniflow.spec"

# Copie du RPM produit dans le dossier dist
find "$RPM_ROOT/RPMS" -name "*.rpm" -exec cp {} "$OUTPUT_DIR/" \;
rm -rf "$RPM_ROOT"

echo "✓ Package RPM créé avec succès dans $OUTPUT_DIR :"
ls -lh "$OUTPUT_DIR"/*.rpm 2>/dev/null || true
