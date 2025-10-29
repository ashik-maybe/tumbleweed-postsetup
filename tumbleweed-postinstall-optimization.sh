#!/usr/bin/env bash
#
# openSUSE Tumbleweed Post-Install Optimizer
# - Speed up zypper
# - Remove unused bloat
# - Ensure full multimedia support via Packman
# - Enable fstrim for SSDs
#
set -euo pipefail
IFS=$'\n\t'

# === CONFIG ===
PACKAGES_TO_REMOVE=(
  baobab
  cheese
  dconf-editor
  evince
  evolution
  firefox
  gimp
  gnome-boxes
  gnome-calendar
  gnome-characters
  gnome-chess
  gnome-connections
  gnome-contacts
  gnome-disk-utility
  gnome-font-viewer
  gnome-mahjongg
  gnome-maps
  gnome-mines
  gnome-music
  gnome-photos
  gnome-software
  gnome-sudoku
  gnome-tour
  gnome-tweaks
  gnome-user-docs
  gnome-weather
  gpk-update-viewer
  libreoffice-*
  lightsoff
  opensuse-welcome
  quadrapassel
  rhythmbox
  seahorse
  shotwell
  simple-scan
  swell-foop
  totem
  xscreensaver
  xterm
  yelp
)

# === UTILITIES ===
if [ -t 1 ]; then
  RED=$'\e[31m'; GREEN=$'\e[32m'; YELLOW=$'\e[33m'; BLUE=$'\e[34m'; BOLD=$'\e[1m'; NORMAL=$'\e[0m'
else
  RED=''; GREEN=''; YELLOW=''; BLUE=''; BOLD=''; NORMAL=''
fi

info()    { printf '%b %s\n' "${BLUE}[INFO]${NORMAL}"    "$*"; }
success() { printf '%b %s\n' "${GREEN}[OK]${NORMAL}"     "$*"; }
warn()    { printf '%b %s\n' "${YELLOW}[WARN]${NORMAL}"  "$*"; }
error()   { printf '%b %s\n' "${RED}[ERROR]${NORMAL}"    "$*"; }

ensure_root() {
  if [ "$(id -u)" -ne 0 ]; then
    exec sudo "$0" "$@"
  fi
}

# === STEP 1: Optimize zypper ===
optimize_zypper() {
  info "Optimizing zypper for speed..."

  # Install deltarpm if missing
  if ! rpm -q deltarpm &>/dev/null; then
    zypper install -y --no-recommends deltarpm
  fi

  # Verify we're using official repos (MirrorCache-compatible)
  if ! zypper lr -u 2>/dev/null | grep -q 'download\.opensuse\.org'; then
    warn "Non-standard repos detected. Mirror optimization may be limited."
  fi

  # Tune zypp.conf
  cat > /etc/zypp/zypp.conf <<EOF
[main]
gpgcheck = true
solver.onlyRequires = true
deltarpm = true
deltarpm.always = true
repo.refresh.minimal-age = 3600
EOF

  success "zypper optimized (deltarpm + fast mirrors enabled)."
}

# === STEP 2: Remove bloat ===
remove_bloat() {
  info "Removing unused default packages..."

  local to_remove=()
  for pkg in "${PACKAGES_TO_REMOVE[@]}"; do
    if [[ "$pkg" == *"*"* ]]; then
      while IFS= read -r match; do
        to_remove+=("$match")
      done < <(rpm -qa "$pkg" 2>/dev/null || true)
    else
      if rpm -q --quiet "$pkg" 2>/dev/null; then
        to_remove+=("$pkg")
      fi
    fi
  done

  if [ ${#to_remove[@]} -eq 0 ]; then
    success "No bloat packages found to remove."
    return
  fi

  printf "  Removing: %s\n" "${to_remove[@]}"
  zypper remove -y --clean-deps "${to_remove[@]}"
  success "Bloat removal complete."
}

# === STEP 3: Full ffmpeg + codecs via Packman ===
enable_packman_ffmpeg() {
  info "Setting up full multimedia support via Packman..."

  # Add Packman repo (priority 90) — using confirmed-working GWDG mirror
  if ! zypper lr | grep -q -i packman; then
    zypper addrepo -cfp 90 'https://ftp.gwdg.de/pub/linux/misc/packman/suse/openSUSE_Tumbleweed/' packman
  fi

  zypper refresh

  # Switch multimedia stack to Packman
  zypper dup --from packman --allow-vendor-change -y

  # Verify H.264 encoding support (indicates full ffmpeg)
  if ffmpeg -codecs 2>/dev/null | grep -q '.*ENC.*libx264'; then
    success "Full ffmpeg with proprietary codecs confirmed."
  else
    warn "ffmpeg may be missing some codecs. Reboot or relogin may help."
  fi
}

# === STEP 4: Enable fstrim for SSDs ===
enable_fstrim() {
  info "Checking fstrim.timer status..."
  if systemctl is-active --quiet fstrim.timer; then
    success "fstrim.timer is already active."
  else
    info "Enabling and starting fstrim.timer (for SSD optimization)..."
    systemctl enable --now fstrim.timer
    success "fstrim.timer enabled. TRIM will run weekly."
  fi
}

# === STEP 5: Clean up orphaned packages ===
cleanup_orphans() {
  info "Cleaning up orphaned packages..."
  local orphans
  orphans=$(zypper packages --orphaned | tail -n +6 | awk '{print $3}' | grep -v '^$')
  if [ -z "$orphans" ]; then
    success "No orphaned packages found."
    return
  fi
  printf "  Removing orphans: %s\n" $orphans
  zypper remove -y --clean-deps $orphans
  success "Orphan cleanup complete."
}

# === MAIN ===
main() {
  ensure_root

  echo "${BOLD}openSUSE Tumbleweed Optimizer${NORMAL}"
  echo "This will:"
  echo "  1. Speed up zypper (deltarpm + fast mirrors)"
  echo "  2. Remove unused GNOME/Firefox/LibreOffice bloat"
  echo "  3. Enable full multimedia via Packman (ffmpeg, codecs)"
  echo "  4. Cleanup orphaned packages"
  echo "  5. Enable fstrim.timer for SSD longevity"
  echo
  read -p "Continue? (y/N): " -n1 -r
  echo
  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    exit 0
  fi

  optimize_zypper
  remove_bloat
  enable_packman_ffmpeg
  cleanup_orphans
  enable_fstrim

  success "Optimization complete! Reboot if you removed core desktop components."
}

main "$@"
