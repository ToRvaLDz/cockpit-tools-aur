#!/bin/bash
set -ex # Debug e stop su errore

# Configurazione
REPO="jlcodes99/cockpit-tools"
PKGBUILD_FILE="PKGBUILD"

# 1. Ottieni l'ultima versione da GitHub API
LATEST_TAG=$(curl -s "https://api.github.com/repos/$REPO/releases/latest" | grep -Po '"tag_name": "\K.*?(?=")')
LATEST_VER=${LATEST_TAG#v}

# Leggi la versione attuale dal PKGBUILD
CURRENT_VER=$(grep "^pkgver=" "$PKGBUILD_FILE" | cut -d'=' -f2)

echo "Versione attuale locale: $CURRENT_VER"
echo "Ultima versione upstream: $LATEST_VER"
echo "FORZATURA: Procedo all'aggiornamento..."

# 2. Aggiorna la versione nel PKGBUILD
sed -i "s/^pkgver=.*/pkgver=$LATEST_VER/" "$PKGBUILD_FILE"
sed -i "s/^pkgrel=.*/pkgrel=1/" "$PKGBUILD_FILE"

# 3. Aggiorna i checksum
DEB_FILENAME="Cockpit.Tools_${LATEST_VER}_amd64.deb"
DOWNLOAD_URL="https://github.com/jlcodes99/cockpit-tools/releases/download/v${LATEST_VER}/${DEB_FILENAME}"

echo "Scaricamento di $DOWNLOAD_URL..."
curl -L -o "/tmp/$DEB_FILENAME" "$DOWNLOAD_URL"
NEW_SHA256=$(sha256sum "/tmp/$DEB_FILENAME" | awk '{print $1}')

sed -i "s/^sha256sums=('.*')/sha256sums=('$NEW_SHA256')/" "$PKGBUILD_FILE"

# 4. Rigenera .SRCINFO
makepkg --printsrcinfo > .SRCINFO

# Pulizia
rm "/tmp/$DEB_FILENAME"

# Segnala il risultato creando un file
echo "UPDATED=true" > update_result.txt
echo "VERSION=$LATEST_VER" >> update_result.txt