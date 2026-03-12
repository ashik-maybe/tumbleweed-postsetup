#!/usr/bin/env bash
#
# Podman (Docker Replacement) Installer/Remover
# Logic: Idempotent installation or complete removal based on flags.
# Usage:
#   To install: ./install-podman.sh
#   To remove:  ./install-podman.sh --remove

set -euo pipefail

readonly LOG_PREFIX="[PODMAN-MGMT]"
readonly PACKAGES=("podman" "podman-compose" "podman-docker" "buildah" "skopeo")

log_info()    { printf "%s (INFO): %s\n" "${LOG_PREFIX}" "$*"; }
log_success() { printf "%s (OK): %s\n" "${LOG_PREFIX}" "$*"; }

install_podman() {
  log_info "Ensuring Podman stack is installed..."
  # Zypper install is naturally idempotent
  env ZYPP_CURL2=1 zypper --non-interactive install "${PACKAGES[@]}"

  log_info "Enabling Podman socket..."
  systemctl enable --now podman.socket

  log_success "Podman is ready. 'podman-docker' has mapped 'docker' to 'podman'."
}

remove_podman() {
  log_info "Removing Podman stack and configurations..."

  # 1. Stop and disable socket/service
  systemctl disable --now podman.socket podman.service 2>/dev/null || true

  # 2. Uninstall packages and clean dependencies
  zypper --non-interactive remove --clean-deps "${PACKAGES[@]}"

  log_success "Podman stack removed."
}

main() {
  [[ "${EUID}" -ne 0 ]] && exec sudo "$0" "$@"

  local action="install"

  # Simple argument parsing
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -r|--remove)
        action="remove"
        shift
        ;;
      *)
        shift
        ;;
    esac
  done

  if [[ "$action" == "remove" ]]; then
    remove_podman
  else
    install_podman
  fi
}

main "$@"
