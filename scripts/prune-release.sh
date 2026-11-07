#!/bin/sh
# Delete release assets that are no longer in ./repo (old package versions).
# Run AFTER a successful upload. Needs gh + GH_TOKEN, and RELEASE_REPO / RELEASE_TAG.
set -eu
: "${RELEASE_REPO:?}" "${RELEASE_TAG:?}"
ls repo/*.pkg >/dev/null 2>&1 || { echo "repo/ has no packages - refusing to prune" >&2; exit 1; }
gh release view "$RELEASE_TAG" -R "$RELEASE_REPO" --json assets --jq '.assets[].name' |
while read -r name; do
  [ -e "repo/$name" ] && continue
  echo "deleting stale asset: $name"
  gh release delete-asset "$RELEASE_TAG" "$name" -R "$RELEASE_REPO" -y
done
