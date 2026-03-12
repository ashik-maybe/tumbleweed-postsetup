#!/usr/bin/env bash
#
# VS Code Installer for openSUSE Tumbleweed
# Logic: Idempotent setup of Microsoft RPM repo and package installation.

set -euo pipefail

readonly LOG_PREFIX="[VSCODE-INSTALL]"
readonly MS_GPG_KEY="https://packages.microsoft.com/keys/microsoft.asc"
readonly REPO_PATH="/etc/zypp/repos.d/vscode.repo"

log_info()    { printf "%s (INFO): %s\n" "${LOG_PREFIX}" "$*"; }
log_success() { printf "%s (OK): %s\n" "${LOG_PREFIX}" "$*"; }

main() {
  [[ "${EUID}" -ne 0 ]] && exec sudo "$0" "$@"

  # Idempotent Repository Setup
  if [[ ! -f "$REPO_PATH" ]]; then
    log_info "Importing Microsoft GPG key..."
    rpm --import "$MS_GPG_KEY"

    log_info "Adding VS Code repository..."
    # Using 'tee' to create the repo file directly as per official docs
    echo -e "[code]\nname=Visual Studio Code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\nautorefresh=1\ntype=rpm-md\ngpgcheck=1\ngpgkey=$MS_GPG_KEY" | tee "$REPO_PATH" > /dev/null
  else
    log_info "VS Code repository already exists. Skipping..."
  fi

  # Idempotent Package Installation
  if ! rpm -q code &>/dev/null; then
    log_info "Installing VS Code..."
    # Ensure metadata is fresh for the new repo
    zypper --non-interactive refresh code
    env ZYPP_CURL2=1 zypper --non-interactive install code
    log_success "VS Code installed successfully."
  else
    log_success "VS Code is already installed."
  fi
}

main "$@"
