#!/usr/bin/env bash
#
# Brave Browser Installer (Idempotent Version)
# Checks for existing repo and installation before execution.

set -euo pipefail

readonly LOG_PREFIX="[BRAVE-INSTALL]"
readonly BRAVE_REPO="https://brave-browser-rpm-release.s3.brave.com/brave-browser.repo"
readonly BRAVE_KEY="https://brave-browser-rpm-release.s3.brave.com/brave-core.asc"

log_info()    { printf "%s (INFO): %s\n" "${LOG_PREFIX}" "$*"; }
log_success() { printf "%s (OK): %s\n" "${LOG_PREFIX}" "$*"; }

main() {
  [[ "${EUID}" -ne 0 ]] && exec sudo "$0" "$@"

  # 1. Check Repo
  if ! zypper repos | grep -q "brave-browser"; then
    log_info "Adding Brave repository..."
    rpm --import "${BRAVE_KEY}"
    zypper addrepo -fG "${BRAVE_REPO}" brave-browser
  else
    log_info "Brave repository already exists. Skipping..."
  fi

  # 2. Check Package
  if ! rpm -q brave-browser &>/dev/null; then
    log_info "Installing Brave Browser..."
    env ZYPP_CURL2=1 zypper --non-interactive install brave-browser
    log_success "Installation complete."
  else
    log_success "Brave Browser is already installed."
  fi
}

main "$@"
