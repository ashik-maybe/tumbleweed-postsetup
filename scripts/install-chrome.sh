#!/usr/bin/env bash
#
# Google Chrome Stable Installer for openSUSE Tumbleweed
# Automated repository configuration and package installation.

set -euo pipefail

readonly LOG_PREFIX="[CHROME-INSTALL]"
readonly CHROME_REPO_URL="https://dl.google.com/linux/direct/google-chrome-stable_current_x86_64.rpm"
readonly CHROME_GPG_KEY="https://dl.google.com/linux/linux_signing_key.pub"

log_info()    { printf "%s (INFO): %s\n" "${LOG_PREFIX}" "$*"; }
log_success() { printf "%s (OK): %s\n" "${LOG_PREFIX}" "$*"; }
log_error()   { printf "%s (ERR): %s\n" "${LOG_PREFIX}" "$*" >&2; }

main() {
  # Ensure root privileges
  if [[ "${EUID}" -ne 0 ]]; then
    exec sudo "$0" "$@"
  fi

  log_info "Importing Google Linux Signing Key..."
  rpm --import "${CHROME_GPG_KEY}"

  log_info "Adding Google Chrome repository..."
  # -f (fail silently), -G (ignore gpg check since we imported manually), -n (name)
  zypper addrepo -fG "https://dl.google.com/linux/chrome/rpm/stable/x86_64" google-chrome

  log_info "Installing Google Chrome Stable..."
  # Use the flags tuned in your main script for speed
  env ZYPP_CURL2=1 zypper --non-interactive install google-chrome-stable

  log_success "Google Chrome is now installed and will update via 'zypper dup'."
}

main "$@"
