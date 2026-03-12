#!/usr/bin/env bash
#
# Flatpak Support Adder for openSUSE Tumbleweed
# logic: Root for system binaries/repo, User for applications.

set -euo pipefail
IFS=$'\n\t'

readonly LOG_PREFIX="[FLATPAK-SETUP]"
# Identify the actual user if running under sudo
readonly REAL_USER="${SUDO_USER:-$USER}"

log_info()    { printf "%s (INFO): %s\n" "${LOG_PREFIX}" "$*"; }
log_success() { printf "%s (OK): %s\n" "${LOG_PREFIX}" "$*"; }

setup_core_flatpak() {
    # 1. Install Flatpak binaries (Requires Root)
    if ! command -v flatpak &>/dev/null; then
        log_info "Installing Flatpak system binaries..."
        zypper --non-interactive install --no-recommends flatpak
    fi

    # 2. Add Flathub remote (Requires Root for system-wide access)
    if ! flatpak remotes | grep -q "flathub"; then
        log_info "Adding Flathub remote to system..."
        flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
    fi
}

install_flatseal() {
    local app_id="com.github.tchx84.Flatseal"

    # Check and Install as the REAL_USER
    if ! sudo -u "$REAL_USER" flatpak list --user --app | grep -q "$app_id"; then
        log_info "Installing Flatseal for user: $REAL_USER..."
        sudo -u "$REAL_USER" flatpak install --user -y flathub "$app_id"
    else
        log_info "Flatseal is already installed for $REAL_USER."
    fi
}

install_warehouse() {
    local app_id="io.github.flattool.Warehouse"

    if ! sudo -u "$REAL_USER" flatpak list --user --app | grep -q "$app_id"; then
        log_info "Installing Warehouse for user: $REAL_USER..."
        sudo -u "$REAL_USER" flatpak install --user -y flathub "$app_id"
    else
        log_info "Warehouse is already installed for $REAL_USER."
    fi
}

main() {
    # Self-elevate to root for the system-level tasks
    [[ "${EUID}" -ne 0 ]] && exec sudo "$0" "$@"

    # 1. System tasks (as root)
    setup_core_flatpak

    # 2. User tasks (dropping privileges internally)
    install_flatseal
    install_warehouse

    log_success "Setup complete. Core is System; Apps are User ($REAL_USER)."
}

main "$@"
