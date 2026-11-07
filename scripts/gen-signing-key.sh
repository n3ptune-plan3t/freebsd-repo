#!/bin/sh
# Run once, locally. Writes keys/pkg.pub (commit it) and ./pkg.key (secret, never commit).
set -eu
cd "$(dirname "$0")/.."
umask 077
openssl genrsa -out pkg.key 4096
openssl rsa -in pkg.key -pubout -out keys/pkg.pub
echo
echo "1. Commit keys/pkg.pub"
echo "2. Store the private key as the PKG_SIGNING_KEY secret:"
echo "     gh secret set PKG_SIGNING_KEY < pkg.key"
echo "3. Delete pkg.key (or keep it in a password manager)."
