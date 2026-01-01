{% set user = pillar['user']['primary_user'] %}

# -----------------------------
# macOS Dark Mode
# -----------------------------

enable_dark_mode:
  macdefaults.write:
    - name: AppleInterfaceStyle
    - domain: NSGlobalDomain
    - value: Dark
    - user: {{ user }}
    - vtype: string
