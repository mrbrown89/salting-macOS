#!/usr/bin/env bash
set -euo pipefail

# -----------------------------
# Initialize all run flags
# -----------------------------
RUN_XCODE=false
RUN_ANSIBLE=false
RUN_SALT=false
RUN_SALT_CALL=false
RUN_PLAYBOOK=false

# -----------------------------
# Functions
# -----------------------------

show_help() {
  cat << EOF
Usage: $0 [options]

Options:
  -a, --ansible       Install Ansible and its dependencies
  -s, --salt          Install Salt (masterless)
  -m, --salt-call     Run Salt states in masterless mode
  -x, --xcode         Install Xcode Command Line Tools
  -p, --playbook      Run Ansible playbook (requires Ansible installed)
  -h, --help          Show this help message
EOF
}

install_xcode_tools() {
  echo ">>> Ensuring Xcode Command Line Tools (if needed)..."

  if ! xcode-select -p >/dev/null 2>&1; then
    touch /tmp/.com.apple.dt.CommandLineTools.installondemand.in-progress
    softwareupdate -l >/dev/null 2>&1 || true

    CLT_LABEL="$(
      softwareupdate -l 2>&1 |
        awk -F'*' '/Command Line Tools for Xcode/{print $2}' |
        sed 's/^ Label: //;s/^ *//;q' || true
    )"

    if [[ -n "${CLT_LABEL}" ]]; then
      sudo softwareupdate -i "${CLT_LABEL}" --verbose
      sudo xcode-select --switch /Library/Developer/CommandLineTools
    fi

    rm -f /tmp/.com.apple.dt.CommandLineTools.installondemand.in-progress
  else
    echo ">>> Command Line Tools already installed."
  fi
}

install_homebrew() {
  # Refuse to run as root
  if [[ "$(id -u)" -eq 0 ]]; then
    echo "Do not run this script as root. Run it as your user."
    return 1
  fi

  sudo -v

  USER_NAME="$(id -un)"
  USER_HOME="${HOME}"
  BREW_PREFIX="/opt/homebrew"

  echo ">>> Running as user: ${USER_NAME}"
  echo ">>> Home directory: ${USER_HOME}"

  echo ">>> Preparing Homebrew directories..."
  sudo install -d -o "${USER_NAME}" -g wheel -m 0755 "${BREW_PREFIX}"
  sudo install -d -o root -g wheel -m 0755 /etc/paths.d
  echo "${BREW_PREFIX}/bin" | sudo tee /etc/paths.d/homebrew >/dev/null
  sudo chmod a+r /etc/paths.d/homebrew

  echo ">>> Installing Homebrew (non-interactive)..."
  NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

  echo ">>> Enabling Homebrew for current shell..."
  if [[ -x "${BREW_PREFIX}/bin/brew" ]]; then
    eval "$(${BREW_PREFIX}/bin/brew shellenv)"
    export PATH="${BREW_PREFIX}/bin:${BREW_PREFIX}/sbin:${PATH}"
  fi

  if ! grep -q "${BREW_PREFIX}/bin/brew shellenv" "${USER_HOME}/.zprofile" 2>/dev/null; then
    {
      echo "# Homebrew"
      echo "eval \"$(${BREW_PREFIX}/bin/brew shellenv)\""
    } >> "${USER_HOME}/.zprofile"
  fi

  echo ">>> Updating Homebrew..."
  brew update
}

install_ansible() {
  echo ">>> Installing Ansible via Homebrew..."
  brew install ansible
  ansible-galaxy collection install community.general
  echo ">>> Sanity check:"
  ansible --version
}

install_salt() {
  echo ">>> Installing Salt (masterless) via Homebrew..."
  brew install salt

  # Add Homebrew bin/sbin to PATH (for Apple Silicon + Intel)
  eval "$(/opt/homebrew/bin/brew shellenv)" 2>/dev/null || true
  export PATH="/usr/local/sbin:/usr/local/bin:/opt/homebrew/bin:/opt/homebrew/sbin:$PATH"

  # Sanity check
  echo ">>> Sanity check:"
  salt-call --version
}

run_playbook() {
  echo ">>> Running Ansible playbook..."
  echo ">>> Current working directory: $(pwd)"
  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  echo ">>> Script directory: ${SCRIPT_DIR}"

  # Ensure Homebrew env is loaded for this process (in case caller didn't re-login)
  BREW_PREFIX_LOCAL="/opt/homebrew"
  if [[ -x "${BREW_PREFIX_LOCAL}/bin/brew" ]]; then
    eval "$(${BREW_PREFIX_LOCAL}/bin/brew shellenv)"
    export PATH="${BREW_PREFIX_LOCAL}/bin:${BREW_PREFIX_LOCAL}/sbin:${PATH}"
  fi

  # Ensure ansible is available
  if ! command -v ansible-playbook >/dev/null 2>&1; then
    echo "ansible-playbook not found on PATH. Please ensure Ansible is installed."
    return 1
  fi

  # Allow overriding via env vars; otherwise infer from script location (../ansible/*)
  DEFAULT_PLAYBOOK_PATH="${SCRIPT_DIR}/../ansible/master.yml"
  DEFAULT_INVENTORY_PATH="${SCRIPT_DIR}/../ansible/inventory"
  PLAYBOOK_PATH="${PLAYBOOK_PATH:-${DEFAULT_PLAYBOOK_PATH}}"
  INVENTORY_PATH="${INVENTORY_PATH:-${DEFAULT_INVENTORY_PATH}}"

  # Resolve to absolute paths if possible
  if [[ -f "${PLAYBOOK_PATH}" ]]; then
    PLAYBOOK_PATH="$(cd "$(dirname "${PLAYBOOK_PATH}")" && pwd)/$(basename "${PLAYBOOK_PATH}")"
  fi
  if [[ -f "${INVENTORY_PATH}" || -d "${INVENTORY_PATH}" ]]; then
    INVENTORY_PATH="$(cd "$(dirname "${INVENTORY_PATH}")" && pwd)/$(basename "${INVENTORY_PATH}")"
  fi

  # Validate inputs
  if [[ ! -f "${PLAYBOOK_PATH}" ]]; then
    echo "Could not find playbook at: ${PLAYBOOK_PATH}"
    echo "Set PLAYBOOK_PATH to the correct location, e.g.: PLAYBOOK_PATH=ansible/master.yml ./bootStrap.sh"
    return 1
  fi
  if [[ ! -f "${INVENTORY_PATH}" && ! -d "${INVENTORY_PATH}" ]]; then
    echo "Could not find inventory at: ${INVENTORY_PATH}"
    echo "Set INVENTORY_PATH to the correct file/dir, e.g.: INVENTORY_PATH=ansible/inventory ./bootStrap.sh"
    return 1
  fi

  echo ">>> Using inventory: ${INVENTORY_PATH}"
  echo ">>> Using playbook:  ${PLAYBOOK_PATH}"
  ansible-playbook -i "${INVENTORY_PATH}" "${PLAYBOOK_PATH}" -v
}

run_salt() {
  echo ">>> Running Salt states (masterless)..."

  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  SALT_STATE_PATH="${SALT_STATE_PATH:-${SCRIPT_DIR}/../salt}"
  SALT_STATE_PATH="$(cd "${SALT_STATE_PATH}" && pwd)"

  if [[ ! -f "${SALT_STATE_PATH}/top.sls" ]]; then
    echo ">>> ERROR: top.sls not found in ${SALT_STATE_PATH}"
    return 1
  fi

  # Ensure salt-call is in PATH
  export PATH="/usr/local/sbin:/usr/local/bin:/opt/homebrew/bin:/opt/homebrew/sbin:$PATH"

  echo ">>> Using Salt state directory: ${SALT_STATE_PATH}"

  sudo salt-call --local state.apply \
       saltenv=base \
       --file-root="${SALT_STATE_PATH}"
}

# -----------------------------
# Argument parsing
# -----------------------------
while [[ $# -gt 0 ]]; do
  case "$1" in
    -a|--ansible) RUN_ANSIBLE=true; shift ;;
    -s|--salt) RUN_SALT=true; shift ;;
    -m|--salt-call) RUN_SALT_CALL=true; shift ;;
    -x|--xcode) RUN_XCODE=true; shift ;;
    -p|--playbook) RUN_PLAYBOOK=true; shift ;;
    -h|--help) show_help; exit 0 ;;
    *) echo "Unknown option: $1"; show_help; exit 1 ;;
  esac
done

# -----------------------------
# Main
# -----------------------------
main() {
  [[ "$RUN_XCODE" = true ]] && install_xcode_tools
  [[ "$RUN_ANSIBLE" = true ]] && { install_homebrew; install_ansible; }
  [[ "$RUN_SALT" = true ]] && { install_homebrew; install_salt; }
  [[ "$RUN_PLAYBOOK" = true ]] && run_playbook
  [[ "$RUN_SALT_CALL" = true ]] && run_salt

  # Default behavior if no flags provided
  if [[ "$RUN_XCODE" = false && "$RUN_ANSIBLE" = false && "$RUN_SALT" = false && "$RUN_PLAYBOOK" = false && "$RUN_SALT_CALL" = false ]]; then
    install_xcode_tools
    install_homebrew
    install_ansible
    run_playbook
  fi

  echo ">>> Bootstrap complete."
}

main
