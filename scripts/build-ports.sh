#!/bin/sh
# Build every origin in ports.list with poudriere (clean jail, proper dependency
# resolution), then write a flat, signed pkg repo to ./repo.
# Runs as root on a FreeBSD amd64 host (CI VM or local).
#
# Inputs (optional):
#   PORTS_REF          file: ports-tree commit/branch to build against (empty = HEAD)
#   seed/*.pkg         previously published packages; unchanged ones are reused
#   $PKG_SIGNING_KEY   RSA private key (PEM text); unset = unsigned repo
set -eu
ROOT=$(cd "$(dirname "$0")/.." && pwd)
PORTSDIR=${PORTSDIR:-/usr/ports}
OUT=${OUT:-$ROOT/repo}
SEED=${SEED:-$ROOT/seed}
PBASE=${PBASE:-/usr/local/poudriere}
JAIL=${JAIL:-build}
TREE=${TREE:-default}
PKGDIR=$PBASE/data/packages/$JAIL-$TREE
export BATCH=yes ROOT PORTSDIR

KEYFILE=
cleanup() {
  [ -n "$KEYFILE" ] && rm -f "$KEYFILE"
  # keep poudriere logs next to the repo so CI can upload them on failure
  if [ -d "$PBASE/data/logs/bulk/$JAIL-$TREE/latest" ]; then
    mkdir -p "$ROOT/logs" && cp -RL "$PBASE/data/logs/bulk/$JAIL-$TREE/latest/." "$ROOT/logs/" 2>/dev/null || true
  fi
}
trap cleanup EXIT

# --- 1. host pkg config: the ports tree is pinned but dependencies come from "latest"
mkdir -p /usr/local/etc/pkg/repos
cat > /usr/local/etc/pkg/repos/FreeBSD.conf <<'CONF'
FreeBSD-ports: {
  url: "pkg+https://pkg.FreeBSD.org/${ABI}/latest",
  mirror_type: "srv",
  signature_type: "fingerprints",
  fingerprints: "/usr/share/keys/pkg",
  enabled: yes
}
FreeBSD-ports-kmods: { enabled: no }
FreeBSD: { enabled: no }
CONF
pkg update -f
pkg install -y poudriere git ca_root_nss

# --- 2. ports tree at the pinned ref, plus our overlay
REF=$(tr -d ' \n' < "$ROOT/PORTS_REF" 2>/dev/null || true)
if [ ! -d "$PORTSDIR/.git" ]; then
  mkdir -p "$PORTSDIR"
  git -C "$PORTSDIR" init -q
  git -C "$PORTSDIR" remote add origin https://git.FreeBSD.org/ports.git
fi
if ! git -C "$PORTSDIR" fetch -q --depth 1 origin "${REF:-HEAD}"; then
  git -C "$PORTSDIR" remote set-url origin https://github.com/freebsd/freebsd-ports.git
  git -C "$PORTSDIR" fetch -q --depth 1 origin "${REF:-HEAD}"
fi
git -C "$PORTSDIR" checkout -q -f FETCH_HEAD
echo "ports tree: $(git -C "$PORTSDIR" rev-parse HEAD)"
cp -R "$ROOT/ports/." "$PORTSDIR/"

# --- 3. distinfo / pkg-plist for ports that don't have them yet (first run only)
sh "$ROOT/scripts/gen-port-files.sh"

# --- 4. poudriere configuration
mkdir -p /usr/local/etc/poudriere.d/options "$PBASE/distfiles"
cat > /usr/local/etc/poudriere.conf <<CONF
NO_ZFS=yes
BASEFS=$PBASE
FREEBSD_HOST=https://download.FreeBSD.org
RESOLV_CONF=/etc/resolv.conf
DISTFILES_CACHE=$PBASE/distfiles
USE_TMPFS=no
ALLOW_MAKE_JOBS=yes
PACKAGE_FETCH_BRANCH=latest
CHECK_CHANGED_OPTIONS=verbose
CHECK_CHANGED_DEPS=yes
CONF
cp "$ROOT/conf/make.conf" /usr/local/etc/poudriere.d/make.conf
cp -R "$ROOT/conf/options/." /usr/local/etc/poudriere.d/options/

# --- 5. jail (same version as the host) and ports tree handle
if ! poudriere jail -lq | grep -qw "$JAIL"; then
  REL=$(freebsd-version -u | sed 's/-p[0-9]*$//')
  poudriere jail -c -j "$JAIL" -v "$REL" -a amd64 -m http
fi
poudriere ports -lq | grep -qw "$TREE" || poudriere ports -c -p "$TREE" -m null -M "$PORTSDIR"

# --- 6. reuse previously published packages; poudriere rebuilds only what changed
#        and drops anything not wanted any more
mkdir -p "$PKGDIR/All"
if ls "$SEED"/*.pkg >/dev/null 2>&1; then
  cp "$SEED"/*.pkg "$PKGDIR/All/"
  echo "seeded $(ls "$SEED"/*.pkg | wc -l | tr -d ' ') package(s)"
fi

# --- 7. build; dependencies not in ports.list come prebuilt from pkg.FreeBSD.org
poudriere bulk -j "$JAIL" -p "$TREE" -b latest -f "$ROOT/ports.list"

# --- 8. flat repo layout (matches release-asset URLs) + signature
rm -rf "$OUT"; mkdir -p "$OUT"
cp "$PKGDIR"/All/*.pkg "$OUT/"
if [ -n "${PKG_SIGNING_KEY:-}" ]; then
  KEYFILE=$(mktemp); chmod 600 "$KEYFILE"
  printf '%s\n' "$PKG_SIGNING_KEY" > "$KEYFILE"
else
  echo "WARNING: PKG_SIGNING_KEY not set - repo is NOT signed" >&2
fi
pkg repo "$OUT" $KEYFILE
ls -l "$OUT"
