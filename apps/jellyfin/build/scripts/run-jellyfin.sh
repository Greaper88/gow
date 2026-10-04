#!/usr/bin/env bash
set -e

case "${JELLYFIN_MODE:-tv}" in
    tv|desktop) ;;
    *) echo "JELLYFIN_MODE must be tv or desktop" >&2; exit 1 ;;
esac

exec jellyfinmediaplayer "--${JELLYFIN_MODE:-tv}" --fullscreen --terminal
