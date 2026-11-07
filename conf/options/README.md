Per-port OPTIONS, copied into /usr/local/etc/poudriere.d/options/ before each build.
Layout: `<category>_<port>/options` (e.g. `x11-wm_moksha/options`).
Generate one with `poudriere options -j build -p default x11-wm/moksha`, then commit it.
