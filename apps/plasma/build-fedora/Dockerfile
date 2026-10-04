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
        /usr/local/bin/kwin_wayland_wrapper /usr/local/bin/gow-power-off \
        /etc/cont-init.d/40-plasma.sh \
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
