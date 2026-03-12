#!/usr/bin/env bash
#
# Brave Browser Installer (Idempotent Version)
# Checks for existing repo and installation before execution.

set -euo pipefail

readonly LOG_PREFIX="[BRAVE-INSTALL]"
readonly BRAVE_REPO_URL="https://brave-browser-rpm-release.s3.brave.com/\$basearch"
readonly BRAVE_KEY="https://brave-browser-rpm-release.s3.brave.com/brave-core.asc"
readonly REPO_ALIAS="brave-browser"

log_info()    { printf "%s (INFO): %s\n" "${LOG_PREFIX}" "$*"; }
log_success() { printf "%s (OK): %s\n" "${LOG_PREFIX}" "$*"; }

main() {
    # Elevation check
    [[ "${EUID}" -ne 0 ]] && exec sudo "$0" "$@"

    # 1. Handle Repository
    if ! zypper repos | grep -q "${REPO_ALIAS}"; then
        log_info "Importing GPG key and adding Brave repository..."
        rpm --import "${BRAVE_KEY}"
        # Using -f (autorefresh) and -G (ignore GPG check during repo add as we imported it)
        zypper addrepo -fG "${BRAVE_REPO_URL}" "${REPO_ALIAS}"
    else
        log_info "Brave repository already exists. Skipping..."
    fi

    # 2. Check and Install Package
    if ! rpm -q brave-browser &>/dev/null; then
        log_info "Installing Brave Browser..."
        # ZYPP_CURL2=1 is often recommended for S3-backed repos on older zypper versions
        env ZYPP_CURL2=1 zypper --non-interactive install brave-browser
        log_success "Installation complete."
    else
        log_success "Brave Browser is already installed."
    fi
}

main "$@"
