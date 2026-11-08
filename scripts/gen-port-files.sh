#!/bin/sh
# First-run helper: create distinfo and pkg-plist for overlay ports that lack them,
# and copy them back into ./ports so they can be committed. No-op when both exist.
# Runs on the (throwaway) FreeBSD build host; it installs build deps with pkg.
set -eu
ROOT=${ROOT:-$(cd "$(dirname "$0")/.." && pwd)}
PORTSDIR=${PORTSDIR:-/usr/ports}
export BATCH=yes

while read -r origin; do
  case "$origin" in ''|\#*) continue ;; esac
  d="$PORTSDIR/$origin"
  if [ ! -f "$d/distinfo" ]; then
    echo "=== makesum $origin"
    make -C "$d" makesum
    cp "$d/distinfo" "$ROOT/ports/$origin/distinfo"
  fi
  if [ ! -f "$d/pkg-plist" ]; then
    echo "=== makeplist $origin"
    # Install whatever dependencies exist as binary packages, one by one (a single
    # missing package would otherwise abort the whole transaction), then let the
    # ports tree build the rest from source: overlay ports such as moksha-menu and
    # anything not in the official repo.
    for dep in $(make -C "$d" missing); do
      pkg install -y "$dep" >/dev/null 2>&1 || echo "no binary package for $dep, will build from source"
    done
    # The binary packages above come from the pkg branch (e.g. quarterly), which can
    # lag the pinned ports tree (gstreamer1-plugins 1.28.8 installed vs 1.28.9 in the
    # tree). `make depends` then rebuilds the newer version from source and its
    # install step aborts with "An older version ... is already installed".
    # FORCE_PKG_REGISTER (ports(7)) lets it overwrite the old registration; this is a
    # throwaway host and the real build happens later in poudriere's clean jail.
    make -C "$d" FORCE_PKG_REGISTER=yes depends
    make -C "$d" clean stage
    make -C "$d" makeplist | grep -v -e '^===>' -e '^/!\\' > "$d/pkg-plist"
    # moksha's shutdown/reboot/suspend helper must be setuid root
    sed -i '' -E 's#^(lib/enlightenment/utils/enlightenment_sys)$#@(root,wheel,4755) \1#' "$d/pkg-plist"
    cp "$d/pkg-plist" "$ROOT/ports/$origin/pkg-plist"
    make -C "$d" clean
  fi
done < "$ROOT/ports.list"
