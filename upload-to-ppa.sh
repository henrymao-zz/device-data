#!/bin/bash
set -e

PPA="ppa:henrymao/ubuntu-nos"
GPG_KEY="A30250A69E5B4C27139CD7898AFC7E4A6437DFA0"

if [ -z "$1" ]; then
    RELEASE=$(lsb_release -cs)
else
    RELEASE="$1"
fi

echo "==> Building source package for $RELEASE..."

DEBEMAIL="henry.mao@canonical.com"
DEBFULLNAME="Henry Mao"
export DEBEMAIL DEBFULLNAME

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

PACKAGE_NAME=$(dpkg-parsechangelog -S Source)
VERSION=$(dpkg-parsechangelog -S Version)
UPSTREAM_VERSION=$(echo "$VERSION" | sed 's/-[0-9]*$//')

TARBALL="../${PACKAGE_NAME}_${UPSTREAM_VERSION}.orig.tar.xz"
if [ ! -f "$TARBALL" ]; then
    echo "==> Creating orig tarball..."
    TEMPDIR=$(mktemp -d)
    TARDIR="${TEMPDIR}/${PACKAGE_NAME}-${UPSTREAM_VERSION}"
    mkdir -p "$TARDIR"
    rsync -a --exclude='.git' --exclude='debian' . "$TARDIR/"
    tar -cJf "$TARBALL" -C "$TEMPDIR" "${PACKAGE_NAME}-${UPSTREAM_VERSION}"
    rm -rf "$TEMPDIR"
fi

cp debian/changelog /tmp/device-data-changelog.bak
trap 'mv -f /tmp/device-data-changelog.bak debian/changelog' EXIT

sed -i "s/UNRELEASED/${RELEASE}/" debian/changelog

NOW=$(date -R)
sed -i "s/>  .* 202[0-9] .*</>  ${NOW}</" debian/changelog

debuild -S -sa -k"${GPG_KEY}"

CHANGES_FILE="../${PACKAGE_NAME}_${VERSION}_source.changes"

echo "==> Uploading to $PPA..."
dput "$PPA" "$CHANGES_FILE"

echo "==> Upload complete."
