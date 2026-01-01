{% set user = pillar['user']['primary_user'] %}

# -----------------------------
# Set the shell to bash
# -----------------------------

set_login_shell_bash:
  cmd.run:
    - name: chsh -s /bin/bash {{ user }}
    - unless: dscl . -read /Users/{{ user }} UserShell | grep -q '/bin/bash'
