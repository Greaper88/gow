#!/usr/bin/env bash
# Execute a validation command with the real desktop's exported environment.
set -euo pipefail
if [[ $(id -u) == 0 ]]; then
    exec gosu "$UNAME" "$0" "$@"
fi
pid=$(pgrep -u "$(id -u)" -x plasmashell | head -n 1)
session_env=()
while IFS= read -r -d '' entry; do
    case "$entry" in
        HOME=*|USER=*|PATH=*|DBUS_SESSION_BUS_ADDRESS=*|DISPLAY=*|WAYLAND_DISPLAY=*|XAUTHORITY=*|XDG_*=*|KDE_*=*)
            session_env+=("$entry") ;;
    esac
done < "/proc/$pid/environ"
exec env "${session_env[@]}" "$@"
