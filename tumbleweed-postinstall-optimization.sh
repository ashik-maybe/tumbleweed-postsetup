#!/usr/bin/env bash
#
# openSUSE Tumbleweed Post-Install Orchestrator
# optimized for performance, proprietary codecs, and bloat removal.

set -euo pipefail
IFS=$'\n\t'

readonly LOG_PREFIX="[SYSTEM-OPT]"
readonly ZYPP_CONF="/etc/zypp/zypp.conf"
readonly PACKMAN_URL="https://ftp.gwdg.de/pub/linux/misc/packman/suse/openSUSE_Tumbleweed/Essentials/"

readonly TARGET_REMOVALS=(
  "baobab" "cheese" "dconf-editor" "evince" "evolution"
  "gimp" "gnome-boxes" "gnome-calendar" "gnome-characters" "gnome-chess" 
  "gnome-connections" "gnome-contacts" "gnome-disk-utility" "gnome-font-viewer" 
  "gnome-mahjongg" "gnome-maps" "gnome-mines" "gnome-music" "gnome-photos" 
  "gnome-software" "gnome-sudoku" "gnome-tour" "gnome-tweaks" "gnome-user-docs" 
  "gnome-weather" "gpk-update-viewer" "libreoffice-*" "lightsoff" 
  "opensuse-welcome" "quadrapassel" "rhythmbox" "seahorse" "shotwell" 
  "simple-scan" "swell-foop" "totem" "xscreensaver" "xterm" "yelp"
)

readonly CODEC_PACKAGES=("ffmpeg-7" "lame" "vlc-codecs" "libavcodec-full" "gstreamer-plugins-bad" "gstreamer-plugins-ugly" "gstreamer-plugins-libav")

log_info()    { printf "%s (INFO): %s\n" "${LOG_PREFIX}" "$*"; }
log_success() { printf "%s (OK): %s\n" "${LOG_PREFIX}" "$*"; }

optimize_zypper() {
  log_info "Optimizing Zypper (Parallel downloads, No DeltaRPM)..."
  cat > "${ZYPP_CONF}" <<EOF
[main]
gpgcheck = true
solver.onlyRequires = true
deltarpm = false
repo.refresh.minimal-age = 3600
download.max_concurrent_connections = 10
download.min_download_speed = 1024
EOF
  zypper clean --all
}

configure_codecs() {
  log_info "Enabling proprietary multimedia codecs via Packman..."
  if ! zypper repos | grep -q "packman"; then
    zypper addrepo --refresh --priority 90 --name "Packman Essentials" "${PACKMAN_URL}" packman-essentials
  fi

  env ZYPP_CURL2=1 ZYPP_PCK_PRELOAD=1 zypper --non-interactive --gpg-auto-import-keys refresh
  env ZYPP_CURL2=1 ZYPP_PCK_PRELOAD=1 zypper --non-interactive dist-upgrade --from packman-essentials --allow-vendor-change --no-recommends
  zypper --non-interactive install --no-recommends "${CODEC_PACKAGES[@]}"
}

cleanup_bloat() {
  log_info "Removing bloat and locking packages..."
  zypper --non-interactive remove --clean-deps "${TARGET_REMOVALS[@]}" || true
  zypper addlock "${TARGET_REMOVALS[@]}"
}

optimize_performance() {
  log_info "Applying performance tweaks (zRAM, fstrim)..."
  systemctl enable --now fstrim.timer
  systemctl mask packagekit.service

  if ! rpm -q zram-generator &>/dev/null; then
    zypper --non-interactive install zram-generator
    echo -e "[zram0]\nzram-size = ram / 2\ncompression-algorithm = zstd" > /etc/systemd/zram-generator.conf
    systemctl daemon-reload
    systemctl start /dev/zram0
  fi
}

main() {
  [[ "${EUID}" -ne 0 ]] && exec sudo "$0" "$@"

  if command -v snapper >/dev/null; then
    log_info "Creating rollback snapshot..."
    snapper create --description "Pre-Optimizer Run"
  fi

  optimize_zypper
  configure_codecs
  cleanup_bloat
  optimize_performance

  log_success "System optimized. Please reboot to complete the process."
}

main "$@"
