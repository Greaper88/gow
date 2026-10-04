# Jellyfin Media Player

Jellyfin Media Player **1.12.0**, running fullscreen in TV mode through GOW's
Sway and native Wayland integration. Connect it to an existing Jellyfin server
to browse and play your library. This image contains the client, not the server.

## Install and use

The Ubuntu-based image is built for `linux/amd64`:

```sh
docker pull ghcr.io/greaper88/jellyfin:edge
```

`edge`, `latest`, and `1.12.0` identify the published build. Each publication
also has a `sha-<commit>` tag for selecting a particular build.

Add `assets/wolf.config.toml` to Wolf's app catalog. For a version 7 Wolf config,
change `[[apps]]` to `[[profiles.apps]]` and `[apps.runner]` to
`[profiles.apps.runner]`, and place the entry inside the desired profile.
Use Wolf's management interface/API for a running server; stop Wolf first when
editing its configuration file directly so it cannot overwrite the edit.

Open **Jellyfin Media Player**, enter the server's LAN address or hostname, and
sign in. `localhost` refers to the client container. No credentials or server
address are baked into the image, and no media mounts or incoming ports are needed.

Wolf supplies the GPU, display, audio, input, and persistent home directory.
The runner name remains `WolfJellyfin`, matching the original standalone image.
Settings and login state live in `~/.local/share/jellyfinmediaplayer/` and logs
in its `logs/` subdirectory.

## Options

- `JELLYFIN_MODE=tv` is the default; use `desktop` for desktop controls.
- Hardware decoding is controlled by the player's playback settings. Wolf's
  existing GPU selection applies to the container.
- Audio uses Wolf's PulseAudio connection. Leave audio passthrough disabled for
  the usual Moonlight audio stream.

## Build and verify

From the GOW repository root:

```sh
docker build -t gow/jellyfin:local apps/jellyfin/build
bin/test-image.sh jellyfin gow/jellyfin:local --docker-path apps
```

The Dockerfile pins the tested GOW base image by digest and verifies the official
Jellyfin package checksum. `BASE_APP_IMAGE` can be overridden by GOW's build
pipeline. Update `JELLYFIN_VERSION`, `JELLYFIN_DEB_SUITE`, and
`JELLYFIN_DEB_SHA256` together when changing the player release.

The original image rendered the fullscreen server-connect screen in an isolated
Sway session and was confirmed working through Wolf. The smoke test checks the
entrypoint, initialization, executable dependencies, and Wayland plugin. A new
base/player version still needs playback, audio, and controller checks in Wolf.

The Jellyfin-only publishing workflow builds and tests before publishing to this
fork's GHCR namespace. The standard Ubuntu app build matrix also includes it.
A Fedora variant is not included.

[Jellyfin Media Player release](https://github.com/jellyfin/jellyfin-desktop/releases/tag/v1.12.0)
and [GOW base app](https://github.com/games-on-whales/gow/tree/master/images/base-app).
