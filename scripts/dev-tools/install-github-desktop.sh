#!/usr/bin/env bash
#
# GitHub Desktop (Shiftkey Mirror) Installer
# Logic: Idempotent setup of the mwt-packages repo and installation.

set -euo pipefail

readonly LOG_PREFIX="[GHD-INSTALL]"
readonly GPG_KEY="https://mirror.mwt.me/shiftkey-desktop/gpgkey"
readonly REPO_PATH="/etc/zypp/repos.d/mwt-packages.repo"

log_info()    { printf "%s (INFO): %s\n" "${LOG_PREFIX}" "$*"; }
log_success() { printf "%s (OK): %s\n" "${LOG_PREFIX}" "$*"; }

main() {
  [[ "${EUID}" -ne 0 ]] && exec sudo "$0" "$@"

  # 1. Idempotent Repository Setup
  if [[ ! -f "$REPO_PATH" ]]; then
    log_info "Importing GPG key and adding GitHub Desktop repo..."
    rpm --import "$GPG_KEY"

    # Use cat/tee to avoid 'sh -c' nesting issues
    cat <<EOF | tee "$REPO_PATH" > /dev/null
[mwt-packages]
name=GitHub Desktop
baseurl=https://mirror.mwt.me/shiftkey-desktop/rpm
enabled=1
autorefresh=1
type=rpm-md
gpgcheck=1
repo_gpgcheck=1
gpgkey=$GPG_KEY
EOF
  else
    log_info "GitHub Desktop repository already exists. Skipping..."
  fi

  # 2. Idempotent Installation
  if ! rpm -q github-desktop &>/dev/null; then
    log_info "Installing GitHub Desktop..."
    # Refresh only the new repo to speed things up
    zypper --non-interactive refresh mwt-packages
    env ZYPP_CURL2=1 zypper --non-interactive install github-desktop
    log_success "GitHub Desktop installed successfully."
  else
    log_success "GitHub Desktop is already installed."
  fi
}

main "$@"
