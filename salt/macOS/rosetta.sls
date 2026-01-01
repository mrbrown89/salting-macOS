# -----------------------------
# Install Rosetta
# -----------------------------

install_rosetta:
  cmd.run:
    - name: /usr/sbin/softwareupdate --install-rosetta --agree-to-license
    - unless: /usr/bin/pgrep oahd
    - onlyif: test "$(uname -m)" = "arm64"
