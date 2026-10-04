# Desktop (Plasma)

Plasma 6 on GOW's Fedora base, with a persistent home directory and Discover
configured for user-installed applications from Flathub. The image supplies
the desktop, Dolphin, Konsole, Kate and Ark; install additional applications
using Discover or `flatpak install --user flathub APP_ID`. Image updates supply
system packages. There is no sudo access or native package installation in Discover.

## Build and use

From the GOW repository root:

```sh
docker build -t gow/plasma:local apps/plasma/build-fedora
```

Add the entry from `assets/wolf.config.toml` to Wolf's application list. This is
a separate desktop from XFCE, with its own `WolfPlasma` home directory. Wolf
provides the display, audio, GPU devices and persistent home in the same way
as its other applications. Do not share a live XFCE home with Plasma: XFCE's
Flatpak settings disable Wayland, and concurrent desktops can change settings.

KWin runs nested in Wolf's Wayland compositor and supplies Xwayland for older
applications. Its initial size comes from `GAMESCOPE_WIDTH` and
`GAMESCOPE_HEIGHT`. GOW's NVIDIA setup is preserved; no GPU vendor is forced.

## Session controls

| Action | Behavior |
| --- | --- |
| Log Out | KDE closes applications and ends the desktop; its container exits. |
| Power Off (launcher favorite) | Uses the same graceful logout path, stopping only this container. |
| Sleep / Switch User | Hidden. A future session-scoped Wolf integration must disconnect the stream while leaving applications running. |
| Hibernate / Restart / Lock | Hidden where supported by KDE's restrictions and capability detection. |

Stopping actions skip KDE's focus-dependent logout countdown. Applications
still receive normal session-close requests and can prompt to save or cancel.

Wolf's management API is not mounted into the desktop. It can control other
sessions, so exposing it just to implement a disconnect button would expand
the desktop's permissions. Use the client's disconnect action to leave the
desktop running, subject to Wolf's configured session/lobby lifetime policy.

The desktop uses its own D-Bus and unprivileged session, without systemd boot,
a display manager, NetworkManager, a local audio server, or host power control.
Machine administration settings and automatic locking are disabled. Normal
appearance, window, keyboard, mouse and sound settings remain available.
KDE restrictions tailor the UI; they are not a security boundary for arbitrary
programs run by the desktop user. Only Flathub is configured initially.

Flatpak needs unprivileged user namespaces. The sample runner keeps GOW's
unconfined seccomp/AppArmor configuration for nested sandboxing. `/dev/fuse`
and `SYS_ADMIN` allow the Flatpak document portal to share chosen files with
sandboxed apps. `DAC_READ_SEARCH` lets the privileged FUSE helper traverse
the private user runtime directory on hosts whose FUSE policy disallows
`DAC_OVERRIDE`. There is no host IPC or access to Docker/the host system bus.
Host policies must allow user namespaces. KWin's file capability is removed
so the compositor can start without `SYS_NICE`.
The runner also disables Docker's default system-path masks, which prevent
Bubblewrap from mounting a new `/proc` in its nested user namespace. Bubblewrap
runs without setuid, as required by current Fedora builds.
Wolf sends Docker API JSON directly, so the runner uses empty `MaskedPaths`
and `ReadonlyPaths` arrays. The CLI-only `systempaths=unconfined` option must
not appear in the runner's `SecurityOpt` list.

## Validation

Structural checks use `tests/smoke-fedora.sh`. A separate test image adds
Spectacle and QML tools for an isolated nested Wayland session. A second KWin
instance provides the virtual parent display. Select a usable render node
for the test; recent KWin requires DMA-BUF support from its parent compositor.

```sh
docker build -t gow/plasma:test apps/plasma/tests
docker run -d --name gow-plasma-test \
  --cap-add SYS_ADMIN --cap-add DAC_READ_SEARCH --device /dev/fuse \
  --device /dev/dri/renderD128 -e 'GOW_REQUIRED_DEVICES=/dev/dri/* /dev/fuse' \
  --security-opt seccomp=unconfined --security-opt apparmor=unconfined \
  --security-opt systempaths=unconfined \
  -e XDG_RUNTIME_DIR=/tmp -e HOME=/home/retro \
  -v "$PWD/apps/plasma/tests:/smoke:ro" \
  gow/plasma:test 'bash /smoke/headless-session.sh'
```

This does not connect to an existing Wolf session. Inspect the logs, check
Discover/portal/Flatpak behavior on its private session bus, then log out and
verify the test container exits. Hardware acceleration and Moonlight input
still need validation in a real Wolf session.
