#!/usr/bin/env bash
#
# Gear Lever Installer (AppImage Management)
# logic: Ensures Flatpak/Flathub exists, then installs Gear Lever for the user.

set -euo pipefail
IFS=$'\n\t'

readonly LOG_PREFIX="[GEAR-LEVER-SETUP]"
readonly REAL_USER="${SUDO_USER:-$USER}"
readonly APP_ID="it.mijorus.gearlever"

log_info()    { printf "%s (INFO): %s\n" "${LOG_PREFIX}" "$*"; }
log_success() { printf "%s (OK): %s\n" "${LOG_PREFIX}" "$*"; }
log_error()   { printf "%s (ERROR): %s\n" "${LOG_PREFIX}" "$*"; exit 1; }

check_requirements() {
    # 1. Check if Flatpak is installed
    if ! command -v flatpak &>/dev/null; then
        log_error "Flatpak is not installed. Please run your Flatpak setup script first."
    fi

    # 2. Check if Flathub remote exists
    if ! flatpak remotes | grep -q "flathub"; then
        log_error "Flathub remote not found. Please run your Flatpak setup script first."
    fi
}

install_gearlever() {
    # Idempotent check: search only user-installed apps
    if ! sudo -u "$REAL_USER" flatpak list --user --app | grep -q "$APP_ID"; then
        log_info "Installing Gear Lever for $REAL_USER..."
        sudo -u "$REAL_USER" flatpak install --user -y flathub "$APP_ID"
        log_success "Gear Lever installed successfully."
    else
        log_info "Gear Lever is already installed for $REAL_USER."
    fi
}

main() {
    # Require root to handle potential sudo -u calls correctly
    [[ "${EUID}" -ne 0 ]] && exec sudo "$0" "$@"

    check_requirements
    install_gearlever
}

main "$@"
