#!/usr/bin/env bash
#
# Brave Browser Installer for openSUSE Tumbleweed
# Logic: Configures Brave RPM repository and installs the stable binary.

set -euo pipefail

readonly LOG_PREFIX="[BRAVE-INSTALL]"
readonly BRAVE_REPO="https://brave-browser-rpm-release.s3.brave.com/brave-browser.repo"
readonly BRAVE_KEY="https://brave-browser-rpm-release.s3.brave.com/brave-core.asc"

log_info()    { printf "%s (INFO): %s\n" "${LOG_PREFIX}" "$*"; }
log_success() { printf "%s (OK): %s\n" "${LOG_PREFIX}" "$*"; }

main() {
  # Privilege elevation
  if [[ "${EUID}" -ne 0 ]]; then
    exec sudo "$0" "$@"
  fi

  log_info "Importing Brave Browser GPG key..."
  rpm --import "${BRAVE_KEY}"

  log_info "Configuring Brave repository..."
  # -f (force/refresh), -G (ignore gpg check since we imported manually)
  zypper addrepo -fG "${BRAVE_REPO}" brave-browser

  log_info "Installing Brave Browser Stable..."
  env ZYPP_CURL2=1 zypper --non-interactive install brave-browser

  log_success "Brave Browser is installed. Future updates will occur via 'zypper dup'."
}

main "$@"
