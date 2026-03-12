#!/usr/bin/env bash
#
# Google Chrome Stable Installer (Idempotent Version)
# Checks for existing repo and installation before execution.

set -euo pipefail

readonly LOG_PREFIX="[CHROME-INSTALL]"
readonly CHROME_GPG_KEY="https://dl.google.com/linux/linux_signing_key.pub"
readonly CHROME_REPO_ADDR="https://dl.google.com/linux/chrome/rpm/stable/x86_64"

log_info()    { printf "%s (INFO): %s\n" "${LOG_PREFIX}" "$*"; }
log_success() { printf "%s (OK): %s\n" "${LOG_PREFIX}" "$*"; }

main() {
  [[ "${EUID}" -ne 0 ]] && exec sudo "$0" "$@"

  # 1. Check Repo
  if ! zypper repos | grep -q "google-chrome"; then
    log_info "Adding Google Chrome repository..."
    rpm --import "${CHROME_GPG_KEY}"
    zypper addrepo -fG "${CHROME_REPO_ADDR}" google-chrome
  else
    log_info "Google Chrome repository already exists. Skipping..."
  fi

  # 2. Check Package
  if ! rpm -q google-chrome-stable &>/dev/null; then
    log_info "Installing Google Chrome..."
    env ZYPP_CURL2=1 zypper --non-interactive install google-chrome-stable
    log_success "Installation complete."
  else
    log_success "Google Chrome is already installed."
  fi
}

main "$@"
