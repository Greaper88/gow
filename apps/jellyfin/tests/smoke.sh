#!/usr/bin/env bash
source /smoke-common/lib.sh

assert_has jellyfinmediaplayer sway dbus-run-session pactl
assert_shared_ok /usr/bin/jellyfinmediaplayer
assert_path /opt/gow/startup-app.sh /opt/gow/run-jellyfin.sh \
    /usr/lib/x86_64-linux-gnu/qt5/plugins/platforms/libqwayland-egl.so

if output=$(timeout 15 gosu "$UNAME" jellyfinmediaplayer --help 2>&1) \
    && [[ "$output" == *--fullscreen* && "$output" == *--tv* ]]; then
    ok 'player starts as the app user and exposes fullscreen TV controls'
else
    bad "player help failed: $output"
fi

smoke_report
