# syntax=docker/dockerfile:1
ARG BASE_APP_IMAGE=ghcr.io/games-on-whales/base-app@sha256:1d7b61da242e767bc5c80c5fe897392b6a9e6854345d3dea6d2f799e7ea98a14
FROM ${BASE_APP_IMAGE}

ARG DEBIAN_FRONTEND=noninteractive
ARG JELLYFIN_VERSION=1.12.0
ARG JELLYFIN_DEB_SUITE=noble
ARG JELLYFIN_DEB_SHA256=2851e97a41494c1b4d890a6d7a5aeb50b31ea9e2523995b589547fd8ad07db42

RUN set -eux; \
    test "$(dpkg --print-architecture)" = amd64; \
    apt-get update; \
    apt-get install -y --no-install-recommends ca-certificates curl qtwayland5; \
    curl -fL --retry 3 \
      "https://github.com/jellyfin/jellyfin-desktop/releases/download/v${JELLYFIN_VERSION}/jellyfin-media-player_${JELLYFIN_VERSION}-${JELLYFIN_DEB_SUITE}.deb" \
      -o /tmp/jellyfin-media-player.deb; \
    echo "${JELLYFIN_DEB_SHA256}  /tmp/jellyfin-media-player.deb" | sha256sum -c -; \
    apt-get install -y --no-install-recommends /tmp/jellyfin-media-player.deb; \
    rm -f /tmp/jellyfin-media-player.deb; \
    rm -rf /var/lib/apt/lists/*

COPY --chmod=755 scripts/startup.sh /opt/gow/startup-app.sh
COPY --chmod=755 scripts/run-jellyfin.sh /opt/gow/run-jellyfin.sh

ENV RUN_SWAY=1 \
    QT_QPA_PLATFORM=wayland \
    JELLYFIN_MODE=tv \
    XDG_RUNTIME_DIR=/tmp/.X11-unix

ARG IMAGE_SOURCE=https://github.com/Greaper88/gow
LABEL org.opencontainers.image.source="${IMAGE_SOURCE}" \
      org.opencontainers.image.title="Jellyfin Media Player for Wolf" \
      org.opencontainers.image.description="Standalone Jellyfin client using GOW display, audio and input integration" \
      org.opencontainers.image.version="${JELLYFIN_VERSION}"
