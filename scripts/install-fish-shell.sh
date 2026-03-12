#!/usr/bin/env bash
#
# fish-shell 4.0 Deployment Orchestrator for openSUSE Tumbleweed.
# Sequence: Install -> Switch Shell -> Purge Legacy History.

set -euo pipefail

# --- Configuration ---
readonly LOG_INFO="\033[1;34m[  INFO  ]\033[0m"
readonly LOG_SUCCESS="\033[1;32m[   OK   ]\033[0m"
readonly LOG_ERROR="\033[1;31m[  ERROR ]\033[0m"

# Direct URL to the repository directory (more reliable than the .repo file for zypper)
readonly REPO_BASE_URL="https://download.opensuse.org/repositories/shells:/fish:/release:/4/openSUSE_Tumbleweed/"
readonly REPO_ALIAS="shells_fish_release_4"

# --- Internal Functions ---
log_info()    { printf "%b %s\n" "${LOG_INFO}" "$*"; }
log_success() { printf "%b %s\n" "${LOG_SUCCESS}" "$*"; }
log_error()   { printf "%b %s\n" "${LOG_ERROR}" "$*"; }

purge_legacy_history() {
  local -r user_home="${1}"
  local -r history_files=(
    "${user_home}/.bash_history"
    "${user_home}/.zsh_history"
    "${user_home}/.history"
  )

  log_info "Purging legacy shell history files..."
  for file in "${history_files[@]}"; do
    rm -f "${file}"
  done
}

main() {
  # Escalation check
  if [[ "${EUID}" -ne 0 ]]; then
    exec sudo "$0" "$@"
  fi

  local -r real_user="${SUDO_USER:-$USER}"
  local -r user_home=$(getent passwd "${real_user}" | cut -d: -f6)
  local -r fish_path="/usr/bin/fish"

  # 1. Infrastructure Setup
  if ! zypper repos | grep -q "${REPO_ALIAS}"; then
    log_info "Registering upstream repository: ${REPO_ALIAS}..."
    # -f enables autorefresh
    zypper addrepo -f "${REPO_BASE_URL}" "${REPO_ALIAS}" > /dev/null
  fi

  # 2. Package Provisioning
  log_info "Refreshing metadata and deploying fish 4.0..."
  # --gpg-auto-import-keys avoids interactive prompts for the new repo key
  if ! zypper --non-interactive --gpg-auto-import-keys refresh "${REPO_ALIAS}" > /dev/null; then
    log_error "Failed to refresh repository. Check network or URL."
    exit 1
  fi

  zypper --non-interactive install --no-recommends fish > /dev/null

  # 3. Shell Transition
  if [[ "$(getent passwd "${real_user}" | cut -d: -f7)" != "${fish_path}" ]]; then
    log_info "Updating default shell to ${fish_path} for user: ${real_user}..."
    chsh -s "${fish_path}" "${real_user}"
  fi

  # 4. Cleanup
  purge_legacy_history "${user_home}"

  log_success "Deployment finalized. fish 4.0 is now the default shell."
}

main "$@"
