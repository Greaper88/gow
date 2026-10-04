#!/usr/bin/env bash
# Invoked by GOW's entrypoint after normal container initialization.
set -euo pipefail
gosu "$UNAME" unshare --user --map-root-user true
install -d -m 0700 -o "$PUID" -g "$PGID" /tmp/wolf-test
gosu "$UNAME" env XDG_RUNTIME_DIR=/tmp/wolf-test \
    dbus-run-session -- /usr/bin/kwin_wayland --virtual --no-lockscreen \
    --socket=wolf-test --width=1280 --height=720 > /tmp/parent-compositor.log 2>&1 &
for ((i=0; i<100; i++)); do
    [[ -S /tmp/wolf-test/wolf-test ]] && break
    sleep 0.1
done
export XDG_RUNTIME_DIR=/tmp/wolf-test WAYLAND_DISPLAY=wolf-test
export GAMESCOPE_WIDTH=1280 GAMESCOPE_HEIGHT=720
exec gosu "$UNAME" /opt/gow/startup.sh
