#!/usr/bin/env bash
#
# Zed Editor Installer/Updater
# Logic: Forces a download and replacement of the Zed binary to ensure latest version.

set -euo pipefail

readonly LOG_PREFIX="[ZED-INSTALL]"
readonly ZED_BIN="$HOME/.local/bin/zed"

log_info()    { printf "%s (INFO): %s\n" "${LOG_PREFIX}" "$*"; }
log_success() { printf "%s (OK): %s\n" "${LOG_PREFIX}" "$*"; }

main() {
  # Notify user if we are updating or installing fresh
  if [[ -f "$ZED_BIN" ]] || command -v zed &>/dev/null; then
    log_info "Zed detected. Downloading latest version to replace existing binary..."
  else
    log_info "Zed not found. Starting fresh installation..."
  fi

  # Official Zed installation script (downloads and places binary in ~/.local/bin)
  # We pipe to sh to execute immediately.
  if curl -f https://zed.dev/install.sh | sh; then
    log_success "Zed Editor has been installed/updated successfully at $ZED_BIN"
  else
    printf "%s (ERR): Failed to download or install Zed.\n" "${LOG_PREFIX}" >&2
    exit 1
  fi
}

main "$@"
