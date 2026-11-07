#!/bin/sh
# Local build on a FreeBSD 15.1 amd64 host (root). Output: ./repo
set -eu
exec sh "$(dirname "$0")/scripts/build-ports.sh"
