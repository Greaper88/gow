#!/usr/bin/env bash
source /smoke-common/lib.sh
assert_has startplasma-wayland kwin_wayland plasmashell plasma-discover \
    dolphin konsole flatpak qdbus-qt6 gow-power-off
assert_shared_ok /usr/bin/kwin_wayland
assert_shared_ok /usr/bin/plasmashell
assert_shared_ok /usr/bin/plasma-discover
if [[ -f /var/lib/flatpak/repo/config ]] && [[ -z $(flatpak remotes --system --columns=name) ]]; then
    ok 'Discover can enumerate an empty system installation without system remotes'
else
    bad 'system Flatpak repository is missing or contains a remote'
fi
if [[ -z $(getcap /usr/bin/kwin_wayland) ]]; then
    ok 'KWin requires no file capabilities to execute'
else
    bad 'KWin has a file capability that may prevent container startup'
fi

backends=(/usr/lib64/qt6/plugins/discover/*-backend.so)
if [[ ${#backends[@]} == 1 && ${backends[0]} == */flatpak-backend.so ]]; then
    ok 'Discover exposes only Flatpak'
else
    bad "unexpected Discover backends: ${backends[*]}"
fi
if gosu "$UNAME" test ! -w /usr/bin && [[ ! -u /usr/bin/sudo ]] \
    && ! gosu "$UNAME" sudo -n true 2>/dev/null; then
    ok 'desktop user has no system package administration path'
else
    bad 'unexpected system write or sudo access'
fi
if gosu "$UNAME" flatpak remote-add --user --if-not-exists flathub /opt/gow/flathub/flathub.flatpakrepo \
    && [[ $(gosu "$UNAME" flatpak remotes --user --columns=name) == flathub ]]; then
    ok 'Flathub registers without a root or network operation'
else
    bad 'Flathub user remote initialization'
fi
smoke_report
