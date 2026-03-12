#!/usr/bin/env bash
#
# openSUSE Tumbleweed Post-Install Orchestrator (Workstation Edition)
#
# Logic: Parallelizes Zypper, Prunes Bloat, Migrates Codecs, Configures Dev Environment.

set -euo pipefail
IFS=$'\n\t'

# --- Configuration ---
readonly LOG_PREFIX="[SYSTEM-OPT]"
readonly ZYPP_CONF="/etc/zypp/zypp.conf"
readonly PACKMAN_URL="https://ftp.gwdg.de/pub/linux/misc/packman/suse/openSUSE_Tumbleweed/Essentials/"

# Targeted bloat removal
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

readonly CODEC_PACKAGES=("ffmpeg-7" "lame" "vlc-codecs" "libavcodec-full" "libopenh264")

# --- Logging ---
log_info()    { printf "%s (INFO): %s\n" "${LOG_PREFIX}" "$*"; }
log_success() { printf "%s (OK): %s\n" "${LOG_PREFIX}" "$*"; }

# --- Modules ---

optimize_zypper() {
  log_info "Configuring Zypper for high-concurrency..."

  # DeltaRPM is disabled to save CPU cycles during package reconstruction.
  # Re-enable only if on a metered or very slow internet connection.
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
  log_success "Zypper throughput optimized (DeltaRPM disabled)."
}

configure_codecs() {
  log_info "Performing Packman Vendor Change..."
  if ! zypper repos | grep -q "packman"; then
    zypper addrepo --refresh --priority 90 --name "Packman Essentials" "${PACKMAN_URL}" packman-essentials
  fi

  env ZYPP_CURL2=1 ZYPP_PCK_PRELOAD=1 \
    zypper --non-interactive --gpg-auto-import-keys refresh
    
  env ZYPP_CURL2=1 ZYPP_PCK_PRELOAD=1 \
    zypper --non-interactive dist-upgrade --from packman-essentials --allow-vendor-change --no-recommends

  zypper --non-interactive install --no-recommends "${CODEC_PACKAGES[@]}"
}

setup_dev_tools() {
  log_info "Configuring development environment (Bun & UV)..."

  # Install Bun (JS/TS runtime)
  if ! command -v bun &>/dev/null; then
    curl -fsSL https://bun.sh/install | bash
  fi

  # Install UV (Fast Python package manager)
  if ! command -v uv &>/dev/null; then
    curl -LsSf https://astral.sh/uv/install.sh | sh
  fi
  
  log_success "Dev tools (bun/uv) initialized."
}

optimize_performance() {
  log_info "Hardening system performance..."
  
  # SSD & RAM Management
  systemctl enable --now fstrim.timer
  systemctl mask packagekit.service

  # zRAM for low-end systems
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
    snapper create --description "Pre-Optimizer Run"
  fi

  optimize_zypper
  configure_codecs
  cleanup_bloat # Uses the removal list and addlock logic from previous version
  setup_dev_tools
  optimize_performance

  log_success "Orchestration complete. Please reboot."
}

main "$@"
