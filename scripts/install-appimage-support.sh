#!/usr/bin/env bash
#
# Gear Lever Installer (AppImage Management)
# logic: Simple system-wide installation.

set -euo pipefail
IFS=$'\n\t'

readonly LOG_PREFIX="[GEAR-LEVER-SETUP]"
readonly APP_ID="it.mijorus.gearlever"

log_info()    { printf "%s (INFO): %s\n" "${LOG_PREFIX}" "$*"; }
log_success() { printf "%s (OK): %s\n" "${LOG_PREFIX}" "$*"; }
log_error()   { printf "%s (ERROR): %s\n" "${LOG_PREFIX}" "$*"; exit 1; }

main() {
    # Ensure root
    [[ "${EUID}" -ne 0 ]] && exec sudo "$0" "$@"

    # 1. Dependency Check
    if ! command -v flatpak &>/dev/null || ! flatpak remotes | grep -q "flathub"; then
        log_error "Flatpak or Flathub missing. Run the Flatpak setup script first."
    fi

    # 2. Idempotent Install
    if ! flatpak list --app | grep -q "$APP_ID"; then
        log_info "Installing Gear Lever..."
        flatpak install -y flathub "$APP_ID"
        log_success "Gear Lever installed."
    else
        log_info "Gear Lever is already installed."
    fi
}

main "$@"
