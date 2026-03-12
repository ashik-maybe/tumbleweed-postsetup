#!/usr/bin/env bash
#
# Flatpak Support Adder for openSUSE Tumbleweed
# logic: Root for system binaries/repo, User for applications.

set -euo pipefail
IFS=$'\n\t'

readonly LOG_PREFIX="[FLATPAK-SETUP]"

log_info()    { printf "%s (INFO): %s\n" "${LOG_PREFIX}" "$*"; }
log_success() { printf "%s (OK): %s\n" "${LOG_PREFIX}" "$*"; }

setup_core() {
    # Install binary
    if ! command -v flatpak &>/dev/null; then
        log_info "Installing Flatpak..."
        zypper --non-interactive install --no-recommends flatpak
    fi

    # Add Flathub
    if ! flatpak remotes | grep -q "flathub"; then
        log_info "Adding Flathub..."
        flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
    fi
}

install_flatseal() {
    if ! flatpak list --app | grep -q "com.github.tchx84.Flatseal"; then
        log_info "Installing Flatseal..."
        flatpak install -y flathub com.github.tchx84.Flatseal
    else
        log_info "Flatseal already present."
    fi
}

install_warehouse() {
    if ! flatpak list --app | grep -q "io.github.flattool.Warehouse"; then
        log_info "Installing Warehouse..."
        flatpak install -y flathub io.github.flattool.Warehouse
    else
        log_info "Warehouse already present."
    fi
}

main() {
    # Ensure root for the whole process
    [[ "${EUID}" -ne 0 ]] && exec sudo "$0" "$@"

    setup_core
    install_flatseal
    install_warehouse

    log_success "Flatpak setup complete."
}

main "$@"
