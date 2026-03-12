#!/usr/bin/env bash
#
# Zellij Binary Installer
# logic: Downloads musl binary, extracts to ~/bin, updates PATH for bash/fish/zsh.

set -euo pipefail

readonly LOG_PREFIX="[ZELLIJ-INSTALL]"
readonly BIN_DIR="$HOME/bin"
readonly TEMP_DIR="/tmp/zellij_install"
readonly DL_URL="https://github.com/zellij-org/zellij/releases/latest/download/zellij-x86_64-unknown-linux-musl.tar.gz"

log_info()    { printf "%s (INFO): %s\n" "${LOG_PREFIX}" "$*"; }
log_success() { printf "%s (OK): %s\n" "${LOG_PREFIX}" "$*"; }

setup_path() {
    local current_shell
    current_shell=$(basename "$SHELL")

    case "$current_shell" in
        fish)
            # Use fish_add_path for built-in idempotency
            if ! fish -c "echo \$fish_user_paths" | grep -q "$BIN_DIR"; then
                log_info "Adding $BIN_DIR to fish path..."
                fish -c "fish_add_path $BIN_DIR"
            fi
            ;;
        bash)
            if [[ ! ":$PATH:" == *":$BIN_DIR:"* ]]; then
                log_info "Adding $BIN_DIR to .bashrc..."
                echo "export PATH=\"\$HOME/bin:\$PATH\"" >> "$HOME/.bashrc"
            fi
            ;;
        zsh)
            if [[ ! ":$PATH:" == *":$BIN_DIR:"* ]]; then
                log_info "Adding $BIN_DIR to .zshrc..."
                echo "export PATH=\"\$HOME/bin:\$PATH\"" >> "$HOME/.zshrc"
            fi
            ;;
    esac
}

main() {
    # 1. Prepare Environment
    mkdir -p "$BIN_DIR"
    mkdir -p "$TEMP_DIR"

    # 2. Download and Extract
    log_info "Downloading latest Zellij..."
    curl -L "$DL_URL" -o "$TEMP_DIR/zellij.tar.gz"

    log_info "Extracting binary to $BIN_DIR..."
    tar -xzf "$TEMP_DIR/zellij.tar.gz" -C "$BIN_DIR"
    chmod +x "$BIN_DIR/zellij"

    # 3. Path Configuration
    setup_path

    # 4. Cleanup
    rm -rf "$TEMP_DIR"

    log_success "Zellij installed to $BIN_DIR"
    log_info "Restart your shell or source your config to use 'zellij'."
}

main "$@"
