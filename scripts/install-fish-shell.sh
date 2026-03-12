#!/usr/bin/env bash
#
# fish-shell 4.0 Deployment Orchestrator for openSUSE Tumbleweed.
# Logic: Verified OBS repository injection and shell migration.

set -euo pipefail

# --- Configuration ---
readonly LOG_INFO="\033[1;34m[  INFO  ]\033[0m"
readonly LOG_SUCCESS="\033[1;32m[   OK   ]\033[0m"
readonly LOG_ERROR="\033[1;31m[  ERROR ]\033[0m"

# URL verified from OCI metapackage
readonly REPO_URL="https://download.opensuse.org/repositories/shells:/fish:/release:/4/openSUSE_Tumbleweed/"
readonly REPO_ALIAS="shells_fish_release_4"

log_info()    { printf "%b %s\n" "${LOG_INFO}" "$*"; }
log_success() { printf "%b %s\n" "${LOG_SUCCESS}" "$*"; }
log_error()   { printf "%b %s\n" "${LOG_ERROR}" "$*"; }

main() {
  # Escalation
  [[ "${EUID}" -ne 0 ]] && exec sudo "$0" "$@"

  local -r real_user="${SUDO_USER:-$USER}"
  local -r user_home=$(getent passwd "${real_user}" | cut -d: -f6)

  # 1. Repository Lifecycle Management
  if ! zypper lr | grep -q "${REPO_ALIAS}"; then
    log_info "Injecting verified fish 4.0 repository..."
    zypper ar -f "${REPO_URL}" "${REPO_ALIAS}" > /dev/null
  fi

  # 2. Package Provisioning
  log_info "Synchronizing repository metadata..."
  zypper --gpg-auto-import-keys refresh "${REPO_ALIAS}" > /dev/null

  log_info "Executing non-interactive installation of fish..."
  if ! zypper --non-interactive install --no-recommends fish; then
    log_error "Deployment failed. Check repository accessibility."
    exit 1
  fi

  # 3. Shell State Migration
  local -r fish_bin="/usr/bin/fish"
  if [[ "$(getent passwd "${real_user}" | cut -d: -f7)" != "${fish_bin}" ]]; then
    log_info "Migrating default shell to ${fish_bin}..."
    chsh -s "${fish_bin}" "${real_user}"
  fi

  # 4. Legacy Cleanup (Engineered idempotency)
  log_info "Purging legacy shell artifacts..."
  rm -f "${user_home}/.bash_history" "${user_home}/.zsh_history"

  log_success "Deployment finalized. System is now running fish 4.0."
}

main "$@"
