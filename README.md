# freebsd-amd64-repo

Personal binary pkg repo for FreeBSD 15 amd64 (ABI `FreeBSD:15:amd64`). Sources live
here; built packages are published as release assets of `RELEASE_REPO`
(`n3ptune-plan3t/freebsd-amd64-pkg`), never committed to git.

## Layout

| Path | Purpose |
|---|---|
| `ports/<category>/<name>/` | ports overlay (Makefile, distinfo, pkg-plist, files/) |
| `ports.list` | origins to build |
| `PORTS_REF` | pinned FreeBSD ports-tree commit (empty = HEAD). Bump deliberately |
| `conf/make.conf`, `conf/options/` | build settings shared by CI and local builds |
| `keys/pkg.pub` | public signing key |
| `scripts/build-ports.sh` | poudriere build -> flat signed repo in `./repo` (same entry for CI and local) |
| `scripts/gen-port-files.sh` | creates missing `distinfo` / `pkg-plist` (first run only) |
| `scripts/gen-signing-key.sh` | one-time signing key generation |
| `scripts/check-updates.py` | upstream version watcher (`update-check.json` = overrides) |
| `scripts/prune-release.sh` | removes stale package versions from the release |

## How a build works

Poudriere builds each port in a clean jail against the pinned ports tree. Dependencies
not in `ports.list` are fetched prebuilt from pkg.FreeBSD.org (`latest`); any whose
version differs from the pinned tree are built from source. Previously published
packages are downloaded first, so unchanged ports are not rebuilt. A weekly scheduled
run keeps things fresh; the update checker opens an issue when an upstream moves.

## One-time setup

1. `sh scripts/gen-signing-key.sh`, commit `keys/pkg.pub`, set the `PKG_SIGNING_KEY` secret.
2. Secret `RELEASE_TOKEN`: token with write access to `RELEASE_REPO`.
3. Run the workflow once. Download the `generated-port-files` artifact and commit the
   generated `distinfo` / `pkg-plist` files.

## Client

Copy `keys/pkg.pub` to `/usr/local/etc/pkg/keys/n3ptune.pub`, then
`/usr/local/etc/pkg/repos/n3ptune.conf`:

    n3ptune: {
      url: "https://github.com/n3ptune-plan3t/freebsd-amd64-pkg/releases/download/FreeBSD-15-amd64",
      mirror_type: "none",
      signature_type: "pubkey",
      pubkey: "/usr/local/etc/pkg/keys/n3ptune.pub",
      enabled: yes
    }

## Local build

As root on a FreeBSD 15 amd64 host: `./build.sh` (output in `./repo`).
Set `PKG_SIGNING_KEY` to sign, and drop old `.pkg` files in `./seed` to reuse them.
