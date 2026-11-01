# syntax=docker/dockerfile:1.4
ARG BASE_IMAGE=ghcr.io/games-on-whales/base:fedora
FROM ${BASE_IMAGE}

# Keep GOW's user/device/NVIDIA initialization, without a second compositor or
# a machine-oriented desktop environment package group.
RUN dnf install -y --setopt=install_weak_deps=False \
        plasma-desktop plasma-workspace kwin plasma-pa \
        plasma-discover plasma-discover-flatpak \
        dolphin konsole ark kate \
        breeze-icon-theme breeze-gtk \
        flatpak dbus-daemon dbus-tools dbus-x11 \
        xdg-desktop-portal xdg-desktop-portal-kde xdg-user-dirs \
        xorg-x11-server-Xwayland qt6-qtwayland qt6-qttools \
        mesa-dri-drivers mesa-vulkan-drivers mesa-libEGL mesa-libGL mesa-libgbm \
        egl-wayland egl-gbm google-noto-sans-fonts google-noto-emoji-color-fonts \
        procps-ng psmisc desktop-file-utils \
    && dnf clean all

# The overview/search interface imports Milou, which Fedora otherwise pulls
# in as a weak dependency along with many machine-oriented components.
RUN dnf install -y --setopt=install_weak_deps=False plasma-milou && dnf clean all

# Read AppImage metadata without executing the mounted application. 7-Zip
# handles SquashFS; newer AppImages (including Vita3K) can use DwarFS instead.
RUN dnf install -y --setopt=install_weak_deps=False python3 7zip && dnf clean all
ARG DWARFS_VERSION=0.15.8
RUN mkdir -p /opt/gow /usr/share/licenses/gow-dwarfs \
    && curl -fL --retry 3 "https://github.com/mhx/dwarfs/releases/download/v${DWARFS_VERSION}/dwarfs-universal-${DWARFS_VERSION}-Linux-x86_64" -o /opt/gow/dwarfs-universal \
    && echo '0ed66df82f9bb6671c1f898404ff4d57c263460078d46dbac8efb9d8eec271b7  /opt/gow/dwarfs-universal' | sha256sum -c - \
    && curl -fL --retry 3 "https://raw.githubusercontent.com/mhx/dwarfs/v${DWARFS_VERSION}/LICENSE" -o /usr/share/licenses/gow-dwarfs/LICENSE \
    && echo '01aacaeaa55c6d58fe8e78f1bc9904397e3428e9a381b8ca7e3352f85d52c2c7  /usr/share/licenses/gow-dwarfs/LICENSE' | sha256sum -c - \
    && curl -fL --retry 3 "https://raw.githubusercontent.com/mhx/dwarfs/v${DWARFS_VERSION}/LICENSES/MIT.txt" -o /usr/share/licenses/gow-dwarfs/MIT.txt \
    && echo 'b05785f9f18e6716bab63424b11454513b9943a222595b70411009202fc592b5  /usr/share/licenses/gow-dwarfs/MIT.txt' | sha256sum -c - \
    && curl -fL --retry 3 "https://raw.githubusercontent.com/mhx/dwarfs/v${DWARFS_VERSION}/LICENSES/GPL-3.0-or-later.txt" -o /usr/share/licenses/gow-dwarfs/GPL-3.0-or-later.txt \
    && echo 'fb981668c18a279e285fc4d83fba1e836cc84dd4daa73c9697d3cfd2d8aca6e0  /usr/share/licenses/gow-dwarfs/GPL-3.0-or-later.txt' | sha256sum -c - \
    && chmod 0755 /opt/gow/dwarfs-universal

# Discover must expose only its Flatpak backend. Native package, firmware,
# system-update and KDE Store backends are inappropriate for this image.
RUN find /usr/lib64/qt6/plugins/discover -maxdepth 1 -type f \
        ! -name 'flatpak-backend.so' -delete \
    && test -f /usr/lib64/qt6/plugins/discover/flatpak-backend.so \
    && mkdir -p /opt/gow/flathub \
    && curl -fsSL https://dl.flathub.org/repo/flathub.flatpakrepo \
        -o /opt/gow/flathub/flathub.flatpakrepo

# Discover enumerates the system installation before the user installation.
# Leave a valid empty repository, without a system remote or system apps.
RUN flatpak remote-add --system --if-not-exists flathub /opt/gow/flathub/flathub.flatpakrepo \
    && flatpak remote-delete --system flathub

COPY overlay/ /
RUN chmod 0755 /opt/gow/startup.sh /opt/gow/plasma-session \
        /opt/gow/appimage-menu \
        /usr/local/bin/kwin_wayland_wrapper /usr/local/bin/gow-power-off \
        /etc/cont-init.d/35-plasma-shm.sh /etc/cont-init.d/40-plasma.sh \
    && for entry in /etc/xdg/autostart/*powerdevil*.desktop \
        /etc/xdg/autostart/*polkit*.desktop /etc/xdg/autostart/*pam_kwallet*.desktop; do \
        if [ -f "$entry" ]; then printf '\nHidden=true\n' >> "$entry"; fi; \
    done \
    && chmod a-s /usr/bin/sudo /usr/bin/su /usr/bin/pkexec \
    && setcap -r /usr/bin/kwin_wayland \
    && rm -rf /home/retro/.local /home/retro/.cache \
    && update-desktop-database /usr/share/applications

ENV XDG_CURRENT_DESKTOP=KDE XDG_SESSION_DESKTOP=KDE XDG_SESSION_TYPE=wayland \
    KDE_SESSION_VERSION=6 KDE_FULL_SESSION=true XDG_MENU_PREFIX=plasma- LANG=C.UTF-8 \
    QT_FORCE_STDERR_LOGGING=1

WORKDIR /home/retro
ARG IMAGE_SOURCE=https://github.com/games-on-whales/gow
LABEL org.opencontainers.image.source=${IMAGE_SOURCE}
