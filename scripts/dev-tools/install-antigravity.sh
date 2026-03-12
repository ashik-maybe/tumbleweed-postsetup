#!/usr/bin/env bash
#
# Google Antigravity Installer for Tumbleweed
# Logic: Idempotent repo setup using openSUSE native paths.

set -euo pipefail

readonly LOG_PREFIX="[ANTIGRAVITY-INSTALL]"
# openSUSE specific repo path
readonly REPO_PATH="/etc/zypp/repos.d/antigravity.repo"

log_info()    { printf "%s (INFO): %s\n" "${LOG_PREFIX}" "$*"; }
log_success() { printf "%s (OK): %s\n" "${LOG_PREFIX}" "$*"; }

main() {
  [[ "${EUID}" -ne 0 ]] && exec sudo "$0" "$@"

  # 1. Idempotent Repository Setup
  if [[ ! -f "$REPO_PATH" ]]; then
    log_info "Configuring Antigravity repo in /etc/zypp/repos.d/..."
    cat <<EOF | tee "$REPO_PATH" > /dev/null
[antigravity-rpm]
name=Antigravity RPM Repository
baseurl=https://us-central1-yum.pkg.dev/projects/antigravity-auto-updater-dev/antigravity-rpm
enabled=1
autorefresh=1
type=rpm-md
gpgcheck=0
EOF
  else
    log_info "Antigravity repo already exists. Skipping..."
  fi

  # 2. Idempotent Installation
  if ! rpm -q antigravity &>/dev/null; then
    log_info "Installing Antigravity..."
    # Refreshing the specific repo alias defined in the [header]
    zypper --non-interactive refresh antigravity-rpm
    env ZYPP_CURL2=1 zypper --non-interactive install antigravity
    log_success "Antigravity installed."
  else
    log_success "Antigravity is already installed."
  fi
}

main "$@"
