#!/usr/bin/env bash
#
# openSUSE Tumbleweed Post-Install Orchestrator (Idempotent)
# logic: Skips steps already completed to allow safe re-runs.

set -euo pipefail
IFS=$'\n\t'

readonly LOG_PREFIX="[SYSTEM-OPT]"
readonly ZYPP_CONF="/etc/zypp/zypp.conf"
readonly PACKMAN_URL="https://ftp.gwdg.de/pub/linux/misc/packman/suse/openSUSE_Tumbleweed/Essentials/"

readonly TARGET_REMOVALS=(
  "baobab" "cheese" "dconf-editor" "evince" "evolution" "firefox" "gimp"
  "gnome-boxes" "gnome-calculator" "gnome-calendar" "gnome-characters"
  "gnome-chess" "gnome-clocks" "gnome-connections" "gnome-contacts"
  "gnome-disk-utility" "gnome-extensions" "gnome-font-viewer" "gnome-logs"
  "gnome-mahjongg" "gnome-maps" "gnome-mines" "gnome-music" "gnome-photos"
  "gnome-software" "gnome-sudoku" "gnome-system-monitor" "gnome-tour"
  "gnome-tweaks" "gnome-user-docs" "gnome-weather" "gpk-update-viewer"
  "iagno" "libreoffice-*" "lightsoff" "opensuse-welcome" "quadrapassel"
  "rhythmbox" "seahorse" "shotwell" "simple-scan" "snapshot" "swell-foop"
  "totem" "xscreensaver" "xterm" "yelp"
)

readonly CODEC_PACKAGES=("ffmpeg-7" "lame" "vlc-codecs" "libavcodec-full" "gstreamer-plugins-bad" "gstreamer-plugins-ugly" "gstreamer-plugins-libav")

log_info()    { printf "%s (INFO): %s\n" "${LOG_PREFIX}" "$*"; }
log_success() { printf "%s (OK): %s\n" "${LOG_PREFIX}" "$*"; }

optimize_zypper() {
  # Check if our specific config is already present to avoid redundant writes
  if grep -q "download.max_concurrent_connections = 10" "$ZYPP_CONF" 2>/dev/null; then
    log_info "Zypper already optimized. Skipping..."
    return
  fi

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
  if ! zypper repos | grep -q "packman-essentials"; then
    log_info "Adding Packman repository..."
    zypper addrepo --refresh --priority 90 --name "Packman Essentials" "${PACKMAN_URL}" packman-essentials
  else
    log_info "Packman repository already present."
  fi

  log_info "Ensuring codecs are installed and vendor is switched..."
  env ZYPP_CURL2=1 ZYPP_PCK_PRELOAD=1 zypper --non-interactive --gpg-auto-import-keys refresh
  env ZYPP_CURL2=1 ZYPP_PCK_PRELOAD=1 zypper --non-interactive dist-upgrade --from packman-essentials --allow-vendor-change --no-recommends
  zypper --non-interactive install --no-recommends "${CODEC_PACKAGES[@]}"
}

cleanup_bloat() {
  log_info "Cleaning bloat..."
  # Zypper remove is naturally idempotent (won't error if already gone)
  zypper --non-interactive remove --clean-deps "${TARGET_REMOVALS[@]}" || true

  # Only add locks for packages not already locked
  local current_locks
  current_locks=$(zypper locks)
  for pkg in "${TARGET_REMOVALS[@]}"; do
    if ! echo "$current_locks" | grep -q "$pkg"; then
       zypper addlock "$pkg"
    fi
  done
}

optimize_performance() {
  log_info "Ensuring performance services are active..."
  systemctl enable --now fstrim.timer
  systemctl mask packagekit.service

  if [[ ! -f /etc/systemd/zram-generator.conf ]]; then
    log_info "Configuring zRAM..."
    if ! rpm -q zram-generator &>/dev/null; then
      zypper --non-interactive install zram-generator
    fi
    cat > /etc/systemd/zram-generator.conf <<EOF
[zram0]
zram-size = ram / 2
compression-algorithm = zstd
EOF
    systemctl daemon-reload
    systemctl start /dev/zram0
  else
    log_info "zRAM already configured."
  fi
}

main() {
  [[ "${EUID}" -ne 0 ]] && exec sudo "$0" "$@"

  # Snapper check
  if command -v snapper >/dev/null && ! snapper list | grep -q "Pre-Optimizer Run"; then
    log_info "Creating rollback snapshot..."
    snapper create --description "Pre-Optimizer Run"
  fi

  optimize_zypper
  configure_codecs
  cleanup_bloat
  optimize_performance

  log_success "Orchestration complete."
}

main "$@"
