#!/usr/bin/env bash
set -euo pipefail

if [[ $(id -u) == 0 ]]; then
    echo 'Plasma must run as the unprivileged GOW user.' >&2
    exit 1
fi

: "${XDG_RUNTIME_DIR:?Wolf must supply XDG_RUNTIME_DIR}"
: "${WAYLAND_DISPLAY:?Wolf must supply WAYLAND_DISPLAY}"
if [[ $WAYLAND_DISPLAY != /* ]]; then
    export WAYLAND_DISPLAY="$XDG_RUNTIME_DIR/$WAYLAND_DISPLAY"
fi
if [[ ! -S $WAYLAND_DISPLAY ]]; then
    echo "Wolf's Wayland socket is missing: $WAYLAND_DISPLAY" >&2
    exit 1
fi

export XDG_RUNTIME_DIR="/run/user/$(id -u)"
export XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
export XDG_DATA_DIRS="$XDG_DATA_HOME/flatpak/exports/share:/usr/local/share:/usr/share"
export XDG_CONFIG_DIRS=/etc/xdg
export QT_QPA_PLATFORM=wayland
export MOZ_ENABLE_WAYLAND=1
export _JAVA_AWT_WM_NONREPARENTING=1
# Wolf supplies the PulseAudio server; do not start another audio server.
unset DISPLAY SESSION_MANAGER DBUS_SESSION_BUS_ADDRESS

mkdir -p "$XDG_DATA_HOME" "$XDG_CONFIG_HOME"
xdg-user-dirs-update
exec dbus-run-session -- /opt/gow/plasma-session
