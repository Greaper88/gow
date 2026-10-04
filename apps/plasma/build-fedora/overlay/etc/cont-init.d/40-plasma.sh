#!/usr/bin/env bash
set -e

# This is the container's own bus. Never mount the host's system bus here.
mkdir -p /run/dbus
dbus-uuidgen --ensure=/etc/machine-id
dbus-daemon --system --fork --nopidfile

# Portals and KWin use a private runtime directory; the Wolf display is kept
# as an absolute socket path by startup.sh.
install -d -m 0700 -o "${PUID}" -g "${PGID}" "/run/user/${PUID}"
install -d -m 1777 /tmp/.X11-unix /tmp/.ICE-unix
