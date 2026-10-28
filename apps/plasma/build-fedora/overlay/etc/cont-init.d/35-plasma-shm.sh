#!/usr/bin/env bash
set -e

# Steam's Flatpak shares the container's /dev/shm with its browser processes.
# Docker's default 64 MiB fills during login and makes the renderer restart.
read -r plasma_shm_block_size plasma_shm_blocks < <(stat -f -c '%S %b' /dev/shm)
if (( plasma_shm_block_size * plasma_shm_blocks < 1073741824 )); then
    printf '%s\n' '[plasma] Providing 1 GiB of private shared memory for desktop applications'
    # Mount a new private filesystem before starting applications. Remounting
    # an inherited host/shared filesystem could change another container's limit.
    mount -t tmpfs -o size=1G,mode=1777,nosuid,nodev,noexec shm /dev/shm
fi
unset plasma_shm_block_size plasma_shm_blocks
