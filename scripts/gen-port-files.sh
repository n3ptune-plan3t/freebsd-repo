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
    make -C "$d" install-missing-packages
    make -C "$d" clean stage
    make -C "$d" makeplist | grep -v -e '^===>' -e '^/!\\' > "$d/pkg-plist"
    # moksha's shutdown/reboot/suspend helper must be setuid root
    sed -i '' -E 's#^(lib/enlightenment/utils/enlightenment_sys)$#@(root,wheel,4755) \1#' "$d/pkg-plist"
    cp "$d/pkg-plist" "$ROOT/ports/$origin/pkg-plist"
    make -C "$d" clean
  fi
done < "$ROOT/ports.list"
