#!/usr/bin/env bash
set -euo pipefail

BREW_PREFIX="/opt/homebrew"

install_xcode_tools() {
  echo ">>> Ensuring Xcode Command Line Tools..."

  if xcode-select -p >/dev/null 2>&1; then
    echo ">>> Xcode Command Line Tools already installed."
    return 0
  fi

  echo ">>> Installing Xcode Command Line Tools..."
  xcode-select --install 2>/dev/null || true

  until xcode-select -p >/dev/null 2>&1; do
    sleep 5
  done

  echo ">>> Xcode Command Line Tools installation complete."
}

install_homebrew() {
  if command -v brew >/dev/null 2>&1; then
    echo ">>> Homebrew already installed."
    eval "$(${BREW_PREFIX}/bin/brew shellenv 2>/dev/null || true)"
    return 0
  fi

  if [[ "$(id -u)" -eq 0 ]]; then
    echo ">>> ERROR: Do not run this script as root."
    exit 1
  fi

  sudo -v

  USER_NAME="$(id -un)"
  USER_HOME="${HOME}"

  echo ">>> Installing Homebrew for user: ${USER_NAME}"

  sudo install -d -o "${USER_NAME}" -g wheel -m 0755 "${BREW_PREFIX}"
  sudo install -d -o root -g wheel -m 0755 /etc/paths.d
  echo "${BREW_PREFIX}/bin" | sudo tee /etc/paths.d/homebrew >/dev/null
  sudo chmod a+r /etc/paths.d/homebrew

  echo ">>> Running Homebrew installer..."
  NONINTERACTIVE=1 /bin/bash -c \
    "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

  eval "$(${BREW_PREFIX}/bin/brew shellenv)"
  export PATH="${BREW_PREFIX}/bin:${BREW_PREFIX}/sbin:${PATH}"

  if ! grep -q "brew shellenv" "${USER_HOME}/.zprofile" 2>/dev/null; then
    {
      echo "# Homebrew"
      echo "eval \"\$(${BREW_PREFIX}/bin/brew shellenv)\""
    } >> "${USER_HOME}/.zprofile"
  fi

  brew update
}

install_salt() {
  echo ">>> Ensuring Salt is installed..."

  eval "$(${BREW_PREFIX}/bin/brew shellenv 2>/dev/null || true)"
  export PATH="/usr/local/sbin:/usr/local/bin:${BREW_PREFIX}/bin:${BREW_PREFIX}/sbin:${PATH}"

  if ! command -v salt-call >/dev/null 2>&1; then
    brew install salt
  else
    echo ">>> Salt already installed."
  fi

  echo ">>> Salt version:"
  salt-call --version
}

run_salt() {
  echo ">>> Running Salt states (masterless)..."

  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  SALT_STATE_PATH="${SALT_STATE_PATH:-${SCRIPT_DIR}/../salt}"
  SALT_STATE_PATH="$(cd "${SALT_STATE_PATH}" && pwd)"

  if [[ ! -f "${SALT_STATE_PATH}/top.sls" ]]; then
    echo ">>> FATAL: top.sls not found."
    echo ">>> Expected at: ${SALT_STATE_PATH}/top.sls"
    exit 1
  fi

  echo ">>> Using Salt state directory: ${SALT_STATE_PATH}"

  sudo salt-call --local state.apply \
    saltenv=base \
    --file-root="${SALT_STATE_PATH}"
}

main() {

  install_xcode_tools
  install_homebrew
  install_salt
  run_salt

  echo "Bootstrap complete. Whoop!"
}

main
